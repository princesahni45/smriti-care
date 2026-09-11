"""
Data Discovery and Metadata Mapping for OASIS-1 MRI Dataset.
Discovers .img / .hdr scans, validates paired Analyze files,
maps each scan to clinical metadata, applies 3-class CDR rules,
and writes data/metadata/mri_dataset.csv.
"""

import os
import re
import csv
import struct
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path


def parse_cell_ref(ref):
    """Parse Excel cell coordinate (e.g. 'B4') to (row_idx_1based, col_idx_0based)."""
    match = re.match(r'([A-Z]+)(\d+)', ref)
    col_str, row_str = match.groups()
    col = 0
    for ch in col_str:
        col = col * 26 + (ord(ch) - ord('A') + 1)
    return int(row_str), col - 1


def read_excel_metadata(xlsx_path):
    """Read OASIS cross-sectional xlsx metadata using standard library xml parser."""
    with zipfile.ZipFile(xlsx_path) as z:
        shared_strings = []
        if 'xl/sharedStrings.xml' in z.namelist():
            tree = ET.fromstring(z.read('xl/sharedStrings.xml'))
            for si in tree.findall('{http://schemas.openxmlformats.org/spreadsheetml/2006/main}si'):
                t = si.find('{http://schemas.openxmlformats.org/spreadsheetml/2006/main}t')
                shared_strings.append(t.text if t is not None else '')
        
        sheet = ET.fromstring(z.read('xl/worksheets/sheet1.xml'))
        data = {}
        max_col, max_row = 0, 0
        for row in sheet.findall('.//{http://schemas.openxmlformats.org/spreadsheetml/2006/main}row'):
            for c in row.findall('{http://schemas.openxmlformats.org/spreadsheetml/2006/main}c'):
                r_idx, c_idx = parse_cell_ref(c.attrib['r'])
                max_col, max_row = max(max_col, c_idx), max(max_row, r_idx)
                t_attr = c.attrib.get('t')
                v = c.find('{http://schemas.openxmlformats.org/spreadsheetml/2006/main}v')
                val = v.text if v is not None else ''
                if t_attr == 's' and val:
                    val = shared_strings[int(val)]
                data[(r_idx, c_idx)] = val
                
        grid = []
        for r in range(1, max_row + 1):
            row_vals = [data.get((r, c), '').strip() for c in range(max_col + 1)]
            grid.append(row_vals)
            
    header = grid[0]
    records = {}
    for row in grid[1:]:
        if not row or not row[0]:
            continue
        record = {header[i]: row[i] if i < len(row) else '' for i in range(len(header))}
        records[row[0]] = record
    return records


def read_analyze_header_info(hdr_path):
    """Read basic metadata from Analyze 7.5 .hdr file."""
    with open(hdr_path, 'rb') as f:
        raw = f.read(348)
    sizeof_hdr = struct.unpack('<I', raw[:4])[0]
    endian = '<' if sizeof_hdr == 348 else '>'
    dim = struct.unpack(endian + '8h', raw[40:56])
    pixdim = struct.unpack(endian + '8f', raw[76:108])
    return {
        'ndim': dim[0],
        'shape': (dim[1], dim[2], dim[3]),
        'pixdim': (pixdim[1], pixdim[2], pixdim[3]),
        'endian': endian
    }


def discover_dataset(raw_dir="data/raw", metadata_path="data/metadata/oasis_cross-sectional.xlsx", output_csv="data/metadata/mri_dataset.csv"):
    """
    Scans raw directory (including disc1, disc2, etc.) for MRI files,
    matches with clinical metadata, flags unmatched cases,
    and produces mri_dataset.csv.
    """
    import sys
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass
    print("=" * 60)
    print("[DATA DISCOVERY] OASIS-1 MULTI-DISC DISCOVERY & VALIDATION")
    print("=" * 60)

    if not os.path.exists(raw_dir):
        raise FileNotFoundError(f"Raw directory not found: {raw_dir}")
    if not os.path.exists(metadata_path):
        raise FileNotFoundError(f"Metadata file not found: {metadata_path}")

    # Read clinical metadata
    meta = read_excel_metadata(metadata_path)
    print(f"Loaded clinical metadata: {len(meta)} total patient records in Excel.")

    # Locate sessions across all disc subdirectories
    raw_path = Path(raw_dir)
    session_dirs = []
    for item in sorted(raw_path.iterdir()):
        if item.is_dir() and item.name.startswith("disc"):
            disc_sessions = [d for d in item.iterdir() if d.is_dir() and re.match(r'OAS1_\d{4}_MR\d+', d.name)]
            session_dirs.extend(disc_sessions)
        elif item.is_dir() and re.match(r'OAS1_\d{4}_MR\d+', item.name):
            session_dirs.append(item)

    session_dirs = sorted(session_dirs, key=lambda d: d.name)
    print(f"Found {len(session_dirs)} session folders across discs in {raw_dir}.")

    all_img_files = list(raw_path.rglob("*.img"))
    all_hdr_files = list(raw_path.rglob("*.hdr"))
    print(f"Total .img files found: {len(all_img_files)}")
    print(f"Total .hdr files found: {len(all_hdr_files)}")

    dataset_rows = []
    unassessed_count = 0
    cdr_counts = {}
    sample_hdr_info = None
    unmatched_mri_sessions = []

    for s_dir in session_dirs:
        session_id = s_dir.name
        # Subject ID is e.g. OAS1_0001
        m = re.match(r'(OAS1_\d{4})_MR(\d+)', session_id)
        if not m:
            continue
        subject_id = m.group(1)

        # Look for the atlas-registered skull-stripped scan first
        processed_masked = list(s_dir.rglob("*_masked_gfc.img"))
        if processed_masked:
            mri_img = processed_masked[0]
        else:
            # Fallback to any processed or raw scan
            raw_imgs = list(s_dir.rglob("*.img"))
            if not raw_imgs:
                print(f"[WARN] No .img found for session {session_id}")
                continue
            mri_img = raw_imgs[0]

        mri_hdr = mri_img.with_suffix('.hdr')
        if not mri_hdr.exists():
            print(f"[WARN] Header missing for {mri_img}")
            continue

        if sample_hdr_info is None:
            sample_hdr_info = read_analyze_header_info(str(mri_hdr))

        # Check metadata
        meta_row = meta.get(session_id, {})
        raw_cdr = meta_row.get('CDR', '').strip()

        if raw_cdr == '' or raw_cdr.lower() == 'n/a':
            # Young control (unassessed CDR in OASIS clinical protocol)
            unassessed_count += 1
            label = -1
            label_name = "Unassessed (Young Control)"
            cdr_val = None
        else:
            cdr_val = float(raw_cdr)
            cdr_counts[cdr_val] = cdr_counts.get(cdr_val, 0) + 1
            if cdr_val == 0.0:
                label = 0
                label_name = "Normal"
            elif cdr_val == 0.5:
                label = 1
                label_name = "Very Mild Dementia"
            elif cdr_val >= 1.0:
                label = 2
                label_name = "Dementia (Mild/Moderate)"
            else:
                label = -1
                label_name = "Unknown"

        dataset_rows.append({
            'subject_id': subject_id,
            'session_id': session_id,
            'mri_path': str(mri_img).replace('\\', '/'),
            'hdr_path': str(mri_hdr).replace('\\', '/'),
            'age': meta_row.get('Age', ''),
            'gender': meta_row.get('M/F', ''),
            'mmse': meta_row.get('MMSE', ''),
            'cdr': raw_cdr if raw_cdr else 'N/A',
            'label': label,
            'label_name': label_name
        })

    # Save to CSV
    os.makedirs(os.path.dirname(output_csv), exist_ok=True)
    fieldnames = ['subject_id', 'session_id', 'mri_path', 'hdr_path', 'age', 'gender', 'mmse', 'cdr', 'label', 'label_name']
    with open(output_csv, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(dataset_rows)

    print(f"\nGenerated: {output_csv} with {len(dataset_rows)} mapped entries.")
    if sample_hdr_info:
        print(f"Sample Dimensions: {sample_hdr_info['shape']} voxels")
        print(f"Sample Voxel Spacing: {sample_hdr_info['pixdim']} mm")
    print(f"Clinical CDR Distribution (All Discs):")
    for c, cnt in sorted(cdr_counts.items()):
        print(f"  CDR = {c}: {cnt} subjects")
    print(f"  Unassessed (Young adult normal controls): {unassessed_count} subjects")

    labeled_rows = [r for r in dataset_rows if r['label'] >= 0]
    print(f"\nTotal clinically labeled subjects for 3-class training: {len(labeled_rows)}")
    for l_id, l_name in [(0, "Normal"), (1, "Very Mild Dementia"), (2, "Dementia (Mild/Moderate)")]:
        cnt = sum(1 for r in labeled_rows if r['label'] == l_id)
        print(f"  Class {l_id} ({l_name}): {cnt} samples ({cnt / len(labeled_rows) * 100:.1f}%)")
    print("=" * 60)
    return dataset_rows


if __name__ == "__main__":
    discover_dataset()
