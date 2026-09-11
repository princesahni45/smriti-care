import os
import sys
import json
import hashlib
from pathlib import Path

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

import torch
from torch.utils.data import Dataset, DataLoader
import numpy as np
import pandas as pd
from sklearn.metrics import accuracy_score, f1_score, precision_recall_fscore_support, confusion_matrix

from models.resnet3d import resnet10_3d
from src.utils import get_device


class CachedMRIDataset(Dataset):
    def __init__(self, records, cache_dir="data/processed"):
        self.records = records
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
        return {
            "image": tensor,
            "label": torch.tensor(label, dtype=torch.long),
            "subject_id": str(row["subject_id"]),
            "session_id": str(row["session_id"]),
            "cdr": str(row["cdr"])
        }


def run_evaluation():
    device, dev_info = get_device()
    print("=" * 80)
    print("EVALUATING ORIGINAL VS DISC 4 MODEL ON FROZEN TEST SET")
    print("=" * 80)

    # 1. Verify Checkpoint Hashes
    orig_ckpt = Path("models/best_model.pth")
    disc4_ckpt = Path("models/best_model_disc4.pth")

    with open(orig_ckpt, "rb") as f:
        orig_sha = hashlib.sha256(f.read()).hexdigest()
    with open(disc4_ckpt, "rb") as f:
        disc4_sha = hashlib.sha256(f.read()).hexdigest()

    print(f"Original Checkpoint: {orig_ckpt} (SHA-256: {orig_sha})")
    print(f"Disc 4 Checkpoint:   {disc4_ckpt} (SHA-256: {disc4_sha})")

    # 2. Load Frozen Test Set
    split_dir = Path("splits/split_v3_disc1_disc2_disc3_disc4")
    test_subs = split_dir.joinpath("test_subjects.txt").read_text(encoding="utf-8").strip().splitlines()

    manifest_df = pd.read_csv("data/metadata/mri_dataset.csv")
    test_records = manifest_df[manifest_df["subject_id"].isin(test_subs)].sort_values("subject_id").to_dict("records")
    print(f"Test Subjects ({len(test_records)} total): {[r['subject_id'] for r in test_records]}")

    test_dataset = CachedMRIDataset(test_records)
    test_loader = DataLoader(test_dataset, batch_size=1, shuffle=False, num_workers=0)

    def eval_checkpoint(ckpt_path, name):
        model = resnet10_3d(in_channels=1, num_classes=3, dropout=0.3).to(device)
        model.load_state_dict(torch.load(ckpt_path, map_location=device))
        model.eval()

        t_preds, t_targets, t_probs = [], [], []
        detailed_samples = []

        with torch.no_grad():
            for batch in test_loader:
                imgs = batch["image"].to(device)
                lbls = batch["label"].to(device)

                outputs = model(imgs)
                probs = torch.softmax(outputs, dim=1).cpu().numpy()
                preds = np.argmax(probs, axis=1)

                t_probs.extend(probs)
                t_preds.extend(preds)
                t_targets.extend(lbls.cpu().numpy())
                detailed_samples.append({
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
            "samples": detailed_samples
        }

    orig_metrics = eval_checkpoint(orig_ckpt, "Original Model (models/best_model.pth)")
    disc4_metrics = eval_checkpoint(disc4_ckpt, "Disc 4 Model (models/best_model_disc4.pth)")

    # Save to json
    with open("reports/comparison_test_metrics.json", "w", encoding="utf-8") as f:
        json.dump({
            "original_model": orig_metrics,
            "disc4_model": disc4_metrics
        }, f, indent=2)
    print("\n[SAVED] reports/comparison_test_metrics.json")

    # Print clean side-by-side comparison
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

    print("\n[PER-CLASS METRICS (Disc 4 Model)]")
    for c, name in [(0, "Normal"), (1, "Very Mild"), (2, "Dementia")]:
        print(f"  Class {c} ({name:10s}): Precision={disc4_metrics['precision'][c]:.3f}, Recall={disc4_metrics['recall'][c]:.3f}, F1={disc4_metrics['f1'][c]:.3f} (Support={disc4_metrics['support'][c]})")

    print("\n[DETAILED PREDICTIONS PER TEST SUBJECT]")
    print(f"{'Subject ID':<12} | {'Session ID':<15} | {'CDR':<5} | {'True':<6} | {'Orig Pred':<10} | {'Disc4 Pred':<10} | {'Probabilities [N, VM, D]'}")
    print("-" * 85)
    for s_orig, s_d4 in zip(orig_metrics["samples"], disc4_metrics["samples"]):
        probs_str = f"[{s_d4['probabilities'][0]:.2f}, {s_d4['probabilities'][1]:.2f}, {s_d4['probabilities'][2]:.2f}]"
        print(f"{s_d4['subject_id']:<12} | {s_d4['session_id']:<15} | {s_d4['cdr']:<5} | {s_d4['ground_truth']:<6} | {s_orig['predicted']:<10} | {s_d4['predicted']:<10} | {probs_str}")


if __name__ == "__main__":
    run_evaluation()
