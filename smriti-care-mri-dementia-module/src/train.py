"""
Training Pipeline for 3D Brain MRI Dementia Severity Estimation.
Features:
- Auto-detect CUDA, automatic mixed precision (AMP)
- Class-weighted Cross-Entropy loss computed strictly from training split
- Subject-stratified validation with early stopping
- Learning rate scheduler (ReduceLROnPlateau / CosineAnnealing)
- Checkpoint persistence: best_model.pth, model_config.json, class_mapping.json
- Training curve logging to reports/training_curve.png
"""

import os
import sys

# Ensure project root is in sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

import json
import time
import copy
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim
from torch.cuda.amp import autocast, GradScaler
from sklearn.metrics import f1_score, accuracy_score

from src.utils import load_config, set_seed, get_device, check_gpu_memory, CLASS_NAMES_3CLASS
from src.dataset import get_data_loaders
from models.resnet3d import resnet10_3d, resnet18_3d
from models.densenet3d import DenseNet3D


def build_model(config):
    """Factory for 3D model architecture based on config."""
    arch = config['model']['architecture']
    in_channels = config['model']['in_channels']
    num_classes = config['model']['num_classes']
    dropout = config['model'].get('dropout', 0.3)

    if arch == "resnet10_3d":
        return resnet10_3d(in_channels=in_channels, num_classes=num_classes, dropout=dropout)
    elif arch == "resnet18_3d":
        return resnet18_3d(in_channels=in_channels, num_classes=num_classes, dropout=dropout)
    elif arch == "densenet3d":
        return DenseNet3D(in_channels=in_channels, num_classes=num_classes, drop_rate=dropout)
    else:
        # Default to lightweight resnet10_3d
        return resnet10_3d(in_channels=in_channels, num_classes=num_classes, dropout=dropout)


def train_model(config_path="config.yaml", num_epochs_override=None, resume_from=None):
    """
    Main training execution function.
    """
    config = load_config(config_path)
    set_seed(config['split']['random_seed'])

    device, dev_info = get_device()
    print("=" * 60)
    print(f"[TRAIN] Starting Training Pipeline on: {dev_info}")
    print("=" * 60)

    # 1. Prepare DataLoaders
    train_loader, val_loader, test_loader, class_weights, split_info = get_data_loaders(config)
    print("\n[TRAIN] Training set class distribution:")
    for c, cnt in split_info['train_counts'].items():
        print(f"  Class {c} ({CLASS_NAMES_3CLASS[c]}): {cnt} samples (weight={class_weights[c]:.3f})")

    # 2. Build Model
    model = build_model(config).to(device)
    total_params = sum(p.numel() for p in model.parameters() if p.requires_grad)
    print(f"\n[MODEL] Architecture: {config['model']['architecture']} | Trainable parameters: {total_params:,}")

    if resume_from and os.path.exists(resume_from):
        print(f"[CHECKPOINT] Loading existing weights from: {resume_from}")
        model.load_state_dict(torch.load(resume_from, map_location=device))
        print("[CHECKPOINT] Successfully loaded weights! Continuing training...")

    # 3. Loss & Optimizer
    if config['training'].get('use_class_weights', True):
        criterion = nn.CrossEntropyLoss(weight=class_weights.to(device))
    else:
        criterion = nn.CrossEntropyLoss()

    lr = float(config['training']['learning_rate'])
    wd = float(config['training']['weight_decay'])
    optimizer = optim.AdamW(model.parameters(), lr=lr, weight_decay=wd)

    scheduler = optim.lr_scheduler.ReduceLROnPlateau(optimizer, mode='max', factor=0.5, patience=3)
    scaler = torch.amp.GradScaler('cuda', enabled=(device.type == 'cuda' and config['training'].get('mixed_precision', True)))

    epochs = num_epochs_override if num_epochs_override is not None else int(config['training']['epochs'])
    patience = int(config['training']['patience'])

    history = {
        'train_loss': [], 'val_loss': [],
        'train_acc': [], 'val_acc': [],
        'train_macro_f1': [], 'val_macro_f1': []
    }

    best_val_f1 = -1.0
    best_model_weights = None
    no_improve_epochs = 0

    models_dir = config['paths']['models_dir']
    reports_dir = config['paths']['reports_dir']
    os.makedirs(models_dir, exist_ok=True)
    os.makedirs(reports_dir, exist_ok=True)

    print("\n" + "-" * 75)
    print(f"{'Epoch':^7} | {'Train Loss':^10} | {'Val Loss':^10} | {'Train F1':^10} | {'Val F1':^10} | {'Val Acc':^10} | {'Status':^12}")
    print("-" * 75)

    start_time = time.time()

    for epoch in range(1, epochs + 1):
        # --- Training Loop ---
        model.train()
        running_loss = 0.0
        all_train_preds = []
        all_train_targets = []

        for batch in train_loader:
            images = batch['image'].to(device)
            labels = batch['label'].to(device)

            optimizer.zero_grad()
            with torch.amp.autocast(device_type=device.type, enabled=(device.type == 'cuda' and config['training'].get('mixed_precision', True))):
                outputs = model(images)
                loss = criterion(outputs, labels)

            scaler.scale(loss).backward()
            scaler.step(optimizer)
            scaler.update()

            running_loss += loss.item() * images.size(0)
            preds = torch.argmax(outputs, dim=1).detach().cpu().numpy()
            all_train_preds.extend(preds)
            all_train_targets.extend(labels.cpu().numpy())

        epoch_train_loss = running_loss / len(train_loader.dataset)
        epoch_train_acc = accuracy_score(all_train_targets, all_train_preds)
        epoch_train_f1 = f1_score(all_train_targets, all_train_preds, average='macro', zero_division=0)

        # --- Validation Loop ---
        model.eval()
        running_val_loss = 0.0
        all_val_preds = []
        all_val_targets = []

        with torch.no_grad():
            for batch in val_loader:
                images = batch['image'].to(device)
                labels = batch['label'].to(device)

                with torch.amp.autocast(device_type=device.type, enabled=(device.type == 'cuda' and config['training'].get('mixed_precision', True))):
                    outputs = model(images)
                    val_loss = criterion(outputs, labels)

                running_val_loss += val_loss.item() * images.size(0)
                preds = torch.argmax(outputs, dim=1).cpu().numpy()
                all_val_preds.extend(preds)
                all_val_targets.extend(labels.cpu().numpy())

        epoch_val_loss = running_val_loss / len(val_loader.dataset)
        epoch_val_acc = accuracy_score(all_val_targets, all_val_preds)
        epoch_val_f1 = f1_score(all_val_targets, all_val_preds, average='macro', zero_division=0)

        scheduler.step(epoch_val_f1)

        history['train_loss'].append(epoch_train_loss)
        history['val_loss'].append(epoch_val_loss)
        history['train_acc'].append(epoch_train_acc)
        history['val_acc'].append(epoch_val_acc)
        history['train_macro_f1'].append(epoch_train_f1)
        history['val_macro_f1'].append(epoch_val_f1)

        status_msg = ""
        # Save best model checkpoint based on Macro-F1 (prioritized for medical imaging)
        if epoch_val_f1 > best_val_f1:
            best_val_f1 = epoch_val_f1
            best_model_weights = copy.deepcopy(model.state_dict())
            no_improve_epochs = 0
            status_msg = f"*BEST ({best_val_f1:.3f})"
        else:
            no_improve_epochs += 1
            status_msg = f"patience {no_improve_epochs}/{patience}"

        print(f"{epoch:^7d} | {epoch_train_loss:^10.4f} | {epoch_val_loss:^10.4f} | {epoch_train_f1:^10.3f} | {epoch_val_f1:^10.3f} | {epoch_val_acc:^10.3f} | {status_msg:<12}")

        if no_improve_epochs >= patience:
            print(f"\n[EARLY STOP] Validation Macro-F1 did not improve for {patience} epochs. Stopping.")
            break

    elapsed = time.time() - start_time
    print("-" * 75)
    print(f"[COMPLETE] Training completed in {elapsed:.1f}s. Best Val Macro-F1: {best_val_f1:.4f}")

    # Load best weights into model
    if best_model_weights is not None:
        model.load_state_dict(best_model_weights)

    # 4. Save Artifacts
    best_model_path = os.path.join(models_dir, "best_model.pth")
    torch.save(model.state_dict(), best_model_path)
    print(f"[SAVED] Checkpoint: {best_model_path}")

    # Save model config
    model_config_path = os.path.join(models_dir, "model_config.json")
    with open(model_config_path, "w", encoding="utf-8") as f:
        json.dump({
            "architecture": config['model']['architecture'],
            "in_channels": config['model']['in_channels'],
            "num_classes": config['model']['num_classes'],
            "target_shape": config['preprocessing']['target_shape'],
            "normalize": config['preprocessing']['normalize'],
            "best_val_macro_f1": float(best_val_f1),
            "trained_epochs": len(history['train_loss']),
            "training_time_seconds": elapsed
        }, f, indent=2)

    # Save class mapping
    class_mapping_path = os.path.join(models_dir, "class_mapping.json")
    with open(class_mapping_path, "w", encoding="utf-8") as f:
        json.dump({str(k): v for k, v in CLASS_NAMES_3CLASS.items()}, f, indent=2)

    # 5. Plot Training Curves
    plot_training_curves(history, os.path.join(reports_dir, "training_curve.png"))

    return model, test_loader, config


def plot_training_curves(history, save_path):
    """Plots and saves Loss and Macro-F1 training & validation curves."""
    epochs = range(1, len(history['train_loss']) + 1)
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 5))

    # Loss curve
    ax1.plot(epochs, history['train_loss'], 'b-o', label='Train Loss', markersize=4)
    ax1.plot(epochs, history['val_loss'], 'r--s', label='Val Loss', markersize=4)
    ax1.set_title("Cross-Entropy Loss Curve")
    ax1.set_xlabel("Epoch")
    ax1.set_ylabel("Loss")
    ax1.legend()
    ax1.grid(True, alpha=0.3)

    # Macro-F1 curve
    ax2.plot(epochs, history['train_macro_f1'], 'g-o', label='Train Macro-F1', markersize=4)
    ax2.plot(epochs, history['val_macro_f1'], 'm--s', label='Val Macro-F1', markersize=4)
    ax2.set_title("Macro-F1 Score Curve (Medical Metric)")
    ax2.set_xlabel("Epoch")
    ax2.set_ylabel("Macro-F1")
    ax2.legend()
    ax2.grid(True, alpha=0.3)

    plt.tight_layout()
    plt.savefig(save_path, dpi=150)
    plt.close()
    print(f"[SAVED] Training curves: {save_path}")


if __name__ == "__main__":
    train_model()
