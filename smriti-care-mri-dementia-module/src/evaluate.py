"""
Comprehensive Evaluation Module for 3D Brain MRI Dementia Severity Estimation.
Metrics computed:
- Accuracy, Balanced Accuracy
- Per-class Precision, Recall (Sensitivity), Specificity, and F1-score
- Macro-F1, Weighted-F1
- Multiclass ROC-AUC (One-vs-Rest)
- Generates:
  reports/confusion_matrix.png
  reports/metrics.json
  reports/test_predictions.csv
"""

import os
import sys

# Ensure project root is in sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

import csv
import json
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns
import torch
import torch.nn.functional as F
from sklearn.metrics import (
    accuracy_score, balanced_accuracy_score, precision_recall_fscore_support,
    confusion_matrix, roc_auc_score
)

from src.utils import load_config, get_device, CLASS_NAMES_3CLASS, MEDICAL_DISCLAIMER
from src.dataset import get_data_loaders
from src.train import build_model


def evaluate_model(model=None, test_loader=None, config=None, config_path="config.yaml"):
    """
    Evaluates model on held-out test split, computes medical metrics,
    and produces evaluation reports.
    """
    if config is None:
        config = load_config(config_path)

    device, _ = get_device()
    models_dir = config['paths']['models_dir']
    reports_dir = config['paths']['reports_dir']
    os.makedirs(reports_dir, exist_ok=True)

    if model is None:
        model = build_model(config)
        weights_path = os.path.join(models_dir, "best_model.pth")
        if not os.path.exists(weights_path):
            raise FileNotFoundError(f"Model weights not found: {weights_path}")
        model.load_state_dict(torch.load(weights_path, map_location=device))
        model.to(device)

    if test_loader is None:
        _, _, test_loader, _, _ = get_data_loaders(config)

    model.eval()
    all_preds = []
    all_targets = []
    all_probs = []
    all_subjs = []
    all_sessions = []
    all_cdrs = []

    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

    print("\n" + "=" * 60)
    print("[EVALUATE] EVALUATING MODEL ON HELD-OUT TEST SPLIT")
    print("=" * 60)

    with torch.no_grad():
        for batch in test_loader:
            images = batch['image'].to(device)
            labels = batch['label'].to(device)

            logits = model(images)
            probs = F.softmax(logits, dim=1).cpu().numpy()
            preds = np.argmax(probs, axis=1)

            all_probs.extend(probs)
            all_preds.extend(preds)
            all_targets.extend(labels.cpu().numpy())
            all_subjs.extend(batch['subject_id'])
            all_sessions.extend(batch['session_id'])
            all_cdrs.extend(batch['cdr'])

    all_targets = np.array(all_targets)
    all_preds = np.array(all_preds)
    all_probs = np.array(all_probs)

    # 1. Global Metrics
    acc = accuracy_score(all_targets, all_preds)
    bal_acc = balanced_accuracy_score(all_targets, all_preds)
    p_macro, r_macro, f1_macro, _ = precision_recall_fscore_support(all_targets, all_preds, average='macro', zero_division=0)
    p_wt, r_wt, f1_wt, _ = precision_recall_fscore_support(all_targets, all_preds, average='weighted', zero_division=0)

    # 2. Per-Class Metrics & Specificity
    precision_per_class, recall_per_class, f1_per_class, support_per_class = precision_recall_fscore_support(
        all_targets, all_preds, labels=[0, 1, 2], zero_division=0
    )

    cm = confusion_matrix(all_targets, all_preds, labels=[0, 1, 2])
    specificity_per_class = []
    for i in range(3):
        tn = np.sum(np.delete(np.delete(cm, i, axis=0), i, axis=1))
        fp = np.sum(np.delete(cm, i, axis=0)[:, i])
        spec = float(tn / (tn + fp)) if (tn + fp) > 0 else 0.0
        specificity_per_class.append(spec)

    # 3. Multiclass ROC-AUC (One-vs-Rest)
    try:
        if len(np.unique(all_targets)) > 1:
            roc_auc = float(roc_auc_score(all_targets, all_probs, multi_class='ovr', labels=[0, 1, 2]))
        else:
            roc_auc = None
    except Exception:
        roc_auc = None

    # Print Medical Report
    print(f"\n[REPORT] TEST EVALUATION METRICS SUMMARY (Subject-Disjoint Test Set, N={len(all_targets)}):")
    print(f"  * Raw Accuracy:         {acc * 100:.2f}%")
    print(f"  * Balanced Accuracy:    {bal_acc * 100:.2f}%")
    print(f"  * Macro-F1 (Primary):   {f1_macro:.4f}")
    print(f"  * Weighted-F1:          {f1_wt:.4f}")
    print(f"  * Macro Recall/Sens:    {r_macro:.4f}")
    print(f"  * Macro Precision:      {p_macro:.4f}")
    if roc_auc is not None:
        print(f"  * Multiclass ROC-AUC:   {roc_auc:.4f}")

    print("\n[REPORT] PER-CLASS PERFORMANCE BREAKDOWN:")
    for c_id in range(3):
        c_name = CLASS_NAMES_3CLASS[c_id]
        print(f"  [{c_id}] {c_name:<25}: Support={support_per_class[c_id]:2d} | Sens/Recall={recall_per_class[c_id]:.3f} | Spec={specificity_per_class[c_id]:.3f} | F1={f1_per_class[c_id]:.3f} | Prec={precision_per_class[c_id]:.3f}")

    # 4. Save metrics.json
    metrics_dict = {
        "disclaimer": MEDICAL_DISCLAIMER,
        "sample_count": int(len(all_targets)),
        "accuracy": float(acc),
        "balanced_accuracy": float(bal_acc),
        "macro_f1": float(f1_macro),
        "weighted_f1": float(f1_wt),
        "macro_recall_sensitivity": float(r_macro),
        "macro_precision": float(p_macro),
        "roc_auc_ovr": float(roc_auc) if roc_auc is not None else None,
        "confusion_matrix": cm.tolist(),
        "per_class": {}
    }
    for c_id in range(3):
        c_name = CLASS_NAMES_3CLASS[c_id]
        metrics_dict["per_class"][c_name] = {
            "class_id": c_id,
            "support": int(support_per_class[c_id]),
            "sensitivity_recall": float(recall_per_class[c_id]),
            "specificity": float(specificity_per_class[c_id]),
            "precision": float(precision_per_class[c_id]),
            "f1_score": float(f1_per_class[c_id])
        }

    metrics_path = os.path.join(reports_dir, "metrics.json")
    with open(metrics_path, "w", encoding="utf-8") as f:
        json.dump(metrics_dict, f, indent=2)
    print(f"\n[SAVED] Metrics JSON: {metrics_path}")

    # 5. Save test_predictions.csv
    test_preds_path = os.path.join(reports_dir, "test_predictions.csv")
    with open(test_preds_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["subject_id", "session_id", "clinical_cdr", "true_label", "true_label_name",
                         "pred_label", "pred_label_name", "confidence",
                         "prob_normal", "prob_very_mild", "prob_dementia"])
        for i in range(len(all_targets)):
            writer.writerow([
                all_subjs[i], all_sessions[i], all_cdrs[i],
                int(all_targets[i]), CLASS_NAMES_3CLASS[int(all_targets[i])],
                int(all_preds[i]), CLASS_NAMES_3CLASS[int(all_preds[i])],
                f"{float(np.max(all_probs[i])):.4f}",
                f"{float(all_probs[i][0]):.4f}",
                f"{float(all_probs[i][1]):.4f}",
                f"{float(all_probs[i][2]):.4f}"
            ])
    print(f"[SAVED] Test predictions CSV: {test_preds_path}")

    # 6. Generate and save Confusion Matrix plot
    cm_path = os.path.join(reports_dir, "confusion_matrix.png")
    plt.figure(figsize=(7, 6))
    class_labels = [CLASS_NAMES_3CLASS[i] for i in range(3)]
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues',
                xticklabels=class_labels, yticklabels=class_labels, cbar=False)
    plt.title("Confusion Matrix — Dementia Severity Estimation\n(AI-Assisted Estimation | Not a Diagnosis)", fontsize=11)
    plt.ylabel("Clinical Ground Truth (CDR)")
    plt.xlabel("Model Estimated Class")
    plt.tight_layout()
    plt.savefig(cm_path, dpi=150)
    plt.close()
    print(f"[SAVED] Confusion matrix plot: {cm_path}")
    print("=" * 60)

    return metrics_dict


if __name__ == "__main__":
    evaluate_model()
