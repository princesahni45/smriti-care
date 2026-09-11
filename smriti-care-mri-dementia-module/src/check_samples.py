"""
Check and demonstrate inference on representative MRI scans (Normal, Very Mild, Dementia).
"""
import os
import sys
import csv

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from src.inference import MRIInferencePipeline


def main():
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

    pipeline = MRIInferencePipeline()

    with open('data/metadata/mri_dataset.csv', 'r', encoding='utf-8') as f:
        rows = list(csv.DictReader(f))

    # Pick one Normal (CDR 0), one Very Mild (CDR 0.5), one Dementia (CDR 1.0)
    samples = {}
    for r in rows:
        cdr = r['cdr']
        if cdr in ['0', '0.5', '1'] and cdr not in samples:
            samples[cdr] = r
        if len(samples) == 3:
            break

    print("=" * 70)
    print("DEMO INFERENCE CHECK ON 3 CLINICAL CASES (OASIS-1):")
    print("=" * 70)

    for cdr, r in samples.items():
        sess = r['session_id']
        mri = r['mri_path']
        hdr = r['hdr_path']
        res = pipeline.predict(mri, hdr_path=hdr, generate_gradcam=True, session_id=sess)
        print(f"\nSession: {sess} | Age: {r['age']} | Sex: {r['gender']} | True CDR: {cdr}")
        print(f"  * Estimated Severity: {res['prediction']}")
        print(f"  * Confidence:         {res['confidence'] * 100:.2f}%")
        print(f"  * Class Breakdown:")
        for cls_name, prob in res['probabilities'].items():
            bar = '#' * int(prob * 30)
            print(f"      - {cls_name:<25}: {prob * 100:5.2f}% |{bar:<30}|")
        print(f"  * Status Note:        {res['clinical_note']}")
        print(f"  * Grad-CAM Image:     {res['gradcam_path']}")
        print("-" * 70)


if __name__ == '__main__':
    main()
