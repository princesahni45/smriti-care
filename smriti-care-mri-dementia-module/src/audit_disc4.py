"""
Inspection and Clinical Label Mapping for OASIS-1 Disc 4.
"""
import os
import sys
import re
import csv
from pathlib import Path

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from src.data_discovery import read_excel_metadata


def main():
    xlsx_path = 'data/metadata/oasis_cross-sectional.xlsx'
    meta = read_excel_metadata(xlsx_path)

    disc4 = Path('data/raw/disc4')
    sessions = sorted([d for d in disc4.iterdir() if d.is_dir() and re.match(r'OAS1_\d{4}_MR\d+', d.name)], key=lambda d: d.name)

    cdr_counts = {'0': 0, '0.5': 0, '>=1': 0, 'missing': 0}
    disc4_records = []

    for s in sessions:
        sid = s.name
        m = re.match(r'(OAS1_\d{4})_MR(\d+)', sid)
        subj_id = m.group(1)

        meta_row = meta.get(sid, {})
        raw_cdr = meta_row.get('CDR', '').strip()

        if raw_cdr == '' or raw_cdr.lower() == 'n/a':
            label = -1
            label_name = 'Unassessed (Young Control)'
            cdr_counts['missing'] += 1
        else:
            cdr_val = float(raw_cdr)
            if cdr_val == 0.0:
                label = 0
                label_name = 'Normal'
                cdr_counts['0'] += 1
            elif cdr_val == 0.5:
                label = 1
                label_name = 'Very Mild Dementia'
                cdr_counts['0.5'] += 1
            elif cdr_val >= 1.0:
                label = 2
                label_name = 'Dementia (Mild/Moderate)'
                cdr_counts['>=1'] += 1
            else:
                label = -1
                label_name = 'Unknown'
                cdr_counts['missing'] += 1

        masked_img = list(s.rglob('*_masked_gfc.img'))[0]
        disc4_records.append({
            'subject_id': subj_id,
            'session_id': sid,
            'mri_path': str(masked_img).replace('\\', '/'),
            'hdr_path': str(masked_img.with_suffix('.hdr')).replace('\\', '/'),
            'age': meta_row.get('Age', ''),
            'gender': meta_row.get('M/F', ''),
            'mmse': meta_row.get('MMSE', ''),
            'cdr': raw_cdr if raw_cdr else 'N/A',
            'label': label,
            'label_name': label_name
        })

    class_names = ["Normal", "Very Mild Dementia", "Dementia (Mild/Moderate)"]
    print("=== DISC 4 CLINICAL LABEL MAPPING REPORT ===")
    print(f"Total Disc 4 sessions mapped: {len(disc4_records)}")
    print(f"  CDR 0 count:        {cdr_counts['0']}")
    print(f"  CDR 0.5 count:      {cdr_counts['0.5']}")
    print(f"  CDR >=1 count:      {cdr_counts['>=1']}")
    print(f"  Missing CDR count:  {cdr_counts['missing']}")

    labeled = [r for r in disc4_records if r['label'] >= 0]
    print(f"\nTotal clinically labeled for 3-class training: {len(labeled)}")
    for l in [0, 1, 2]:
        c = sum(1 for r in labeled if r['label'] == l)
        print(f"  Class {l} ({class_names[l]}): {c}")

    return disc4_records


if __name__ == '__main__':
    main()
