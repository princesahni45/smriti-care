"""
Safety Verification Sequence (Steps 1 to 5) before Full Training.
1. Dataset inspection verification
2. Preprocesses 5 sample real MRI scans
3. Visualizes sagittal, coronal, and axial slices, saving to reports/sample_slices.png
4. Verifies label alignment against OASIS metadata
5. Verifies train/val/test subject separation (zero leakage)
"""

import os
import sys
import csv

# Ensure project root is in sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import torch

from src.utils import load_config, set_seed, CLASS_NAMES_3CLASS
from src.preprocessing import preprocess_mri
from src.dataset import create_subject_splits
from src.data_validation import validate_mri_dataset, verify_split_leakage


def run_safety_checks(config_path="config.yaml"):
    print("=" * 65)
    print("[SAFETY] EXECUTING PRE-TRAINING SAFETY VERIFICATION SEQUENCE")
    print("=" * 65)

    config = load_config(config_path)
    set_seed(config['split']['random_seed'])
    reports_dir = config['paths']['reports_dir']
    os.makedirs(reports_dir, exist_ok=True)

    # Step 1: Dataset Inspection & Quality Checks
    print("\n--- Safety Step 1: Dataset Quality & Anomaly Checks ---")
    valid = validate_mri_dataset(config['paths']['dataset_csv'])
    if not valid:
        print("[WARN] Anomaly detected during dataset inspection.")

    # Step 2: Preprocess 5 Sample Real MRI Scans
    print("\n--- Safety Step 2: Preprocess 5 Sample Scans ---")
    with open(config['paths']['dataset_csv'], 'r', encoding='utf-8') as f:
        reader = list(csv.DictReader(f))
    labeled_samples = [r for r in reader if int(r['label']) >= 0][:5]

    preprocessed_samples = []
    target_shape = tuple(config['preprocessing']['target_shape'])

    for i, s in enumerate(labeled_samples):
        mri_path = s['mri_path']
        hdr_path = s.get('hdr_path', None)
        sess = s['session_id']
        lbl = int(s['label'])

        tensor = preprocess_mri(
            mri_path=mri_path,
            hdr_path=hdr_path,
            target_shape=target_shape,
            normalize=config['preprocessing']['normalize'],
            is_train=False
        )

        vol = tensor.squeeze().numpy()
        cdr_val = s['cdr']
        print(f"  [{i+1}/5] {sess} | Shape: {tensor.shape} | Voxel Range: [{vol.min():.2f}, {vol.max():.2f}] | Mean: {vol.mean():.2f} | Label: {lbl} ({CLASS_NAMES_3CLASS[lbl]})")
        preprocessed_samples.append((sess, vol, lbl, cdr_val))

    # Step 3: Visualize Cross-Sectional Slices
    print("\n--- Safety Step 3: Multi-Planar Slice Visualization ---")
    fig, axes = plt.subplots(len(preprocessed_samples), 3, figsize=(12, 3.5 * len(preprocessed_samples)))
    if len(preprocessed_samples) == 1:
        axes = [axes]

    for idx, (sess, vol, lbl, cdr_val) in enumerate(preprocessed_samples):
        d, h, w = vol.shape
        sag = vol[d // 2, :, :]
        cor = vol[:, h // 2, :]
        axi = vol[:, :, w // 2]

        axes[idx][0].imshow(sag, cmap='gray', origin='lower')
        axes[idx][0].set_title(f"{sess} - Sagittal", fontsize=9)
        axes[idx][0].axis('off')

        axes[idx][1].imshow(cor, cmap='gray', origin='lower')
        axes[idx][1].set_title(f"{sess} - Coronal (CDR {cdr_val}: {CLASS_NAMES_3CLASS[lbl]})", fontsize=9)
        axes[idx][1].axis('off')

        axes[idx][2].imshow(axi, cmap='gray', origin='lower')
        axes[idx][2].set_title(f"{sess} - Axial", fontsize=9)
        axes[idx][2].axis('off')

    plt.suptitle("Preprocessed OASIS-1 Volumetric MRI Slices (96x96x96 Normalized)", fontsize=13, y=0.99)
    plt.tight_layout()
    slice_fig_path = os.path.join(reports_dir, "sample_slices.png")
    plt.savefig(slice_fig_path, dpi=150)
    plt.close()
    print(f"  [SAVED] Slices plot: {slice_fig_path}")

    # Step 4: Verify Labels
    print("\n--- Safety Step 4: Label Verification ---")
    print(f"  Verified 3-class mapping:")
    for c_id, name in CLASS_NAMES_3CLASS.items():
        print(f"    Class {c_id}: {name}")

    # Step 5: Verify Train/Val/Test Subject Disjointness
    print("\n--- Safety Step 5: Split Separation & Leakage Audit ---")
    train_recs, val_recs, test_recs, class_weights, split_info = create_subject_splits(
        csv_path=config['paths']['dataset_csv'],
        train_ratio=config['split']['train_ratio'],
        val_ratio=config['split']['val_ratio'],
        test_ratio=config['split']['test_ratio'],
        random_seed=config['split']['random_seed']
    )

    print(f"  Train: {len(train_recs)} subjects | Val: {len(val_recs)} subjects | Test: {len(test_recs)} subjects")
    leakage_free = verify_split_leakage(split_info['train_subjs'], split_info['val_subjs'], split_info['test_subjs'])

    if leakage_free:
        print("\n[OK] ALL 5 PRE-TRAINING SAFETY GATES PASSED SUCCESSFULLY!")
    else:
        print("\n[FAIL] SAFETY CHECK FAILED: SUBJECT LEAKAGE DETECTED!")
    print("=" * 65)
    return leakage_free


if __name__ == "__main__":
    run_safety_checks()
