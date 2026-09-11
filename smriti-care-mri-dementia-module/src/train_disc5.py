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
            vol_np = tensor.squeeze().numpy()
            vol_aug = augment_3d_volume(vol_np)
            tensor = torch.from_numpy(vol_aug.astype(np.float32)).unsqueeze(0)

        return {
            "image": tensor,
            "label": torch.tensor(label, dtype=torch.long),
            "subject_id": str(row["subject_id"]),
            "session_id": str(row["session_id"]),
            "cdr": str(row["cdr"])
        }


def run_training_disc5():
    set_seed(42)
    device, dev_info = get_device()
    print("=" * 80)
    print("OASIS-1 DISC 5 CONTINUATION TRAINING")
    print(f"Device: {dev_info}")
    print("=" * 80)

    # 1. Verify Checkpoint Hashes BEFORE Training
    orig_ckpt = Path("models/best_model.pth")
    disc4_ckpt = Path("models/best_model_disc4.pth")
    assert orig_ckpt.exists(), "models/best_model.pth missing!"
    assert disc4_ckpt.exists(), "models/best_model_disc4.pth missing!"

    with open(orig_ckpt, "rb") as f:
        orig_sha_before = hashlib.sha256(f.read()).hexdigest()
    with open(disc4_ckpt, "rb") as f:
        disc4_sha_before = hashlib.sha256(f.read()).hexdigest()

    print(f"\n[CHECKPOINT BASELINE (BEFORE TRAINING)]")
    print(f"Original Checkpoint: {orig_ckpt} (SHA-256: {orig_sha_before})")
    print(f"Disc 4 Checkpoint:   {disc4_ckpt} (SHA-256: {disc4_sha_before})")
    assert orig_sha_before == "85aa7a5dd60f84f8f276eaacc46bd3a50df7cc8b03c872f5cd22cef19d88bfeb"
    assert disc4_sha_before == "7b23efdb1609999478f8b4ad8af1e731aba4d3ec051846520b1ee303e2f04fde"

    # 2. Load Split v4 Subject Lists
    split_dir = Path("splits/split_v4_disc1_disc2_disc3_disc4_disc5")
    train_subs = split_dir.joinpath("train_subjects.txt").read_text(encoding="utf-8").strip().splitlines()
    val_subs = split_dir.joinpath("val_subjects.txt").read_text(encoding="utf-8").strip().splitlines()
    test_subs = split_dir.joinpath("test_subjects.txt").read_text(encoding="utf-8").strip().splitlines()

    print(f"\n[DATASET SPLIT v4]")
    print(f"Train Subjects:      {len(train_subs)}")
    print(f"Validation Subjects: {len(val_subs)}")
    print(f"Test Subjects:       {len(test_subs)} (Frozen Benchmark)")
    assert len(train_subs) == 68
    assert len(val_subs) == 16
    assert len(test_subs) == 10

    # 3. Load Records & DataLoaders
    manifest_df = pd.read_csv("data/metadata/mri_dataset_v4_disc1_disc2_disc3_disc4_disc5.csv")
    train_records = manifest_df[manifest_df["subject_id"].isin(train_subs)].to_dict("records")
    val_records = manifest_df[manifest_df["subject_id"].isin(val_subs)].to_dict("records")
    test_records = manifest_df[manifest_df["subject_id"].isin(test_subs)].sort_values("subject_id").to_dict("records")

    train_dataset = CachedMRIDataset(train_records, is_train=True)
    val_dataset = CachedMRIDataset(val_records, is_train=False)
    test_dataset = CachedMRIDataset(test_records, is_train=False)

    train_loader = DataLoader(train_dataset, batch_size=4, shuffle=True, num_workers=0)
    val_loader = DataLoader(val_dataset, batch_size=4, shuffle=False, num_workers=0)
    test_loader = DataLoader(test_dataset, batch_size=1, shuffle=False, num_workers=0)

    # 4. Calculate Stable Class Weights from TRAINING Partition ONLY
    train_counts = {0: 0, 1: 0, 2: 0}
    for r in train_records:
        train_counts[int(r["label"])] += 1
    total_train = len(train_records)

    print(f"\n[TRAINING PARTITION CLASS COUNTS]")
    print(f"  Class 0 (Normal):             {train_counts[0]}")
    print(f"  Class 1 (Very Mild Dementia): {train_counts[1]}")
    print(f"  Class 2 (Dementia):           {train_counts[2]}")

    weights = [
        total_train / (3.0 * train_counts[0]),
        total_train / (3.0 * train_counts[1]),
        total_train / (3.0 * train_counts[2])
    ]
    class_weights_tensor = torch.tensor(weights, dtype=torch.float32).to(device)
    print(f"[LOSS CONFIGURATION]")
    print(f"  Computed Weights: Class 0={weights[0]:.3f}, Class 1={weights[1]:.3f}, Class 2={weights[2]:.3f}")
    criterion = nn.CrossEntropyLoss(weight=class_weights_tensor)

    # 5. Initialize Model from models/best_model_disc4.pth
    model = resnet10_3d(in_channels=1, num_classes=3, dropout=0.3).to(device)
    state_dict = torch.load(disc4_ckpt, map_location=device)
    model.load_state_dict(state_dict)
    print(f"\n[MODEL INITIALIZATION]")
    print(f"  Architecture: resnet10_3d")
    print(f"  Initialized strictly from: {disc4_ckpt} (Continuation Training)")

    # 6. Hyperparameters
    learning_rate = 5e-5
    max_epochs = 20
    patience = 5

    optimizer = optim.AdamW(model.parameters(), lr=learning_rate, weight_decay=1e-4)
    scheduler = optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=max_epochs, eta_min=1e-6)

    print(f"\n[TRAINING HYPERPARAMETERS]")
    print(f"  Learning Rate: {learning_rate}")
    print(f"  Optimizer:     AdamW (weight_decay=1e-4)")
    print(f"  Scheduler:     CosineAnnealingLR (T_max={max_epochs}, eta_min=1e-6)")
    print(f"  Max Epochs:    {max_epochs}")
    print(f"  Early Stopping Patience: {patience} epochs (Criterion: Validation Macro-F1)")

    # 7. Training Loop
    best_val_macro_f1 = -1.0
    best_val_acc = -1.0
    best_epoch = -1
    best_model_weights = None
    no_improve_count = 0

    history = {
        "epoch": [], "lr": [],
        "train_loss": [], "train_acc": [], "train_macro_f1": [],
        "val_loss": [], "val_acc": [], "val_macro_f1": [],
        "val_prec_c0": [], "val_prec_c1": [], "val_prec_c2": [],
        "val_rec_c0": [], "val_rec_c1": [], "val_rec_c2": []
    }

    print("\n" + "=" * 80)
    print("STARTING CONTINUATION TRAINING (DISC 5)")
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

        # --- Validation Phase ---
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

        if val_macro_f1 > best_val_macro_f1:
            best_val_macro_f1 = val_macro_f1
            best_val_acc = val_acc
            best_epoch = epoch
            best_model_weights = copy.deepcopy(model.state_dict())
            no_improve_count = 0
            status = f"*BEST (Macro-F1={val_macro_f1:.4f})"
        else:
            no_improve_count += 1
            status = f"patience {no_improve_count}/{patience}"

        epoch_time = time.time() - epoch_start
        print(f"\n--- Epoch {epoch:2d}/{max_epochs} [{epoch_time:.1f}s, LR: {curr_lr:.2e}] ---")
        print(f"  Train: Loss={train_loss:.4f} | Acc={train_acc*100:.1f}% | Macro-F1={train_macro_f1:.4f}")
        print(f"  Val:   Loss={val_loss:.4f} | Acc={val_acc*100:.1f}% | Macro-F1={val_macro_f1:.4f} -> {status}")
        print(f"  Val Per-Class: Normal (P={prec[0]:.2f}, R={rec[0]:.2f}) | Very Mild (P={prec[1]:.2f}, R={rec[1]:.2f}) | Dementia (P={prec[2]:.2f}, R={rec[2]:.2f})")
        print(f"  Val Confusion Matrix: {cm_val.tolist()}")

        if no_improve_count >= patience:
            print(f"\n[EARLY STOPPING] No validation Macro-F1 improvement for {patience} epochs.")
            print(f"Halting at Epoch {epoch}. Best epoch was Epoch {best_epoch} (Macro-F1={best_val_macro_f1:.4f}).")
            break

    total_train_time = time.time() - start_train_time

    # 8. Save New Checkpoints Separately
    new_best_ckpt = Path("models/best_model_disc5.pth")
    final_ckpt = Path("models/final_model_disc5.pth")

    if best_model_weights is not None:
        torch.save(best_model_weights, new_best_ckpt)
    else:
        torch.save(model.state_dict(), new_best_ckpt)
    print(f"\n[SAVED] New best checkpoint: {new_best_ckpt}")

    torch.save(model.state_dict(), final_ckpt)
    print(f"[SAVED] Final checkpoint:    {final_ckpt}")

    with open("reports/training_history_disc5.json", "w", encoding="utf-8") as f:
        json.dump(history, f, indent=2)
    print(f"[SAVED] reports/training_history_disc5.json")

    with open("reports/metrics_val_disc5.json", "w", encoding="utf-8") as f:
        json.dump({
            "best_epoch": best_epoch,
            "best_val_macro_f1": float(best_val_macro_f1),
            "best_val_accuracy": float(best_val_acc),
            "total_epochs": len(history["epoch"]),
            "training_time_seconds": total_train_time
        }, f, indent=2)
    print(f"[SAVED] reports/metrics_val_disc5.json")

    # Curves plot
    plt.figure(figsize=(12, 5))
    plt.subplot(1, 2, 1)
    plt.plot(history["epoch"], history["train_loss"], "b-o", label="Train Loss", markersize=4)
    plt.plot(history["epoch"], history["val_loss"], "r--s", label="Val Loss", markersize=4)
    plt.xlabel("Epoch")
    plt.ylabel("Loss")
    plt.title("Cross-Entropy Loss (Disc 5)")
    plt.legend()
    plt.grid(True, alpha=0.3)

    plt.subplot(1, 2, 2)
    plt.plot(history["epoch"], history["train_macro_f1"], "g-o", label="Train Macro-F1", markersize=4)
    plt.plot(history["epoch"], history["val_macro_f1"], "m--s", label="Val Macro-F1", markersize=4)
    plt.xlabel("Epoch")
    plt.ylabel("Macro-F1")
    plt.title("Macro-F1 (Disc 5)")
    plt.legend()
    plt.grid(True, alpha=0.3)

    plt.tight_layout()
    plt.savefig("reports/training_curve_disc5.png", dpi=150)
    plt.close()
    print(f"[SAVED] reports/training_curve_disc5.png")

    # 9. Verify Checkpoint Hashes AFTER Training
    with open(orig_ckpt, "rb") as f:
        orig_sha_after = hashlib.sha256(f.read()).hexdigest()
    with open(disc4_ckpt, "rb") as f:
        disc4_sha_after = hashlib.sha256(f.read()).hexdigest()

    print(f"\n[CHECKPOINT INTEGRITY AUDIT (AFTER TRAINING)]")
    print(f"Original Checkpoint Before: {orig_sha_before}")
    print(f"Original Checkpoint After:  {orig_sha_after}")
    assert orig_sha_before == orig_sha_after, "CRITICAL: models/best_model.pth was altered!"

    print(f"Disc 4 Checkpoint Before:   {disc4_sha_before}")
    print(f"Disc 4 Checkpoint After:    {disc4_sha_after}")
    assert disc4_sha_before == disc4_sha_after, "CRITICAL: models/best_model_disc4.pth was altered!"
    print(f"[PASS] Both previous checkpoints are 100% BYTE-IDENTICAL AND UNTOUCHED.")

    # 10. 3-Way Held-Out Test Benchmark Evaluation
    print("\n" + "=" * 80)
    print("3-WAY COMPARISON ON THE FROZEN 10-SUBJECT TEST BENCHMARK")
    print("=" * 80)

    def eval_checkpoint(ckpt_path, name):
        m = resnet10_3d(in_channels=1, num_classes=3, dropout=0.3).to(device)
        m.load_state_dict(torch.load(ckpt_path, map_location=device))
        m.eval()

        t_preds, t_targets, t_probs = [], [], []
        detailed = []

        with torch.no_grad():
            for batch in test_loader:
                imgs = batch["image"].to(device)
                lbls = batch["label"].to(device)

                outputs = m(imgs)
                probs = torch.softmax(outputs, dim=1).cpu().numpy()
                preds = np.argmax(probs, axis=1)

                t_probs.extend(probs)
                t_preds.extend(preds)
                t_targets.extend(lbls.cpu().numpy())
                detailed.append({
                    "subject_id": str(batch["subject_id"][0]),
                    "session_id": str(batch["session_id"][0]),
                    "cdr": str(batch["cdr"][0]),
                    "ground_truth": int(lbls[0].cpu().numpy()),
                    "predicted": int(preds[0]),
                    "probabilities": [round(float(p), 4) for p in probs[0]]
                })

        acc = accuracy_score(t_targets, t_preds)
        macro_f1 = f1_score(t_targets, t_preds, average="macro", zero_division=0)
        p, r, f1, s = precision_recall_fscore_support(t_targets, t_preds, labels=[0, 1, 2], zero_division=0)
        cm = confusion_matrix(t_targets, t_preds, labels=[0, 1, 2])

        return {
            "model_name": name,
            "accuracy": float(acc),
            "macro_f1": float(macro_f1),
            "precision": [float(x) for x in p],
            "recall": [float(x) for x in r],
            "f1": [float(x) for x in f1],
            "support": [int(x) for x in s],
            "confusion_matrix": cm.tolist(),
            "samples": detailed
        }

    res_orig = eval_checkpoint(orig_ckpt, "Original Model (models/best_model.pth)")
    res_disc4 = eval_checkpoint(disc4_ckpt, "Disc 4 Model (models/best_model_disc4.pth)")
    res_disc5 = eval_checkpoint(new_best_ckpt, "Disc 5 Model (models/best_model_disc5.pth)")

    # Save to json
    with open("reports/comparison_test_metrics_disc5.json", "w", encoding="utf-8") as f:
        json.dump({
            "original_model": res_orig,
            "disc4_model": res_disc4,
            "disc5_model": res_disc5
        }, f, indent=2)
    print(f"\n[SAVED] reports/comparison_test_metrics_disc5.json")

    # 3-Way Table
    print("\n" + "=" * 80)
    print(f"{'Metric':<26} | {'Original':<14} | {'Disc 4':<14} | {'Disc 5':<14}")
    print("-" * 80)
    print(f"{'Accuracy':<26} | {res_orig['accuracy']*100:>12.1f}% | {res_disc4['accuracy']*100:>12.1f}% | {res_disc5['accuracy']*100:>12.1f}%")
    print(f"{'Macro-F1':<26} | {res_orig['macro_f1']:>14.4f} | {res_disc4['macro_f1']:>14.4f} | {res_disc5['macro_f1']:>14.4f}")
    print(f"{'Normal Recall (Class 0)':<26} | {res_orig['recall'][0]*100:>12.1f}% | {res_disc4['recall'][0]*100:>12.1f}% | {res_disc5['recall'][0]*100:>12.1f}%")
    print(f"{'Very Mild Recall (Class 1)':<26} | {res_orig['recall'][1]*100:>12.1f}% | {res_disc4['recall'][1]*100:>12.1f}% | {res_disc5['recall'][1]*100:>12.1f}%")
    print(f"{'Dementia Recall (Class 2)':<26} | {res_orig['recall'][2]*100:>12.1f}% | {res_disc4['recall'][2]*100:>12.1f}% | {res_disc5['recall'][2]*100:>12.1f}%")
    print("-" * 80)

    print("\n[CONFUSION MATRICES (Rows=True, Columns=Pred)]")
    print("Original Model:")
    print(np.array(res_orig["confusion_matrix"]))
    print("\nDisc 4 Model:")
    print(np.array(res_disc4["confusion_matrix"]))
    print("\nDisc 5 Model:")
    print(np.array(res_disc5["confusion_matrix"]))

    print("\n[PER-CLASS METRICS (Disc 5 Model)]")
    for c, name in [(0, "Normal"), (1, "Very Mild"), (2, "Dementia")]:
        print(f"  Class {c} ({name:10s}): Precision={res_disc5['precision'][c]:.3f}, Recall={res_disc5['recall'][c]:.3f}, F1={res_disc5['f1'][c]:.3f} (Support={res_disc5['support'][c]})")

    print("\n[DETAILED PREDICTIONS PER TEST SUBJECT (Disc 5 Model)]")
    print(f"{'Subject ID':<12} | {'Session ID':<15} | {'CDR':<5} | {'True':<5} | {'Orig':<5} | {'D4':<5} | {'D5':<5} | {'Probabilities [N, VM, D]'}")
    print("-" * 90)
    for s_o, s_4, s_5 in zip(res_orig["samples"], res_disc4["samples"], res_disc5["samples"]):
        probs = f"[{s_5['probabilities'][0]:.2f}, {s_5['probabilities'][1]:.2f}, {s_5['probabilities'][2]:.2f}]"
        match = "MATCH" if s_5["ground_truth"] == s_5["predicted"] else "MISMATCH"
        print(f"{s_5['subject_id']:<12} | {s_5['session_id']:<15} | {s_5['cdr']:<5} | {s_5['ground_truth']:<5} | {s_o['predicted']:<5} | {s_4['predicted']:<5} | {s_5['predicted']:<5} | {probs} [{match}]")


if __name__ == "__main__":
    run_training_disc5()
