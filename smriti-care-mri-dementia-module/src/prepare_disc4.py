import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
"""
Disc 4 Preparation Script
Executes:
1. Combined manifest generation (Disc 1+2+3+4) -> mri_dataset_v3_disc1_disc2_disc3_disc4.csv & mri_dataset.csv
2. Split v3 generation -> splits/split_v3_disc1_disc2_disc3_disc4/ (train, val, test)
3. Incremental pre-caching of ONLY the 15 clinically labeled Disc 4 scans -> data/processed/{session_id}_prep.pt
4. Tensor validation
5. Leakage audit
6. Checkpoint immutability check
"""

import os
import re
import csv
import shutil
import hashlib
import torch
import numpy as np
import pandas as pd
from pathlib import Path

from src.preprocessing import preprocess_mri


def run_preparation():
    print("=" * 70)
    print("OASIS-1 DISC 4 PREPARATION PIPELINE")
    print("=" * 70)

    # ---------------------------------------------------------
    # Checkpoint Baseline
    # ---------------------------------------------------------
    ckpt_path = Path("models/best_model.pth")
    assert ckpt_path.exists(), "models/best_model.pth does not exist!"
    with open(ckpt_path, "rb") as f:
        ckpt_sha_before = hashlib.sha256(f.read()).hexdigest()
    ckpt_size_before = ckpt_path.stat().st_size
    ckpt_mtime_before = ckpt_path.stat().st_mtime
    print(f"\n[0] Initial Checkpoint Status:")
    print(f"    Path:    {ckpt_path}")
    print(f"    Size:    {ckpt_size_before} bytes")
    print(f"    SHA-256: {ckpt_sha_before}")

    # ---------------------------------------------------------
    # 1. Manifest Discovery (Discs 1, 2, 3, 4)
    # ---------------------------------------------------------
    print(f"\n[1] Generating Combined Manifest (Discs 1-4)...")
    excel_path = Path("data/metadata/oasis_cross-sectional.xlsx")
    df_excel = pd.read_excel(excel_path)
    meta_by_id = {}
    for _, row in df_excel.iterrows():
        sid = str(row["ID"]).strip()
        meta_by_id[sid] = row

    raw_dir = Path("data/raw")
    session_dirs = sorted([d for d in raw_dir.glob("disc*/*") if d.is_dir()])
    print(f"    Found {len(session_dirs)} total session directories across all discs.")

    dataset_rows = []
    cdr_counts = {}
    unassessed_count = 0

    for s_dir in session_dirs:
        session_id = s_dir.name
        m = re.match(r"(OAS1_\d{4})_MR(\d+)", session_id)
        if not m:
            continue
        subject_id = m.group(1)

        # Atlas registered masked scan
        processed_masked = list(s_dir.rglob("*_masked_gfc.img"))
        if processed_masked:
            mri_img = processed_masked[0]
        else:
            raw_imgs = list(s_dir.rglob("*.img"))
            if not raw_imgs:
                continue
            mri_img = raw_imgs[0]

        mri_hdr = mri_img.with_suffix(".hdr")
        if not mri_hdr.exists():
            continue

        meta_row = meta_by_id.get(session_id, None)
        raw_cdr = ""
        age = ""
        gender = ""
        mmse = ""
        if meta_row is not None:
            raw_cdr_val = meta_row.get("CDR")
            if pd.notna(raw_cdr_val):
                raw_cdr = str(raw_cdr_val).strip()
            age = meta_row.get("Age", "")
            gender = meta_row.get("M/F", "")
            mmse = meta_row.get("MMSE", "")

        if raw_cdr == "" or raw_cdr.lower() == "n/a" or raw_cdr.lower() == "nan":
            unassessed_count += 1
            label = -1
            label_name = "Unassessed (Young Control)"
            cdr_val = "N/A"
        else:
            cdr_num = float(raw_cdr)
            cdr_val = raw_cdr
            cdr_counts[cdr_num] = cdr_counts.get(cdr_num, 0) + 1
            if cdr_num == 0.0:
                label = 0
                label_name = "Normal"
            elif cdr_num == 0.5:
                label = 1
                label_name = "Very Mild Dementia"
            elif cdr_num >= 1.0:
                label = 2
                label_name = "Dementia (Mild/Moderate)"
            else:
                label = -1
                label_name = "Unknown"

        dataset_rows.append({
            "subject_id": subject_id,
            "session_id": session_id,
            "mri_path": str(mri_img).replace("\\", "/"),
            "hdr_path": str(mri_hdr).replace("\\", "/"),
            "age": age,
            "gender": gender,
            "mmse": mmse,
            "cdr": cdr_val,
            "label": label,
            "label_name": label_name
        })

    v3_manifest_path = Path("data/metadata/mri_dataset_v3_disc1_disc2_disc3_disc4.csv")
    manifest_path = Path("data/metadata/mri_dataset.csv")

    fieldnames = ["subject_id", "session_id", "mri_path", "hdr_path", "age", "gender", "mmse", "cdr", "label", "label_name"]
    with open(v3_manifest_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(dataset_rows)

    # Update active manifest
    shutil.copyfile(v3_manifest_path, manifest_path)
    print(f"    Saved v3 manifest: {v3_manifest_path} ({len(dataset_rows)} rows)")
    print(f"    Updated active manifest: {manifest_path}")

    # ---------------------------------------------------------
    # 2. Split v3 Construction
    # ---------------------------------------------------------
    print(f"\n[2] Constructing Subject-Level Split v3...")
    split_v2_dir = Path("splits/split_v2_disc1_disc2_disc3")
    v2_train = split_v2_dir.joinpath("train_subjects.txt").read_text().strip().splitlines()
    v2_val = split_v2_dir.joinpath("val_subjects.txt").read_text().strip().splitlines()
    v2_test = split_v2_dir.joinpath("test_subjects.txt").read_text().strip().splitlines()

    print(f"    Baseline Split v2 Counts:")
    print(f"      Train: {len(v2_train)} subjects")
    print(f"      Val:   {len(v2_val)} subjects")
    print(f"      Test:  {len(v2_test)} subjects (FROZEN)")

    # Identify Disc 4 labeled subjects
    disc4_labeled = [r for r in dataset_rows if "disc4" in r["mri_path"] and r["label"] >= 0]
    disc4_subjects_by_class = {0: [], 1: [], 2: []}
    for r in disc4_labeled:
        disc4_subjects_by_class[r["label"]].append(r["subject_id"])

    # Sort deterministically
    for c in disc4_subjects_by_class:
        disc4_subjects_by_class[c] = sorted(list(set(disc4_subjects_by_class[c])))

    print(f"    Disc 4 Clinically Labeled Subjects:")
    print(f"      Class 0 (Normal, CDR 0.0):       {len(disc4_subjects_by_class[0])} subjects -> {disc4_subjects_by_class[0]}")
    print(f"      Class 1 (Very Mild, CDR 0.5):    {len(disc4_subjects_by_class[1])} subjects -> {disc4_subjects_by_class[1]}")
    print(f"      Class 2 (Dementia, CDR >= 1.0):  {len(disc4_subjects_by_class[2])} subjects -> {disc4_subjects_by_class[2]}")

    # Stratified partition:
    # 12 to TRAIN: 6 Class 0, 4 Class 1, 2 Class 2
    # 3 to VAL:    1 Class 0, 1 Class 1, 1 Class 2
    disc4_train = (
        disc4_subjects_by_class[0][:6] +
        disc4_subjects_by_class[1][:4] +
        disc4_subjects_by_class[2][:2]
    )
    disc4_val = (
        disc4_subjects_by_class[0][6:] +
        disc4_subjects_by_class[1][4:] +
        disc4_subjects_by_class[2][2:]
    )

    print(f"\n    Disc 4 Allocation:")
    print(f"      Added to TRAIN (+{len(disc4_train)}): {sorted(disc4_train)}")
    print(f"      Added to VAL   (+{len(disc4_val)}):   {sorted(disc4_val)}")

    # Combined split lists
    v3_train = sorted(v2_train + disc4_train)
    v3_val = sorted(v2_val + disc4_val)
    v3_test = sorted(v2_test)  # Strictly preserved frozen test set

    split_v3_dir = Path("splits/split_v3_disc1_disc2_disc3_disc4")
    split_v3_dir.mkdir(parents=True, exist_ok=True)

    split_v3_dir.joinpath("train_subjects.txt").write_text("\n".join(v3_train) + "\n", encoding="utf-8")
    split_v3_dir.joinpath("val_subjects.txt").write_text("\n".join(v3_val) + "\n", encoding="utf-8")
    split_v3_dir.joinpath("test_subjects.txt").write_text("\n".join(v3_test) + "\n", encoding="utf-8")

    print(f"    Saved Split v3 to: {split_v3_dir}")
    print(f"      train_subjects.txt: {len(v3_train)} subjects")
    print(f"      val_subjects.txt:   {len(v3_val)} subjects")
    print(f"      test_subjects.txt:  {len(v3_test)} subjects (Strictly Frozen)")

    # ---------------------------------------------------------
    # 3. Incremental Pre-caching of the 15 Disc 4 Labeled Tensors
    # ---------------------------------------------------------
    print(f"\n[3] Incrementally Pre-caching ONLY 15 Disc 4 Clinically Labeled Scans...")
    cache_dir = Path("data/processed")
    cache_dir.mkdir(parents=True, exist_ok=True)

    cached_records = []
    for r in disc4_labeled:
        session_id = r["session_id"]
        sub_id = r["subject_id"]
        label = r["label"]
        label_name = r["label_name"]
        mri_path = r["mri_path"]
        hdr_path = r["hdr_path"]

        # Run existing validated preprocessing
        tensor = preprocess_mri(
            mri_path=mri_path,
            hdr_path=hdr_path,
            target_shape=(96, 96, 96),
            normalize="zscore",
            is_train=False
        )

        prep_file = cache_dir / f"{session_id}_prep.pt"
        torch.save(tensor, prep_file)

        # Also save 96.pt for seamless compatibility with dataset.py
        p96_file = cache_dir / f"{session_id}_96.pt"
        torch.save(tensor, p96_file)

        cached_records.append({
            "session_id": session_id,
            "subject_id": sub_id,
            "label": label,
            "label_name": label_name,
            "prep_file": str(prep_file),
            "tensor": tensor
        })
        print(f"    Cached: {session_id} -> {prep_file.name} | shape={tuple(tensor.shape)}, label={label} ({label_name})")

    # ---------------------------------------------------------
    # 4. Rigorous Tensor Validation
    # ---------------------------------------------------------
    print(f"\n[4] Validating All 15 New Cached Tensors...")
    for item in cached_records:
        t = item["tensor"]
        sess = item["session_id"]
        lbl = item["label"]

        assert tuple(t.shape) == (1, 96, 96, 96), f"Shape mismatch for {sess}: {t.shape}"
        assert t.dtype == torch.float32, f"Dtype mismatch for {sess}: {t.dtype}"
        assert not torch.isnan(t).any(), f"NaN detected in {sess}"
        assert not torch.isinf(t).any(), f"Inf detected in {sess}"
        assert t.std() > 0.1, f"Volume has zero/near-zero variance for {sess}"
        assert t.min() < t.max(), f"Volume is constant for {sess}"
        assert lbl in [0, 1, 2], f"Invalid label for {sess}: {lbl}"

        # Verify reload from disk
        reloaded = torch.load(item["prep_file"], weights_only=True)
        assert torch.equal(t, reloaded), f"Reloaded file does not match memory tensor for {sess}"

    print(f"    [PASS] All 15 tensors successfully validated: shape (1, 96, 96, 96), float32, no NaN/Inf, non-empty.")

    # ---------------------------------------------------------
    # 5. Strict Zero-Leakage and Integrity Verification
    # ---------------------------------------------------------
    print(f"\n[5] Performing Final Leakage and Split Integrity Checks...")
    set_train = set(v3_train)
    set_val = set(v3_val)
    set_test = set(v3_test)

    overlap_tv = set_train.intersection(set_val)
    overlap_tt = set_train.intersection(set_test)
    overlap_vt = set_val.intersection(set_test)

    print(f"    Train intersect Val:  {len(overlap_tv)} {overlap_tv}")
    print(f"    Train intersect Test: {len(overlap_tt)} {overlap_tt}")
    print(f"    Val intersect Test:   {len(overlap_vt)} {overlap_vt}")

    assert len(overlap_tv) == 0, f"Leakage between Train and Val: {overlap_tv}"
    assert len(overlap_tt) == 0, f"Leakage between Train and Test: {overlap_tt}"
    assert len(overlap_vt) == 0, f"Leakage between Val and Test: {overlap_vt}"

    # Frozen test set exact match
    assert set_test == set(v2_test), "Frozen test set was altered!"
    print(f"    [PASS] Frozen test set preserved 100% exactly (10 subjects identical to split_v2).")

    # Disc 4 overlap check with Discs 1-3
    discs123_subjects = set([r["subject_id"] for r in dataset_rows if "disc4" not in r["mri_path"]])
    disc4_subjects = set([r["subject_id"] for r in dataset_rows if "disc4" in r["mri_path"]])
    disc_overlap = discs123_subjects.intersection(disc4_subjects)
    print(f"    Disc 4 intersect Discs 1-3 Subject Overlap: {len(disc_overlap)}")
    assert len(disc_overlap) == 0, f"Overlap between Disc 4 and previous discs: {disc_overlap}"

    # Check no CDR-NaN in supervised splits
    sub_to_label = {r["subject_id"]: r["label"] for r in dataset_rows}
    all_supervised = set_train | set_val | set_test
    nan_in_splits = [s for s in all_supervised if sub_to_label.get(s, -1) < 0]
    print(f"    Unassessed / CDR-NaN subjects in supervised splits: {len(nan_in_splits)}")
    assert len(nan_in_splits) == 0, f"Found unassessed subjects in splits: {nan_in_splits}"

    # ---------------------------------------------------------
    # 6. Checkpoint Safety Verification
    # ---------------------------------------------------------
    print(f"\n[6] Verifying Checkpoint Immutability...")
    with open(ckpt_path, "rb") as f:
        ckpt_sha_after = hashlib.sha256(f.read()).hexdigest()
    ckpt_size_after = ckpt_path.stat().st_size
    ckpt_mtime_after = ckpt_path.stat().st_mtime

    print(f"    SHA-256 before: {ckpt_sha_before}")
    print(f"    SHA-256 after:  {ckpt_sha_after}")
    assert ckpt_sha_before == ckpt_sha_after, "CRITICAL ERROR: models/best_model.pth was modified!"
    assert ckpt_size_before == ckpt_size_after, "CRITICAL ERROR: models/best_model.pth size changed!"
    assert ckpt_mtime_before == ckpt_mtime_after, "CRITICAL ERROR: models/best_model.pth timestamp changed!"
    print(f"    [PASS] models/best_model.pth is 100% untouched and unchanged.")

    # ---------------------------------------------------------
    # 7. Compute Final Split Statistics
    # ---------------------------------------------------------
    print(f"\n[7] Final Split Class Distribution:")
    train_class_counts = {0: 0, 1: 0, 2: 0}
    val_class_counts = {0: 0, 1: 0, 2: 0}
    test_class_counts = {0: 0, 1: 0, 2: 0}

    for s in v3_train:
        train_class_counts[sub_to_label[s]] += 1
    for s in v3_val:
        val_class_counts[sub_to_label[s]] += 1
    for s in v3_test:
        test_class_counts[sub_to_label[s]] += 1

    print(f"    TRAIN (Total: {len(v3_train)} subjects):")
    for c, name in [(0, "Normal"), (1, "Very Mild Dementia"), (2, "Dementia (Mild/Moderate)")]:
        print(f"      Class {c} ({name}): {train_class_counts[c]} ({train_class_counts[c]/len(v3_train)*100:.1f}%)")

    print(f"    VAL (Total: {len(v3_val)} subjects):")
    for c, name in [(0, "Normal"), (1, "Very Mild Dementia"), (2, "Dementia (Mild/Moderate)")]:
        print(f"      Class {c} ({name}): {val_class_counts[c]} ({val_class_counts[c]/len(v3_val)*100:.1f}%)")

    print(f"    TEST (Total: {len(v3_test)} subjects):")
    for c, name in [(0, "Normal"), (1, "Very Mild Dementia"), (2, "Dementia (Mild/Moderate)")]:
        print(f"      Class {c} ({name}): {test_class_counts[c]} ({test_class_counts[c]/len(v3_test)*100:.1f}%)")

    print("\n" + "=" * 70)
    print("PREPARATION PHASE COMPLETED SUCCESSFULLY")
    print("NO TRAINING WAS INITIATED")
    print("=" * 70)


if __name__ == "__main__":
    run_preparation()
