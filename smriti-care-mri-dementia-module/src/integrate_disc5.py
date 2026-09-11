import os
import sys
import csv
import shutil
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


def run_integration():
    print("=" * 80)
    print("OASIS-1 DISC 5 INTEGRATION & PREPARATION PIPELINE")
    print("=" * 80)

    # 1. Verify Checkpoints are Untouched Before Running
    ckpt_best = Path("models/best_model.pth")
    ckpt_d4 = Path("models/best_model_disc4.pth")
    with open(ckpt_best, "rb") as f:
        sha_best_before = hashlib.sha256(f.read()).hexdigest()
    with open(ckpt_d4, "rb") as f:
        sha_d4_before = hashlib.sha256(f.read()).hexdigest()

    assert sha_best_before == "85aa7a5dd60f84f8f276eaacc46bd3a50df7cc8b03c872f5cd22cef19d88bfeb"
    assert sha_d4_before == "7b23efdb1609999478f8b4ad8af1e731aba4d3ec051846520b1ee303e2f04fde"
    print(f"\n[1] Checkpoint Baseline Verified:")
    print(f"  models/best_model.pth:       SHA-256={sha_best_before}")
    print(f"  models/best_model_disc4.pth: SHA-256={sha_d4_before}")

    # 2. Build Combined Manifest for Discs 1-5
    print(f"\n[2] Generating Combined Manifest (Discs 1-5)...")
    excel_path = Path("data/metadata/oasis_cross-sectional.xlsx")
    df_excel = pd.read_excel(excel_path)
    meta_by_id = {str(r["ID"]).strip(): r for _, r in df_excel.iterrows()}

    raw_dir = Path("data/raw")
    session_dirs = sorted([d for d in raw_dir.glob("disc*/*") if d.is_dir()])
    print(f"  Total session directories across all discs (1-5): {len(session_dirs)}")

    dataset_rows = []
    labeled_rows = []
    for s_dir in session_dirs:
        session_id = s_dir.name
        sub_id = session_id.rsplit("_", 1)[0]

        processed_masked = list(s_dir.rglob("*_masked_gfc.img"))
        mri_img = processed_masked[0] if processed_masked else list(s_dir.rglob("*.img"))[0]
        mri_hdr = mri_img.with_suffix(".hdr")

        meta_row = meta_by_id.get(session_id, None)
        raw_cdr = ""
        age, gender, mmse = "", "", ""
        if meta_row is not None:
            val = meta_row.get("CDR")
            if pd.notna(val):
                raw_cdr = str(val).strip()
            age = meta_row.get("Age", "")
            gender = meta_row.get("M/F", "")
            mmse = meta_row.get("MMSE", "")

        if raw_cdr == "" or raw_cdr.lower() in ["n/a", "nan"]:
            label = -1
            label_name = "Unassessed (Young Control)"
            cdr_str = "N/A"
        else:
            cdr_num = float(raw_cdr)
            cdr_str = raw_cdr
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

        row_dict = {
            "subject_id": sub_id,
            "session_id": session_id,
            "mri_path": str(mri_img).replace("\\", "/"),
            "hdr_path": str(mri_hdr).replace("\\", "/"),
            "age": age,
            "gender": gender,
            "mmse": mmse,
            "cdr": cdr_str,
            "label": label,
            "label_name": label_name
        }
        dataset_rows.append(row_dict)
        if label >= 0:
            labeled_rows.append(row_dict)

    print(f"  Total mapped sessions: {len(dataset_rows)}")
    print(f"  Total clinically labeled sessions/subjects: {len(labeled_rows)}")
    assert len(labeled_rows) == 94, f"Expected 94 labeled subjects, got {len(labeled_rows)}"

    # Save manifest v4
    v4_manifest_path = Path("data/metadata/mri_dataset_v4_disc1_disc2_disc3_disc4_disc5.csv")
    fieldnames = ["subject_id", "session_id", "mri_path", "hdr_path", "age", "gender", "mmse", "cdr", "label", "label_name"]
    with open(v4_manifest_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(dataset_rows)
    print(f"  Saved v4 manifest: {v4_manifest_path} ({len(dataset_rows)} rows, 94 labeled)")

    # 3. Stratified Split v4 Generation
    print(f"\n[3] Generating Subject-Level Split v4...")
    split_v3_dir = Path("splits/split_v3_disc1_disc2_disc3_disc4")
    v3_train = split_v3_dir.joinpath("train_subjects.txt").read_text(encoding="utf-8").strip().splitlines()
    v3_val = split_v3_dir.joinpath("val_subjects.txt").read_text(encoding="utf-8").strip().splitlines()
    v3_test = split_v3_dir.joinpath("test_subjects.txt").read_text(encoding="utf-8").strip().splitlines()

    print(f"  Split v3 Baseline:")
    print(f"    Train: {len(v3_train)} | Val: {len(v3_val)} | Test: {len(v3_test)} (Total: 76)")

    # The 18 Disc 5 labeled subjects
    disc5_labeled = [r for r in labeled_rows if "disc5" in r["mri_path"]]
    print(f"  Disc 5 Labeled Subjects: {len(disc5_labeled)}")
    assert len(disc5_labeled) == 18

    disc5_by_class = {0: [], 1: [], 2: []}
    for r in disc5_labeled:
        disc5_by_class[r["label"]].append(r["subject_id"])
    for c in disc5_by_class:
        disc5_by_class[c] = sorted(list(set(disc5_by_class[c])))

    print(f"    Class 0 (Normal):       {len(disc5_by_class[0])} subjects -> {disc5_by_class[0]}")
    print(f"    Class 1 (Very Mild):    {len(disc5_by_class[1])} subjects -> {disc5_by_class[1]}")
    print(f"    Class 2 (Dementia):     {len(disc5_by_class[2])} subjects -> {disc5_by_class[2]}")

    # Stratified allocation:
    # 14 to Train: 8 Class 0, 5 Class 1, 1 Class 2
    # 4 to Val:    2 Class 0, 1 Class 1, 1 Class 2
    disc5_train = disc5_by_class[0][:8] + disc5_by_class[1][:5] + disc5_by_class[2][:1]
    disc5_val = disc5_by_class[0][8:] + disc5_by_class[1][5:] + disc5_by_class[2][1:]

    v4_train = sorted(v3_train + disc5_train)
    v4_val = sorted(v3_val + disc5_val)
    v4_test = sorted(v3_test)  # Frozen 10 subjects

    print(f"\n  Split v4 Allocation:")
    print(f"    Train:      {len(v4_train)} subjects (54 previous + 14 from Disc 5)")
    print(f"    Validation: {len(v4_val)} subjects (12 previous + 4 from Disc 5)")
    print(f"    Test:       {len(v4_test)} subjects (10 FROZEN benchmark)")
    assert len(v4_train) == 68
    assert len(v4_val) == 16
    assert len(v4_test) == 10
    assert len(v4_train) + len(v4_val) + len(v4_test) == 94

    split_v4_dir = Path("splits/split_v4_disc1_disc2_disc3_disc4_disc5")
    split_v4_dir.mkdir(parents=True, exist_ok=True)
    split_v4_dir.joinpath("train_subjects.txt").write_text("\n".join(v4_train) + "\n", encoding="utf-8")
    split_v4_dir.joinpath("val_subjects.txt").write_text("\n".join(v4_val) + "\n", encoding="utf-8")
    split_v4_dir.joinpath("test_subjects.txt").write_text("\n".join(v4_test) + "\n", encoding="utf-8")
    print(f"  Saved Split v4 to: {split_v4_dir}")

    # 4. Data Leakage Verification
    print(f"\n[4] Zero-Leakage & Disjoint Sets Verification...")
    s_tr, s_va, s_te = set(v4_train), set(v4_val), set(v4_test)
    assert len(s_tr.intersection(s_va)) == 0, "Leakage Train & Val!"
    assert len(s_tr.intersection(s_te)) == 0, "Leakage Train & Test!"
    assert len(s_va.intersection(s_te)) == 0, "Leakage Val & Test!"
    assert s_te == set(v3_test), "Frozen test set was modified!"
    print(f"  Train intersect Val:  {len(s_tr.intersection(s_va))} set()")
    print(f"  Train intersect Test: {len(s_tr.intersection(s_te))} set()")
    print(f"  Val intersect Test:   {len(s_va.intersection(s_te))} set()")
    print(f"  [PASS] Zero data leakage verified.")

    # 5. Pre-caching All 18 Disc 5 Tensors
    print(f"\n[5] Pre-caching ONLY the 18 Clinically Labeled Disc 5 Tensors...")
    cache_dir = Path("data/processed")
    cache_dir.mkdir(parents=True, exist_ok=True)

    precached_items = []
    for idx, r in enumerate(disc5_labeled, 1):
        sess = r["session_id"]
        sub = r["subject_id"]
        lbl = r["label"]
        lbl_name = r["label_name"]
        mri_path = r["mri_path"]
        hdr_path = r["hdr_path"]

        tensor = preprocess_mri(
            mri_path=mri_path,
            hdr_path=hdr_path,
            target_shape=(96, 96, 96),
            normalize="zscore",
            is_train=False
        )

        p_prep = cache_dir / f"{sess}_prep.pt"
        p_96 = cache_dir / f"{sess}_96.pt"
        torch.save(tensor, p_prep)
        torch.save(tensor, p_96)

        # Validation
        assert tuple(tensor.shape) == (1, 96, 96, 96), f"Shape invalid for {sess}: {tensor.shape}"
        assert tensor.dtype == torch.float32, f"Dtype invalid for {sess}: {tensor.dtype}"
        assert not torch.isnan(tensor).any(), f"NaN detected for {sess}"
        assert not torch.isinf(tensor).any(), f"Inf detected for {sess}"

        precached_items.append((sub, sess, lbl, lbl_name, p_prep))
        print(f"  [{idx:2d}/18] Cached & Validated: {sess} ({sub}) | label={lbl} ({lbl_name}) -> {p_prep.name}")

    print(f"  [PASS] All 18 Disc 5 scans successfully pre-cached and validated.")

    # 6. Final Checkpoint Verification
    print(f"\n[6] Final Checkpoint Immutability Verification...")
    with open(ckpt_best, "rb") as f:
        sha_best_after = hashlib.sha256(f.read()).hexdigest()
    with open(ckpt_d4, "rb") as f:
        sha_d4_after = hashlib.sha256(f.read()).hexdigest()

    assert sha_best_before == sha_best_after, "CRITICAL: models/best_model.pth was altered!"
    assert sha_d4_before == sha_d4_after, "CRITICAL: models/best_model_disc4.pth was altered!"
    print(f"  models/best_model.pth:       SHA-256={sha_best_after} (100% UNTOUCHED)")
    print(f"  models/best_model_disc4.pth: SHA-256={sha_d4_after} (100% UNTOUCHED)")

    # 7. Class Distribution Computations
    sub_to_lbl = {r["subject_id"]: r["label"] for r in labeled_rows}
    c_tr = {0: 0, 1: 0, 2: 0}
    c_va = {0: 0, 1: 0, 2: 0}
    c_te = {0: 0, 1: 0, 2: 0}
    for s in v4_train:
        c_tr[sub_to_lbl[s]] += 1
    for s in v4_val:
        c_va[sub_to_lbl[s]] += 1
    for s in v4_test:
        c_te[sub_to_lbl[s]] += 1

    print("\n" + "=" * 80)
    print("INTEGRATION COMPLETE")
    print("=" * 80)
    print(f"Total Labeled Subjects: 94")
    print(f"  Class 0 (Normal):             {c_tr[0] + c_va[0] + c_te[0]}")
    print(f"  Class 1 (Very Mild Dementia): {c_tr[1] + c_va[1] + c_te[1]}")
    print(f"  Class 2 (Dementia):           {c_tr[2] + c_va[2] + c_te[2]}")
    print(f"Train (68): Class 0={c_tr[0]}, Class 1={c_tr[1]}, Class 2={c_tr[2]}")
    print(f"Val   (16): Class 0={c_va[0]}, Class 1={c_va[1]}, Class 2={c_va[2]}")
    print(f"Test  (10): Class 0={c_te[0]}, Class 1={c_te[1]}, Class 2={c_te[2]}")


if __name__ == "__main__":
    run_integration()
