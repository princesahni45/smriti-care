"""
Formal Verification Script for NIfTI Preprocessing Fix.
Evaluates:
- OAS1_0001_MR1_t1.nii.gz (CDR 0.0 -> Normal)
- OAS1_0003_MR1_t1.nii.gz (CDR 0.5 -> Very Mild Dementia)
- OAS1_0031_MR1_t1.nii.gz (CDR 1.0 -> Dementia (Mild/Moderate))
And tests regression on:
- OAS1_0001_MR1_mpr_n4_anon_111_t88_masked_gfc.img (Analyze 7.5)
"""
import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from src.inference import MRIInferencePipeline


def main():
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

    pipeline = MRIInferencePipeline()

    samples = [
        ('OAS1_0001_MR1_t1.nii.gz', '0.0', 'Normal'),
        ('OAS1_0003_MR1_t1.nii.gz', '0.5', 'Very Mild Dementia'),
        ('OAS1_0031_MR1_t1.nii.gz', '1.0', 'Dementia (Mild/Moderate)')
    ]

    print("=" * 70)
    print("VERIFICATION OF PREPROCESSING FIX ON 3 KNOWN NIFTI VALIDATION SAMPLES")
    print("=" * 70)

    results = []
    for fname, cdr, expected in samples:
        path = f"C:/Users/LENOVO/Downloads/{fname}"
        print(f"\nEvaluating: {fname} (CDR: {cdr} | Expected: {expected})")
        print("-" * 70)
        res = pipeline.predict(path, generate_gradcam=True, session_id=fname.replace('.nii.gz', ''), debug=True)
        pred = res['prediction']
        conf = res['confidence']
        probs = res['probabilities']
        matched = (pred == expected)
        results.append((fname, cdr, expected, pred, conf, probs, matched))
        print(f"  --> Prediction:     {pred} (Confidence: {conf*100:.2f}%)")
        print(f"  --> Probabilities:  {probs}")
        print(f"  --> Ground Truth:   {expected} -> {'MATCH (CORRECT)' if matched else 'MISMATCH'}")
        print(f"  --> Grad-CAM Path:  {res.get('gradcam_path')}")

    print("\n" + "=" * 70)
    print("REGRESSION CHECK: TESTING NATIVE OASIS ANALYZE TRAINING FILE")
    print("=" * 70)
    analyze_path = "data/raw/disc1/OAS1_0001_MR1/PROCESSED/MPRAGE/T88_111/OAS1_0001_MR1_mpr_n4_anon_111_t88_masked_gfc.img"
    res_ana = pipeline.predict(analyze_path, debug=True)
    print(f"Native Analyze Prediction: {res_ana['prediction']} (Confidence: {res_ana['confidence']*100:.2f}%)")
    print(f"Native Analyze Probs:      {res_ana['probabilities']}")

    print("\n" + "=" * 70)
    print("SUMMARY OF ALL 3 VALIDATION SAMPLES:")
    print("=" * 70)
    for fname, cdr, expected, pred, conf, probs, matched in results:
        status_sym = "[OK] CORRECT" if matched else "[FAIL] MISMATCH"
        print(f"  * {fname:<25} | True CDR: {cdr:<4} | Expected: {expected:<24} | Pred: {pred:<24} | Conf: {conf*100:5.2f}% | {status_sym}")

    all_correct = all(r[6] for r in results)
    print(f"\nALL 3 PREDICTIONS CORRECT: {'YES' if all_correct else 'NO'}")
    print("=" * 70)


if __name__ == '__main__':
    main()
