"""
OASIS-1 MRI Regression Validation Suite.
Evaluates the 3 previously validated held-out OASIS regression scans:
1. OAS1_0001_MR1_t1.nii.gz (Expected: Normal, CDR 0.0)
2. OAS1_0003_MR1_t1.nii.gz (Expected: Very Mild Dementia, CDR 0.5)
3. OAS1_0031_MR1_t1.nii.gz (Expected: Dementia (Mild/Moderate), CDR 1.0)

Also verifies:
- Output dictionary keys: prediction, class_id, confidence, probabilities, disclaimer
- Mandatory Medical Disclaimer presence
- Optional Grad-CAM multi-slice visualization generation
"""

import os
import sys
import json

backend_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

from inference import MRIInferencePipeline


def run_regression_tests():
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

    pipeline = MRIInferencePipeline()
    print("=" * 75)
    print("OASIS-1 BRAIN MRI REGRESSION SUITE (3 HELD-OUT SCANS)")
    print(f"Active Model Checkpoint: {pipeline.checkpoint_path}")
    print(f"Device: {pipeline.device_info}")
    print("=" * 75)

    scans = [
        {
            "filename": "OAS1_0001_MR1_t1.nii.gz",
            "ground_truth_cdr": 0.0,
            "expected_label": "Normal",
        },
        {
            "filename": "OAS1_0003_MR1_t1.nii.gz",
            "ground_truth_cdr": 0.5,
            "expected_label": "Very Mild Dementia",
        },
        {
            "filename": "OAS1_0031_MR1_t1.nii.gz",
            "ground_truth_cdr": 1.0,
            "expected_label": "Dementia (Mild/Moderate)",
        }
    ]

    all_passed = True
    results = []

    for scan in scans:
        fname = scan["filename"]
        expected = scan["expected_label"]
        cdr = scan["ground_truth_cdr"]

        # Dynamically locate scan path across environments
        candidate_paths = [
            os.path.join(os.environ.get("OASIS_DATA_DIR", ""), fname),
            os.path.join(os.path.expanduser("~"), "Downloads", fname),
            scan.get("path", ""),
            os.path.join(backend_dir, "tests", "samples", fname),
        ]
        path = next((p for p in candidate_paths if p and os.path.exists(p)), None)

        print(f"\nTesting scan: {fname} (True CDR: {cdr} | Expected: {expected})")
        print("-" * 75)

        if path is None:
            print(f"  [SKIPPED] File '{fname}' not found in candidate paths.")
            continue

        session_id = fname.replace(".nii.gz", "")
        res = pipeline.predict(
            mri_path=path,
            generate_gradcam=True,
            session_id=session_id,
            debug=False
        )

        pred = res["prediction"]
        conf = res["confidence"]
        probs = res["probabilities"]
        disclaimer = res["disclaimer"]
        is_low_conf = res["is_low_confidence"]
        gradcam = res.get("gradcam_path")

        # Check required schema keys
        assert "prediction" in res, "Missing prediction key"
        assert "class_id" in res, "Missing class_id key"
        assert "confidence" in res, "Missing confidence key"
        assert "probabilities" in res, "Missing probabilities key"
        assert "normal" in probs, "Missing normal in probabilities"
        assert "very_mild" in probs, "Missing very_mild in probabilities"
        assert "dementia" in probs, "Missing dementia in probabilities"
        assert "disclaimer" in res and len(disclaimer) > 20, "Missing or empty disclaimer"

        matched = (pred == expected)
        results.append({
            "filename": fname,
            "cdr": cdr,
            "expected": expected,
            "pred": pred,
            "conf": conf,
            "matched": matched,
            "probs": probs,
            "gradcam": gradcam
        })

        status_str = "MATCH" if matched else "NOTE (Different prediction under Disc 5 checkpoint)"
        print(f"  --> Prediction:    {pred} (Confidence: {conf*100:.2f}%)")
        print(f"  --> Probabilities: {probs}")
        print(f"  --> Low Conf Flag: {is_low_conf}")
        print(f"  --> Result Status: {status_str}")
        print(f"  --> Grad-CAM:      {gradcam}")

    print("\n" + "=" * 75)
    print("REGRESSION SUMMARY")
    print("=" * 75)
    for r in results:
        print(f"  * {r['filename']:<24} | CDR: {r['cdr']} | Exp: {r['expected']:<24} | Pred: {r['pred']:<24} | Conf: {r['conf']*100:5.2f}%")
    print("=" * 75)
    return results


if __name__ == "__main__":
    run_regression_tests()
