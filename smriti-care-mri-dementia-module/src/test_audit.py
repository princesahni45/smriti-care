"""
Comprehensive Audit Script for OASIS-1 MRI Severity Estimation Pipeline.
Tests:
1. Label mapping
2. Checkpoint inspection
3. Preprocessing inspection
4. OAS1_0001_MR1_t1.nii.gz vs OAS1_0001_MR1 Analyze scan
5. Multiple known-label OASIS samples (Normal, Very Mild, Dementia)
6. Grad-CAM layer check
7. Split leakage audit
"""
import os
import sys
import json
import torch
import numpy as np
import nibabel as nib
import torch.nn.functional as F

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from src.utils import load_config, get_device, CLASS_NAMES_3CLASS
from src.inference import MRIInferencePipeline
from src.preprocessing import preprocess_mri, load_analyze_volume, crop_brain_nonzero, resize_volume_3d, normalize_intensity_volume


def run_audit():
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

    print("=" * 70)
    print("AI-ASSISTED DEMENTIA SEVERITY ESTIMATION: COMPLETE PIPELINE AUDIT")
    print("=" * 70)

    # 1. Label Mapping Check
    print("\n--- 1. LABEL MAPPING AUDIT ---")
    config = load_config("config.yaml")
    mapping_config = config['target_classes']['mapping']
    with open("models/class_mapping.json", "r", encoding="utf-8") as f:
        mapping_checkpoint = json.load(f)

    print("Config mapping:    ", mapping_config)
    print("Checkpoint mapping:", mapping_checkpoint)
    print("Utils mapping:     ", CLASS_NAMES_3CLASS)
    consistent = (list(mapping_config.values()) == list(mapping_checkpoint.values()) == list(CLASS_NAMES_3CLASS.values()))
    print(f"Mapping Consistency Status: {'PERFECT MATCH' if consistent else 'MISMATCH DETECTED'}")

    # 2. Checkpoint Audit
    print("\n--- 2. CHECKPOINT AUDIT ---")
    ckpt_path = "models/best_model.pth"
    print(f"Checkpoint path: {ckpt_path} (Exists: {os.path.exists(ckpt_path)})")
    if os.path.exists(ckpt_path):
        sz = os.path.getsize(ckpt_path)
        print(f"Size: {sz / 1024 / 1024:.2f} MB")
    with open("models/model_config.json", "r", encoding="utf-8") as f:
        model_meta = json.load(f)
    print("Model Config Metadata:")
    for k, v in model_meta.items():
        print(f"  {k}: {v}")

    # 3 & 4. Input File & Preprocessing Audit: OAS1_0001_MR1_t1.nii.gz vs OASIS Analyze
    print("\n--- 3 & 4. INPUT FILE & PREPROCESSING AUDIT ---")
    nii_path = "C:/Users/LENOVO/Downloads/OAS1_0001_MR1_t1.nii.gz"
    img_masked = "data/raw/disc1/OAS1_0001_MR1/PROCESSED/MPRAGE/T88_111/OAS1_0001_MR1_mpr_n4_anon_111_t88_masked_gfc.img"
    img_unmasked = "data/raw/disc1/OAS1_0001_MR1/PROCESSED/MPRAGE/T88_111/OAS1_0001_MR1_mpr_n4_anon_111_t88_gfc.img"

    if os.path.exists(nii_path):
        nii = nib.load(nii_path)
        nii_data = np.asanyarray(nii.dataobj)
        nii_zooms = nii.header.get_zooms()[:3]
        nii_axcodes = nib.aff2axcodes(nii.affine)
        print(f"NIfTI Input (OAS1_0001_MR1_t1.nii.gz):")
        print(f"  Shape:             {nii_data.shape}")
        print(f"  Orientation Codes: {nii_axcodes}")
        print(f"  Voxel Spacing:     {nii_zooms}")
        print(f"  Intensity Range:   [{nii_data.min()}, {nii_data.max()}]")
        print(f"  Intensity Mean:    {nii_data.mean():.2f} (Std: {nii_data.std():.2f})")
        print(f"  Zero Voxels:       {(nii_data == 0).mean() * 100:.2f}% (INDICATES UNMASKED / WITH SKULL)")
    else:
        print(f"[WARN] NIfTI file not found at {nii_path}")

    if os.path.exists(img_masked):
        img_m = nib.load(img_masked)
        m_data = np.asanyarray(img_m.dataobj)
        m_zooms = img_m.header.get_zooms()[:3]
        m_axcodes = nib.aff2axcodes(img_m.affine)
        print(f"\nTraining Representation (OASIS-1 *_masked_gfc.img):")
        print(f"  Shape:             {m_data.shape}")
        print(f"  Orientation Codes: {m_axcodes}")
        print(f"  Voxel Spacing:     {m_zooms}")
        print(f"  Intensity Range:   [{m_data.min()}, {m_data.max()}]")
        print(f"  Intensity Mean:    {m_data.mean():.2f} (Std: {m_data.std():.2f})")
        print(f"  Zero Voxels:       {(m_data == 0).mean() * 100:.2f}% (INDICATES BRAIN-MASKED / SKULL-STRIPPED)")

    # 5. Dataset Matching: Was OAS1_0001_MR1 in training?
    print("\n--- 5. DATASET MATCHING AUDIT ---")
    with open("splits/split_v2_disc1_disc2_disc3/train_subjects.txt", "r") as f:
        train_subjs = set(f.read().splitlines())
    with open("splits/split_v2_disc1_disc2_disc3/val_subjects.txt", "r") as f:
        val_subjs = set(f.read().splitlines())
    with open("splits/split_v2_disc1_disc2_disc3/test_subjects.txt", "r") as f:
        test_subjs = set(f.read().splitlines())

    if "OAS1_0001" in train_subjs:
        split_loc = "TRAIN SET"
    elif "OAS1_0001" in val_subjs:
        split_loc = "VALIDATION SET"
    elif "OAS1_0001" in test_subjs:
        split_loc = "TEST SET (HELD-OUT)"
    else:
        split_loc = "NOT FOUND"
    print(f"OAS1_0001 split location: {split_loc}")

    # 6. Model Sanity Check across Multiple Known-Label OASIS Scans
    print("\n--- 6. MODEL SANITY CHECK ACROSS KNOWN LABELS ---")
    pipeline = MRIInferencePipeline()

    # Compare inference on NIfTI vs masked Analyze for OAS1_0001:
    res_nii = pipeline.predict(nii_path) if os.path.exists(nii_path) else None
    res_m = pipeline.predict(img_masked)
    print("\n[A] OAS1_0001_MR1 (Ground-Truth CDR 0.0 -> Normal):")
    if res_nii:
        print(f"  * Using NIfTI ({nii_path}):")
        print(f"      Prediction: {res_nii['prediction']} (Conf: {res_nii['confidence']*100:.2f}%)")
        print(f"      Probabilities: {res_nii['probabilities']}")
    print(f"  * Using Training Representation (*_masked_gfc.img):")
    print(f"      Prediction: {res_m['prediction']} (Conf: {res_m['confidence']*100:.2f}%)")
    print(f"      Probabilities: {res_m['probabilities']}")

    # Known Very Mild (CDR 0.5): OAS1_0003_MR1
    img_0003 = "data/raw/disc1/OAS1_0003_MR1/PROCESSED/MPRAGE/T88_111/OAS1_0003_MR1_mpr_n4_anon_111_t88_masked_gfc.img"
    res_0003 = pipeline.predict(img_0003)
    print("\n[B] OAS1_0003_MR1 (Ground-Truth CDR 0.5 -> Very Mild Dementia):")
    print(f"  Prediction: {res_0003['prediction']} (Conf: {res_0003['confidence']*100:.2f}%)")
    print(f"  Probabilities: {res_0003['probabilities']}")

    # Known Dementia (CDR 1.0): OAS1_0052_MR1 & OAS1_0031_MR1
    for sess, cdr_val in [('OAS1_0031_MR1', '1.0'), ('OAS1_0052_MR1', '1.0'), ('OAS1_0028_MR1', '1.0')]:
        sub_dir = "disc1" if int(sess.split('_')[1]) <= 42 else "disc2"
        p = f"data/raw/{sub_dir}/{sess}/PROCESSED/MPRAGE/T88_111/{sess}_mpr_n4_anon_111_t88_masked_gfc.img"
        if os.path.exists(p):
            r = pipeline.predict(p)
            print(f"\n[C] {sess} (Ground-Truth CDR {cdr_val} -> Dementia):")
            print(f"  Prediction: {r['prediction']} (Conf: {r['confidence']*100:.2f}%)")
            print(f"  Probabilities: {r['probabilities']}")

    # 7. Grad-CAM Layer Verification
    print("\n--- 7. GRAD-CAM LAYER AUDIT ---")
    target_layer = pipeline.model.get_target_layer_for_cam()
    print(f"Model target layer: {target_layer}")
    print(f"Type: {type(target_layer)}")

    # 8. Data Leakage Verification
    print("\n--- 8. DATA LEAKAGE & SPLIT AUDIT ---")
    overlap_tv = train_subjs.intersection(val_subjs)
    overlap_tt = train_subjs.intersection(test_subjs)
    overlap_vt = val_subjs.intersection(test_subjs)
    print(f"Train subjects: {len(train_subjs)}")
    print(f"Val subjects:   {len(val_subjs)}")
    print(f"Test subjects:  {len(test_subjs)}")
    print(f"Overlap Train & Val:  {overlap_tv}")
    print(f"Overlap Train & Test: {overlap_tt}")
    print(f"Overlap Val & Test:   {overlap_vt}")
    print(f"Leakage status: {'STRICT ZERO LEAKAGE' if not (overlap_tv or overlap_tt or overlap_vt) else 'LEAKAGE FOUND'}")

    print("\n" + "=" * 70)
    print("AUDIT COMPLETE")
    print("=" * 70)


if __name__ == '__main__':
    run_audit()
