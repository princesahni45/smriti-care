# Shareable Setup Guide: AI-Assisted Brain MRI Dementia Severity Estimation

Welcome to the **Smriti Care AI-Assisted Brain MRI Dementia Severity Estimation Module**!
This standalone package provides the complete source code, trained deep learning checkpoint, preprocessing pipeline, FastAPI inference backend, test suite, and Flutter frontend integration.

---

## 1. Project Overview & Capabilities
- **Task**: 3D Volumetric Brain MRI Dementia Severity Estimation.
- **Input Modalities**: T1-weighted structural brain MRI scans in **NIfTI** (`.nii`, `.nii.gz`) or **Analyze 7.5** (`.img` + `.hdr`) format.
- **Deep Architecture**: 3D ResNet-10 (`resnet10_3d`) operating on `(1, 96, 96, 96)` volumetric inputs.
- **Preprocessing Pipeline**:
  1. *Orientation Standardization*: Spatial affine reorientation to canonical `('L', 'A', 'S')` reference coordinates.
  2. *Brain Extraction*: Conditional skull-stripping with atlas brain mask template fallback.
  3. *Bounding Box Cropping*: Eliminates empty background voxels.
  4. *Resampling*: Spline interpolation resizing to standardized shape `(96, 96, 96)`.
  5. *Intensity Normalization*: Z-score standardization `(voxel - mean) / std` over brain tissue.
- **Explainability**: 3D Grad-CAM saliency heatmaps highlighting Axial, Coronal, and Sagittal regions influencing network decisions.
- **Active Model Checkpoint**: `models/best_model_disc5.pth` (OASIS-1 Discs 1–5 supervised continuation training, 94 labeled subjects).

---

## 2. Standard Clinical Class Mapping
The model predicts three clinical severity tiers corresponding to Clinical Dementia Rating (CDR) scores:
- **Class 0 — Normal** (CDR 0.0)
- **Class 1 — Very Mild Dementia** (CDR 0.5)
- **Class 2 — Dementia (Mild/Moderate)** (CDR >= 1.0)

> **Notice**: The model uses MRI imaging data only. Clinical variables (Age, MMSE, CDR, SES, eTIV) are strictly excluded from inference inputs.

---

## 3. Environment & Dependency Installation

### Requirements
- Python 3.10 or 3.11
- PyTorch 2.0+
- Nibabel 5.0+
- FastAPI & Uvicorn

### Installation Steps
```bash
# 1. Create a virtual environment
python -m venv .venv

# 2. Activate virtual environment
# Windows:
.venv\Scripts\activate
# macOS / Linux:
source .venv/bin/activate

# 3. Install dependencies
pip install -r requirements.txt
```

---

## 4. How to Start the FastAPI Inference Server

You can run the API from the root folder or from `backend/`:

```bash
# From project root:
uvicorn api.main:app --host 127.0.0.1 --port 8000 --reload

# Or from backend/ directory:
cd backend
uvicorn main:app --host 127.0.0.1 --port 8000 --reload
```

Once running:
- **API Documentation (Swagger)**: `http://127.0.0.1:8000/docs`
- **Health Check Endpoint**: `http://127.0.0.1:8000/health`
- **Model Info & Metrics**: `http://127.0.0.1:8000/model-info`
- **Prediction Endpoint**: `POST http://127.0.0.1:8000/predict`
- **Attention Visualizations**: `GET http://127.0.0.1:8000/static/gradcam/{filename}`

### Example cURL Request:
```bash
curl -X POST "http://127.0.0.1:8000/predict?generate_gradcam=true" \
  -H "accept: application/json" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@your_scan.nii.gz"
```

---

## 5. How to Run the Tests

```bash
# Run automated API endpoint & error handling tests:
python -m unittest tests/test_api.py

# Run OASIS regression suite (evaluates against local validation scans):
python tests/test_regression.py
```

---

## 6. Directory Structure
```text
smriti-care-mri-dementia-module/
  ├── SHARE_SETUP.md          <-- Setup instructions and reference
  ├── README.md               <-- Main project documentation
  ├── config.yaml             <-- Pipeline configuration
  ├── requirements.txt        <-- Python dependencies
  ├── src/                    <-- Preprocessing, inference, Grad-CAM, training modules
  ├── api/                    <-- FastAPI inference application
  ├── models/                 <-- ACTIVE checkpoint (best_model_disc5.pth) & mask
  ├── tests/                  <-- API and regression test suites
  ├── backend/                <-- Standalone backend service package
  ├── frontend_flutter/       <-- Flutter UI screens, services, and models
  └── reports/                <-- Benchmark curves, metrics, and audit summaries
```

---

## 7. Notice Regarding OASIS Raw MRI Datasets
**Raw OASIS MRI datasets (.img/.hdr pairs, .nii archives, disc tar.gz archives, and cached tensors under data/) are intentionally NOT included in this archive.**
This ensures lightweight distribution, compliance with data sharing agreements, and patient privacy.
To test the pipeline:
- You can upload any valid 3D T1-weighted brain MRI scan in NIfTI format (`.nii` or `.nii.gz`).
- You can obtain the open-access OASIS-1 dataset from [oasis-brains.org](https://www.oasis-brains.org/).

---

## 8. Mandatory Medical Disclaimer
> **This system provides AI-assisted estimation based on MRI patterns for research and educational purposes only. It is not a medical diagnosis and must not replace clinical assessment, cognitive testing, or radiological evaluation by a qualified healthcare professional.**
