import json
import os
import sys
import tarfile
import hashlib
from pathlib import Path

# Project root
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

import torch
import numpy as np
import pandas as pd

from src.preprocessing import preprocess_mri


def run_disc5_audit():
    print("=" * 80)
    print("OASIS-1 DISC 5 INTEGRATION AUDIT")
    print("=" * 80)

    # 1. Verify Archive
    tar_path = Path(r"C:\Users\LENOVO\Downloads\oasis_cross-sectional_disc5.tar.gz")
    assert tar_path.exists(), f"Archive not found: {tar_path}"
    tar_size = tar_path.stat().st_size
    print(f"\n[1] ARCHIVE VERIFICATION")
    print(f"  Path: {tar_path}")
    print(f"  Size: {tar_size:,} bytes ({tar_size / (1024**2):.2f} MB, {tar_size / (1024**3):.2f} GB)")

    # 2. Extract into data/raw/
    raw_dir = Path("data/raw")
    disc5_dir = raw_dir / "disc5"
    if not disc5_dir.exists():
        print(f"\n[2] EXTRACTING DISC 5 INTO data/raw/...")
        with tarfile.open(tar_path, "r:gz") as tar:
            tar.extractall(path=raw_dir)
        print(f"  Extraction complete. Target directory: {disc5_dir}")
    else:
        print(f"\n[2] data/raw/disc5 already exists. Skipping re-extraction.")

    # 3. Audit Extracted Contents
    session_dirs = sorted([d for d in disc5_dir.iterdir() if d.is_dir()])
    print(f"\n[3] SESSION & SUBJECT AUDIT")
    print(f"  Total Session Directories: {len(session_dirs)}")
    subjects = sorted(list(set([d.name.rsplit('_', 1)[0] for d in session_dirs])))
    print(f"  Total Unique Subjects:     {len(subjects)}")

    # Check for target atlas skull-stripped files
    found_masked = 0
    missing_masked = []
    for s in session_dirs:
        masked = list(s.rglob("*_masked_gfc.img"))
        if masked:
            found_masked += 1
        else:
            missing_masked.append(s.name)

    print(f"  Target Scans (*_masked_gfc.img): {found_masked}/{len(session_dirs)} found.")
    if missing_masked:
        print(f"  WARNING: Missing target scans in: {missing_masked}")

    # 4. Match Against Clinical Metadata
    excel_path = Path("data/metadata/oasis_cross-sectional.xlsx")
    df_excel = pd.read_excel(excel_path)
    df_disc5 = df_excel[df_excel["ID"].isin([s.name for s in session_dirs])].copy()

    # Repeat sessions within Disc 5
    repeat_subjs = [s for s in subjects if len([d for d in session_dirs if d.name.startswith(s)]) > 1]
    print(f"  Subjects with multiple sessions in Disc 5: {len(repeat_subjs)} -> {repeat_subjs}")

    # Label classification
    labeled_rows = []
    unassessed_rows = []
    for s_dir in session_dirs:
        sess_id = s_dir.name
        sub_id = sess_id.rsplit("_", 1)[0]
        meta = df_excel[df_excel["ID"] == sess_id]

        masked_imgs = list(s_dir.rglob("*_masked_gfc.img"))
        mri_path = str(masked_imgs[0]).replace("\\", "/") if masked_imgs else "NOT_FOUND"

        if len(meta) == 0:
            unassessed_rows.append({"subject_id": sub_id, "session_id": sess_id, "mri_path": mri_path, "cdr": "N/A", "label": -1})
            continue

        raw_cdr = meta["CDR"].values[0]
        age = meta["Age"].values[0]
        gender = meta["M/F"].values[0]
        mmse = meta["MMSE"].values[0]

        if pd.isna(raw_cdr):
            unassessed_rows.append({"subject_id": sub_id, "session_id": sess_id, "mri_path": mri_path, "cdr": "NaN", "label": -1})
        else:
            cdr_val = float(raw_cdr)
            if cdr_val == 0.0:
                cls = 0
                cls_name = "Normal"
            elif cdr_val == 0.5:
                cls = 1
                cls_name = "Very Mild Dementia"
            elif cdr_val >= 1.0:
                cls = 2
                cls_name = "Dementia (Mild/Moderate)"
            else:
                cls = -1
                cls_name = "Unknown"

            labeled_rows.append({
                "subject_id": sub_id,
                "session_id": sess_id,
                "mri_path": mri_path,
                "hdr_path": mri_path.replace(".img", ".hdr"),
                "age": age,
                "gender": gender,
                "mmse": mmse,
                "cdr": cdr_val,
                "class": cls,
                "class_name": cls_name
            })

    print(f"\n[4] CLINICAL LABEL BREAKDOWN")
    print(f"  Clinically Labeled Subjects (CDR >= 0): {len(labeled_rows)}")
    print(f"  Unassessed Young Controls (CDR NaN):    {len(unassessed_rows)}")

    class_counts = {0: 0, 1: 0, 2: 0}
    for r in labeled_rows:
        class_counts[r["class"]] += 1

    print(f"  Class Distribution in Disc 5:")
    print(f"    Class 0 (Normal, CDR 0.0):             {class_counts[0]}")
    print(f"    Class 1 (Very Mild Dementia, CDR 0.5): {class_counts[1]}")
    print(f"    Class 2 (Dementia, CDR >= 1.0):        {class_counts[2]}")

    # 5. Overlap & Leakage Check with Existing Splits
    split_dir = Path("splits/split_v3_disc1_disc2_disc3_disc4")
    tr_subs = set(split_dir.joinpath("train_subjects.txt").read_text().strip().splitlines())
    va_subs = set(split_dir.joinpath("val_subjects.txt").read_text().strip().splitlines())
    te_subs = set(split_dir.joinpath("test_subjects.txt").read_text().strip().splitlines())
    dataset_76_subs = tr_subs | va_subs | te_subs

    disc5_labeled_subs = set([r["subject_id"] for r in labeled_rows])

    overlap_dataset = disc5_labeled_subs.intersection(dataset_76_subs)
    overlap_train = disc5_labeled_subs.intersection(tr_subs)
    overlap_val = disc5_labeled_subs.intersection(va_subs)
    overlap_test = disc5_labeled_subs.intersection(te_subs)

    print(f"\n[5] OVERLAP & DATA LEAKAGE AUDIT")
    print(f"  Disc 5 Labeled vs 76-subject dataset overlap: {len(overlap_dataset)} {overlap_dataset}")
    print(f"  Disc 5 Labeled vs Train split overlap:       {len(overlap_train)} {overlap_train}")
    print(f"  Disc 5 Labeled vs Val split overlap:         {len(overlap_val)} {overlap_val}")
    print(f"  Disc 5 Labeled vs Frozen Test split overlap: {len(overlap_test)} {overlap_test}")
    assert len(overlap_dataset) == 0, f"Critical overlap found: {overlap_dataset}"
    print(f"  [PASS] ZERO subject overlap. All {len(disc5_labeled_subs)} labeled Disc 5 subjects are 100% novel.")

    # 6. Preprocessing Verification on All 18 Clinically Labeled Scans
    print(f"\n[6] PREPROCESSING VERIFICATION ON ALL {len(labeled_rows)} CLINICALLY LABELED SCANS")
    all_prep_pass = True
    prep_results = []

    for idx, r in enumerate(labeled_rows, 1):
        mri_path = r["mri_path"]
        hdr_path = r["hdr_path"]
        sess = r["session_id"]
        sub = r["subject_id"]

        try:
            t = preprocess_mri(
                mri_path=mri_path,
                hdr_path=hdr_path,
                target_shape=(96, 96, 96),
                normalize="zscore",
                is_train=False
            )

            is_valid_shape = tuple(t.shape) == (1, 96, 96, 96)
            is_valid_dtype = (t.dtype == torch.float32)
            has_no_nan = not torch.isnan(t).any().item()
            has_no_inf = not torch.isinf(t).any().item()
            is_non_empty = (t.std().item() > 0.1) and (t.min().item() < t.max().item())

            valid = is_valid_shape and is_valid_dtype and has_no_nan and has_no_inf and is_non_empty

            if not valid:
                all_prep_pass = False

            prep_results.append({
                "subject_id": sub,
                "session_id": sess,
                "cdr": r["cdr"],
                "class": r["class"],
                "class_name": r["class_name"],
                "mri_path": mri_path,
                "valid": valid,
                "shape": tuple(t.shape),
                "dtype": str(t.dtype),
                "min": round(t.min().item(), 2),
                "max": round(t.max().item(), 2)
            })

            status = "PASS" if valid else "FAIL"
            print(f"  [{idx:2d}/{len(labeled_rows)}] {sess} ({sub}) | CDR={r['cdr']} (Class {r['class']}) -> {status} [shape={tuple(t.shape)}, float32, no NaN/Inf]")
        except Exception as e:
            all_prep_pass = False
            print(f"  [{idx:2d}/{len(labeled_rows)}] {sess} ({sub}) -> ERROR: {e}")

    assert all_prep_pass, "One or more scans failed preprocessing!"
    print(f"\n  [PASS] All {len(labeled_rows)} clinically labeled Disc 5 scans passed preprocessing successfully!")

    # 7. Checkpoint Safety Confirmation
    print(f"\n[7] CHECKPOINT SAFETY AUDIT")
    ckpt_best = Path("models/best_model.pth")
    ckpt_d4 = Path("models/best_model_disc4.pth")

    with open(ckpt_best, "rb") as f:
        sha_best = hashlib.sha256(f.read()).hexdigest()
    with open(ckpt_d4, "rb") as f:
        sha_d4 = hashlib.sha256(f.read()).hexdigest()

    print(f"  models/best_model.pth:       SHA-256={sha_best} (UNTOUCHED)")
    print(f"  models/best_model_disc4.pth: SHA-256={sha_d4} (UNTOUCHED)")
    assert sha_best == "85aa7a5dd60f84f8f276eaacc46bd3a50df7cc8b03c872f5cd22cef19d88bfeb"
    assert sha_d4 == "7b23efdb1609999478f8b4ad8af1e731aba4d3ec051846520b1ee303e2f04fde"

    # Save summary json
    with open("reports/disc5_audit_summary.json", "w", encoding="utf-8") as f:
        json.dump({
            "total_sessions": len(session_dirs),
            "total_unique_subjects": len(subjects),
            "clinically_labeled_count": len(labeled_rows),
            "unassessed_count": len(unassessed_rows),
            "class_distribution": class_counts,
            "labeled_subjects": prep_results
        }, f, indent=2)

    print("\n" + "=" * 80)
    print("DISC 5 AUDIT COMPLETED SUCCESSFULLY")
    print("NO DATASET OR SPLIT FILES MODIFIED")
    print("=" * 80)


if __name__ == "__main__":
    run_disc5_audit()
