import os
import sys
import json
import time
import copy
import hashlib
from pathlib import Path

# Add project root
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader
import numpy as np
import pandas as pd
from sklearn.metrics import (
    accuracy_score, f1_score, precision_recall_fscore_support, confusion_matrix
)
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

from models.resnet3d import resnet10_3d
from src.preprocessing import augment_3d_volume
from src.utils import set_seed, get_device, CLASS_NAMES_3CLASS


class CachedMRIDataset(Dataset):
    def __init__(self, records, is_train=False, cache_dir="data/processed"):
        self.records = records
        self.is_train = is_train
        self.cache_dir = Path(cache_dir)

    def __len__(self):
        return len(self.records)

    def __getitem__(self, idx):
        row = self.records[idx]
        sess_id = row["session_id"]
        label = int(row["label"])

        cache_file = self.cache_dir / f"{sess_id}_96.pt"
        if not cache_file.exists():
            cache_file = self.cache_dir / f"{sess_id}_prep.pt"

        tensor = torch.load(cache_file, weights_only=True)

        if self.is_train:
            # Data augmentation on train split
            vol_np = tensor.squeeze().numpy()
            vol_aug = augment_3d_volume(vol_np)
            tensor = torch.from_numpy(vol_aug.astype(np.float32)).unsqueeze(0)

        return {
            "image": tensor,
            "label": torch.tensor(label, dtype=torch.long),
            "subject_id": row["subject_id"],
            "session_id": row["session_id"],
            "cdr": row["cdr"]
        }


def run_training():
    set_seed(42)
    device, dev_info = get_device()
    print("=" * 75)
    print("OASIS-1 DISC 4 CONTINUATION TRAINING")
    print(f"Device: {dev_info}")
    print("=" * 75)

    # 1. Verify and Record Checkpoint Hash BEFORE training
    orig_ckpt = Path("models/best_model.pth")
    assert orig_ckpt.exists(), "models/best_model.pth missing!"
    with open(orig_ckpt, "rb") as f:
        orig_sha_before = hashlib.sha256(f.read()).hexdigest()
    orig_size_before = orig_ckpt.stat().st_size
    print(f"\n[CHECKPOINT BASELINE]")
    print(f"Original Checkpoint: {orig_ckpt}")
    print(f"Size:                {orig_size_before} bytes")
    print(f"SHA-256 Before:      {orig_sha_before}")

    # 2. Load Split v3 Subject Lists
    split_dir = Path("splits/split_v3_disc1_disc2_disc3_disc4")
    train_subs = split_dir.joinpath("train_subjects.txt").read_text(encoding="utf-8").strip().splitlines()
    val_subs = split_dir.joinpath("val_subjects.txt").read_text(encoding="utf-8").strip().splitlines()
    test_subs = split_dir.joinpath("test_subjects.txt").read_text(encoding="utf-8").strip().splitlines()

    print(f"\n[DATASET SPLIT v3]")
    print(f"Train Subjects:      {len(train_subs)}")
    print(f"Validation Subjects: {len(val_subs)}")
    print(f"Test Subjects:       {len(test_subs)} (Frozen Benchmark)")
    assert len(train_subs) == 54
    assert len(val_subs) == 12
    assert len(test_subs) == 10

    # 3. Build Datasets & DataLoaders
    manifest_df = pd.read_csv("data/metadata/mri_dataset.csv")
    train_records = manifest_df[manifest_df["subject_id"].isin(train_subs)].to_dict("records")
    val_records = manifest_df[manifest_df["subject_id"].isin(val_subs)].to_dict("records")
    test_records = manifest_df[manifest_df["subject_id"].isin(test_subs)].to_dict("records")

    train_dataset = CachedMRIDataset(train_records, is_train=True)
    val_dataset = CachedMRIDataset(val_records, is_train=False)
    test_dataset = CachedMRIDataset(test_records, is_train=False)

    train_loader = DataLoader(train_dataset, batch_size=4, shuffle=True, num_workers=0)
    val_loader = DataLoader(val_dataset, batch_size=4, shuffle=False, num_workers=0)
    test_loader = DataLoader(test_dataset, batch_size=1, shuffle=False, num_workers=0)

    # 4. Class Weights Formulation
    # Combined counts: Class 0 = 43, Class 1 = 22, Class 2 = 11 (Total = 76)
    # Inverse frequency: N / (3 * Nc)
    weights = [76.0 / (3.0 * 43.0), 76.0 / (3.0 * 22.0), 76.0 / (3.0 * 11.0)]
    class_weights_tensor = torch.tensor(weights, dtype=torch.float32).to(device)
    print(f"\n[LOSS CONFIGURATION]")
    print(f"Combined Class Counts: Class 0=43, Class 1=22, Class 2=11")
    print(f"Normalized Class Weights: {weights[0]:.3f}, {weights[1]:.3f}, {weights[2]:.3f}")
    criterion = nn.CrossEntropyLoss(weight=class_weights_tensor)

    # 5. Initialize Model from Existing Checkpoint
    model = resnet10_3d(in_channels=1, num_classes=3, dropout=0.3).to(device)
    state_dict = torch.load(orig_ckpt, map_location=device)
    model.load_state_dict(state_dict)
    print(f"\n[MODEL INITIALIZATION]")
    print(f"Loaded architecture: resnet10_3d")
    print(f"Initialized strictly from: {orig_ckpt} (Continuation Training)")

    # 6. Optimizer & Scheduler
    learning_rate = 5e-5
    max_epochs = 20
    patience = 5

    optimizer = optim.AdamW(model.parameters(), lr=learning_rate, weight_decay=1e-4)
    scheduler = optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=max_epochs, eta_min=1e-6)

    print(f"\n[TRAINING HYPERPARAMETERS]")
    print(f"Learning Rate: {learning_rate}")
    print(f"Optimizer:     AdamW (weight_decay=1e-4)")
    print(f"Scheduler:     CosineAnnealingLR (T_max={max_epochs}, eta_min=1e-6)")
    print(f"Max Epochs:    {max_epochs}")
    print(f"Early Stopping Patience: {patience} epochs (Criterion: Validation Macro-F1)")

    # 7. Training Loop with Full Epoch-by-Epoch Metric Reporting
    best_val_macro_f1 = -1.0
    best_val_acc = -1.0
    best_epoch = -1
    best_model_weights = None
    no_improve_count = 0

    history = {
        "epoch": [],
        "lr": [],
        "train_loss": [],
        "train_acc": [],
        "train_macro_f1": [],
        "val_loss": [],
        "val_acc": [],
        "val_macro_f1": [],
        "val_prec_c0": [], "val_prec_c1": [], "val_prec_c2": [],
        "val_rec_c0": [], "val_rec_c1": [], "val_rec_c2": []
    }

    print("\n" + "=" * 80)
    print("STARTING CONTINUATION TRAINING EPOCHS")
    print("=" * 80)

    start_train_time = time.time()

    for epoch in range(1, max_epochs + 1):
        epoch_start = time.time()
        curr_lr = optimizer.param_groups[0]["lr"]

        # --- Train Phase ---
        model.train()
        running_train_loss = 0.0
        train_preds, train_targets = [], []

        for batch in train_loader:
            imgs = batch["image"].to(device)
            lbls = batch["label"].to(device)

            optimizer.zero_grad()
            outputs = model(imgs)
            loss = criterion(outputs, lbls)
            loss.backward()
            optimizer.step()

            running_train_loss += loss.item() * imgs.size(0)
            preds = torch.argmax(outputs, dim=1).detach().cpu().numpy()
            train_preds.extend(preds)
            train_targets.extend(lbls.cpu().numpy())

        scheduler.step()

        train_loss = running_train_loss / len(train_dataset)
        train_acc = accuracy_score(train_targets, train_preds)
        train_macro_f1 = f1_score(train_targets, train_preds, average="macro", zero_division=0)

        # --- Validation Phase (Strict Model Selection) ---
        model.eval()
        running_val_loss = 0.0
        val_preds, val_targets = [], []

        with torch.no_grad():
            for batch in val_loader:
                imgs = batch["image"].to(device)
                lbls = batch["label"].to(device)

                outputs = model(imgs)
                loss = criterion(outputs, lbls)

                running_val_loss += loss.item() * imgs.size(0)
                preds = torch.argmax(outputs, dim=1).cpu().numpy()
                val_preds.extend(preds)
                val_targets.extend(lbls.cpu().numpy())

        val_loss = running_val_loss / len(val_dataset)
        val_acc = accuracy_score(val_targets, val_preds)
        val_macro_f1 = f1_score(val_targets, val_preds, average="macro", zero_division=0)
        prec, rec, f1_per, _ = precision_recall_fscore_support(
            val_targets, val_preds, labels=[0, 1, 2], zero_division=0
        )
        cm_val = confusion_matrix(val_targets, val_preds, labels=[0, 1, 2])

        # Track history
        history["epoch"].append(epoch)
        history["lr"].append(curr_lr)
        history["train_loss"].append(train_loss)
        history["train_acc"].append(train_acc)
        history["train_macro_f1"].append(train_macro_f1)
        history["val_loss"].append(val_loss)
        history["val_acc"].append(val_acc)
        history["val_macro_f1"].append(val_macro_f1)
        history["val_prec_c0"].append(float(prec[0]))
        history["val_prec_c1"].append(float(prec[1]))
        history["val_prec_c2"].append(float(prec[2]))
        history["val_rec_c0"].append(float(rec[0]))
        history["val_rec_c1"].append(float(rec[1]))
        history["val_rec_c2"].append(float(rec[2]))

        # Model selection check
        is_best = False
        if val_macro_f1 > best_val_macro_f1:
            best_val_macro_f1 = val_macro_f1
            best_val_acc = val_acc
            best_epoch = epoch
            best_model_weights = copy.deepcopy(model.state_dict())
            no_improve_count = 0
            is_best = True
            status = f"*BEST (Macro-F1={val_macro_f1:.4f})"
        else:
            no_improve_count += 1
            status = f"patience {no_improve_count}/{patience}"

        epoch_time = time.time() - epoch_start

        # Detailed epoch printout
        print(f"\n--- Epoch {epoch:2d}/{max_epochs} [{epoch_time:.1f}s, LR: {curr_lr:.2e}] ---")
        print(f"  Train: Loss={train_loss:.4f} | Acc={train_acc*100:.1f}% | Macro-F1={train_macro_f1:.4f}")
        print(f"  Val:   Loss={val_loss:.4f} | Acc={val_acc*100:.1f}% | Macro-F1={val_macro_f1:.4f} -> {status}")
        print(f"  Val Per-Class: Normal (P={prec[0]:.2f}, R={rec[0]:.2f}) | Very Mild (P={prec[1]:.2f}, R={rec[1]:.2f}) | Dementia (P={prec[2]:.2f}, R={rec[2]:.2f})")
        print(f"  Val Confusion Matrix: {cm_val.tolist()}")

        if no_improve_count >= patience:
            print(f"\n[EARLY STOPPING TRIGGERED] No validation Macro-F1 improvement for {patience} epochs.")
            print(f"Halting training at Epoch {epoch}. Best epoch was Epoch {best_epoch} (Macro-F1={best_val_macro_f1:.4f}).")
            break

    total_train_time = time.time() - start_train_time
    total_epochs_completed = len(history["epoch"])

    # 8. Save Artifacts Separately (Preserving models/best_model.pth)
    new_best_ckpt = Path("models/best_model_disc4.pth")
    final_ckpt = Path("models/final_model_disc4.pth")

    if best_model_weights is not None:
        torch.save(best_model_weights, new_best_ckpt)
        print(f"\n[SAVED] New best checkpoint: {new_best_ckpt}")
    else:
        torch.save(model.state_dict(), new_best_ckpt)
        print(f"\n[SAVED] Checkpoint: {new_best_ckpt}")

    torch.save(model.state_dict(), final_ckpt)
    print(f"[SAVED] Final checkpoint: {final_ckpt}")

    # Save training history and validation metrics
    with open("reports/training_history_disc4.json", "w", encoding="utf-8") as f:
        json.dump(history, f, indent=2)
    print(f"[SAVED] Training history: reports/training_history_disc4.json")

    with open("reports/metrics_val_disc4.json", "w", encoding="utf-8") as f:
        json.dump({
            "best_epoch": best_epoch,
            "best_val_macro_f1": float(best_val_macro_f1),
            "best_val_accuracy": float(best_val_acc),
            "total_epochs": total_epochs_completed,
            "training_time_seconds": total_train_time
        }, f, indent=2)

    # Plot and save training curves
    plt.figure(figsize=(12, 5))
    plt.subplot(1, 2, 1)
    plt.plot(history["epoch"], history["train_loss"], "b-o", label="Train Loss", markersize=4)
    plt.plot(history["epoch"], history["val_loss"], "r--s", label="Val Loss", markersize=4)
    plt.xlabel("Epoch")
    plt.ylabel("Loss")
    plt.title("Cross-Entropy Loss (Disc 4)")
    plt.legend()
    plt.grid(True, alpha=0.3)

    plt.subplot(1, 2, 2)
    plt.plot(history["epoch"], history["train_macro_f1"], "g-o", label="Train Macro-F1", markersize=4)
    plt.plot(history["epoch"], history["val_macro_f1"], "m--s", label="Val Macro-F1", markersize=4)
    plt.xlabel("Epoch")
    plt.ylabel("Macro-F1")
    plt.title("Macro-F1 (Disc 4)")
    plt.legend()
    plt.grid(True, alpha=0.3)

    plt.tight_layout()
    plt.savefig("reports/training_curve_disc4.png", dpi=150)
    plt.close()
    print(f"[SAVED] Training curves: reports/training_curve_disc4.png")

    # 9. Verify Original Checkpoint is Byte-Identical
    with open(orig_ckpt, "rb") as f:
        orig_sha_after = hashlib.sha256(f.read()).hexdigest()
    orig_size_after = orig_ckpt.stat().st_size
    print(f"\n[CHECKPOINT INTEGRITY CHECK]")
    print(f"Original Checkpoint:  {orig_ckpt}")
    print(f"SHA-256 Before:       {orig_sha_before}")
    print(f"SHA-256 After:        {orig_sha_after}")
    assert orig_sha_before == orig_sha_after, "CRITICAL: models/best_model.pth was altered!"
    assert orig_size_before == orig_size_after, "CRITICAL: models/best_model.pth size altered!"
    print(f"[PASS] models/best_model.pth is 100% BYTE-IDENTICAL AND PRESERVED.")

    # 10. Held-Out Frozen Test Evaluation
    print("\n" + "=" * 80)
    print("EVALUATING BOTH CHECKPOINTS ON HELD-OUT TEST BENCHMARK")
    print("=" * 80)

    # Function to evaluate any checkpoint on the frozen test set
    def evaluate_test_set(checkpoint_path, model_name):
        eval_model = resnet10_3d(in_channels=1, num_classes=3, dropout=0.3).to(device)
        eval_model.load_state_dict(torch.load(checkpoint_path, map_location=device))
        eval_model.eval()

        t_preds, t_targets, t_probs = [], [], []
        detailed_samples = []

        with torch.no_grad():
            for batch in test_loader:
                imgs = batch["image"].to(device)
                lbls = batch["label"].to(device)

                outputs = eval_model(imgs)
                probs = torch.softmax(outputs, dim=1).cpu().numpy()
                preds = np.argmax(probs, axis=1)

                t_probs.extend(probs)
                t_preds.extend(preds)
                t_targets.extend(lbls.cpu().numpy())
                detailed_samples.append({
                    "subject_id": batch["subject_id"][0],
                    "session_id": batch["session_id"][0],
                    "cdr": batch["cdr"][0],
                    "ground_truth": int(lbls[0].cpu().numpy()),
                    "predicted": int(preds[0]),
                    "probabilities": [float(p) for p in probs[0]]
                })

        acc = accuracy_score(t_targets, t_preds)
        macro_f1 = f1_score(t_targets, t_preds, average="macro", zero_division=0)
        p, r, f1, s = precision_recall_fscore_support(t_targets, t_preds, labels=[0, 1, 2], zero_division=0)
        cm = confusion_matrix(t_targets, t_preds, labels=[0, 1, 2])

        return {
            "model_name": model_name,
            "accuracy": float(acc),
            "macro_f1": float(macro_f1),
            "precision": [float(x) for x in p],
            "recall": [float(x) for x in r],
            "f1": [float(x) for x in f1],
            "support": [int(x) for x in s],
            "confusion_matrix": cm.tolist(),
            "samples": detailed_samples
        }

    orig_metrics = evaluate_test_set(orig_ckpt, "Original Model (models/best_model.pth)")
    disc4_metrics = evaluate_test_set(new_best_ckpt, "Disc 4 Model (models/best_model_disc4.pth)")

    # Save test results
    with open("reports/comparison_test_metrics.json", "w", encoding="utf-8") as f:
        json.dump({
            "original_model": orig_metrics,
            "disc4_model": disc4_metrics
        }, f, indent=2)

    # 11. Print Comparison Report
    print("\n" + "=" * 80)
    print(f"{'Metric':<25} | {'Original Model':<18} | {'Disc4 Model':<18} | {'Change'}")
    print("-" * 80)
    acc_diff = disc4_metrics["accuracy"] - orig_metrics["accuracy"]
    f1_diff = disc4_metrics["macro_f1"] - orig_metrics["macro_f1"]
    r0_diff = disc4_metrics["recall"][0] - orig_metrics["recall"][0]
    r1_diff = disc4_metrics["recall"][1] - orig_metrics["recall"][1]
    r2_diff = disc4_metrics["recall"][2] - orig_metrics["recall"][2]

    print(f"{'Accuracy':<25} | {orig_metrics['accuracy']*100:>16.1f}% | {disc4_metrics['accuracy']*100:>16.1f}% | {acc_diff*100:+5.1f}%")
    print(f"{'Macro-F1':<25} | {orig_metrics['macro_f1']:>18.4f} | {disc4_metrics['macro_f1']:>18.4f} | {f1_diff:+7.4f}")
    print(f"{'Normal Recall (Class 0)':<25} | {orig_metrics['recall'][0]*100:>16.1f}% | {disc4_metrics['recall'][0]*100:>16.1f}% | {r0_diff*100:+5.1f}%")
    print(f"{'Very Mild Recall (Class 1)':<25} | {orig_metrics['recall'][1]*100:>16.1f}% | {disc4_metrics['recall'][1]*100:>16.1f}% | {r1_diff*100:+5.1f}%")
    print(f"{'Dementia Recall (Class 2)':<25} | {orig_metrics['recall'][2]*100:>16.1f}% | {disc4_metrics['recall'][2]*100:>16.1f}% | {r2_diff*100:+5.1f}%")
    print("-" * 80)

    print("\n[CONFUSION MATRICES (Rows=True, Columns=Pred)]")
    print("Original Model:")
    print(np.array(orig_metrics["confusion_matrix"]))
    print("\nDisc 4 Model:")
    print(np.array(disc4_metrics["confusion_matrix"]))

    print("\n[DETAILED TEST SAMPLES PER-SUBJECT (Disc 4 Model)]")
    for s in disc4_metrics["samples"]:
        match = "CORRECT" if s["ground_truth"] == s["predicted"] else "WRONG"
        print(f"  {s['subject_id']} ({s['session_id']}, CDR={s['cdr']}): True={s['ground_truth']}, Pred={s['predicted']} [{match}] Probs=[{s['probabilities'][0]:.2f}, {s['probabilities'][1]:.2f}, {s['probabilities'][2]:.2f}]")


if __name__ == "__main__":
    run_training()
