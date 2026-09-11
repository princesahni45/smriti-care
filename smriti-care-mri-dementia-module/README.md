# AI-Assisted Brain MRI Dementia Severity Estimation

### *A Research & Educational Volumetric 3D Deep Learning Module for Structural MRI*

> **Mandatory Medical Disclaimer:**  
> This system provides **AI-assisted estimation based on MRI patterns for research and educational purposes only**. It is **not** a medical diagnosis and must never replace clinical assessment, cognitive testing, or radiological evaluation by a qualified healthcare professional. Guaranteed detection, diagnosis, or 100% accuracy is neither claimed nor possible.

---

## 1. Project Overview

This project provides an end-to-end medical deep learning module that estimates dementia severity directly from 3D brain MRI scans using the authentic **OASIS-1 (Open Access Series of Imaging Studies)** cross-sectional dataset.

Rather than slicing 3D volumes into arbitrary 2D pictures, this module treats brain MRI as true volumetric data:
- **Input:** 3D MRI volume (Analyze 7.5 `.img` + `.hdr` pairs, `.nii`, or `.nii.gz`).
- **Target:** 3-Class Dementia Severity derived from the Clinical Dementia Rating (CDR):
  - **Class 0:** Normal / Nondemented ($\text{CDR} = 0$)
  - **Class 1:** Very Mild Dementia ($\text{CDR} = 0.5$)
  - **Class 2:** Dementia (Mild / Moderate, $\text{CDR} \ge 1$)
- **Core Architecture:** Volumetric 3D ResNet (`resnet10_3d` / `resnet18_3d`) with mixed-precision acceleration.
- **Explainability:** 3D Gradient-weighted Class Activation Mapping (**3D Grad-CAM**) with multi-planar slice overlays (Sagittal, Coronal, Axial).
- **Service & UI:** FastAPI backend service and direct integration into the **MindCare NER** cognitive care platform.

---

## 2. OASIS-1 Dataset & Local Data Structure

The dataset utilizes the OASIS-1 Cross-Sectional MRI collection ($N = 436$ sessions across 416 subjects):
- **MRI Format:** Analyze 7.5 big-endian paired format (`.img` raw voxel data + `.hdr` 348-byte header).
- **Dimensions:** $176 \times 208 \times 176$ voxels.
- **Voxel Resolution:** $1.0 \times 1.0 \times 1.0\text{ mm}$ isotropic in Talairach-88 stereotaxic space (`T88_111`).
- **Brain Masking:** Utilizes pre-registered, skull-stripped volumes (`_masked_gfc.img/.hdr`), isolating brain parenchyma and eliminating non-brain skull/scalp artifacts.
- **Metadata Columns:** `ID, M/F, Hand, Age, Educ, SES, MMSE, CDR, eTIV, nWBV, ASF, Delay`.

### Critical Clinical Ground-Truth Rules
1. `CDR` is strictly the **target variable** and is never provided as an input feature to the model.
2. Metadata variables (`MMSE`, `Age`, `eTIV`, `nWBV`, etc.) are excluded from the primary model input to ensure the network learns severity representations strictly from anatomical MRI patterns.
3. Young adult control subjects (aged 18–43) were not clinically administered the CDR assessment (recorded as blank/unassessed in OASIS documentation). To preserve strict label truth, unassessed subjects are audited and excluded from supervised loss calculation.

---

## 3. Repository & Directory Architecture

```
mri_dementia/
├── data/
│   ├── raw/
│   │   └── disc1/               # Extracted OASIS-1 session folders
│   ├── processed/               # Preprocessed 3D volume cache
│   └── metadata/
│       ├── oasis_cross-sectional.xlsx
│       ├── oasis_cross-sectional-reliability.xlsx
│       └── mri_dataset.csv      # Mapped subject dataset index
├── models/
│   ├── resnet3d.py              # 3D ResNet architectures (ResNet-10, ResNet-18)
│   ├── densenet3d.py            # 3D DenseNet volumetric architecture
│   ├── best_model.pth           # Trained PyTorch model checkpoint
│   ├── model_config.json        # Architecture & normalization metadata
│   └── class_mapping.json       # Target class ID to clinical label mapping
├── src/
│   ├── utils.py                 # Seeds, device detection, disclaimers, config loader
│   ├── preprocessing.py         # 3D loading, cropping, 96x96x96 resampling, z-score norm
│   ├── dataset.py               # Subject-level stratified splitting, class weights, loader
│   ├── data_discovery.py        # Archive scanner, metadata parser, dataset report generator
│   ├── data_validation.py       # Data integrity, dimension, and zero-leakage verifier
│   ├── safety_checks.py         # 5-step pre-training verification sequence
│   ├── train.py                 # Training loop, AMP, early stopping, LR scheduler, plots
│   ├── evaluate.py              # Test evaluation (Accuracy, F1, Recall, Spec, ROC-AUC)
│   ├── inference.py             # Inference pipeline & low-confidence warning logic
│   └── explainability.py        # 3D Grad-CAM saliency extraction & visualization
├── api/
│   └── main.py                  # FastAPI REST endpoints (/predict, /health, /model-info)
├── reports/
│   ├── sample_slices.png        # Multi-planar slice visualization of preprocessed scans
│   ├── training_curve.png       # Loss and Macro-F1 training curves
│   ├── confusion_matrix.png     # Multi-class confusion matrix
│   ├── metrics.json             # Full numerical evaluation report
│   ├── test_predictions.csv     # Individual test subject predictions and probabilities
│   └── gradcam/                 # Generated 3D Grad-CAM saliency slice plots
├── config.yaml                  # Central configuration file
├── requirements.txt             # Python dependencies
└── README.md                    # Project documentation
```

---

## 4. Preventing Data Leakage (Strict Subject-Level Splitting)

A common failure mode in medical imaging AI is slice- or session-level random splitting, which leaks patient anatomy between training and evaluation splits.

This pipeline enforces:
- **Unit of Partitioning:** **Subject ID** (`OAS1_xxxx`), not scan or slice.
- **Split Ratio:** 70% Train, 15% Validation, 15% Test.
- **Stratification:** Stratified across clinical CDR classes.
- **Audit:** `verify_split_leakage()` computes set intersections across splits:
  $$\text{Train} \cap \text{Val} = \emptyset, \quad \text{Train} \cap \text{Test} = \emptyset, \quad \text{Val} \cap \text{Test} = \emptyset$$

---

## 5. Volumetric 3D Preprocessing Pipeline

1. **Volume Loading:** Native Analyze 7.5 reading via `nibabel` with fallback binary struct parser.
2. **Brain Bounding-Box Extraction:** Identifies non-zero tissue coordinates and crops peripheral zero-padding.
3. **Standardized Resampling:** Trilinear spline interpolation resamples the volume from $(176 \times 208 \times 176)$ to a fixed $(96 \times 96 \times 96)$ 3D tensor, fitting within a 6GB GPU VRAM budget.
4. **Intensity Standardization:** Percentile clipping (0.5% to 99.5%) removes acquisition artifacts, followed by brain-tissue z-score normalization:
   $$z = \frac{x - \mu_{\text{brain}}}{\sigma_{\text{brain}}}$$
5. **Data Augmentation (Train split only):** Subtle 3D rotations ($\pm 7^\circ$), translations ($\pm 5\%$), scaling ($0.95 - 1.05$), and mild Gaussian noise ($\sigma = 0.02$).

---

## 6. Model Training & Class Imbalance Mitigation

- **Architecture:** `ResNet3D` with 3D Convolutions, 3D BatchNorm, and Global Average Pooling.
- **Class-Weighted Loss:** To prevent majority-class bias (Normal CDR 0), weights are computed **strictly from the training partition**:
  $$w_c = \frac{N_{\text{train}}}{C \times N_c}$$
- **Sampling:** Supported via PyTorch `WeightedRandomSampler`.
- **Optimization:** AdamW ($\text{lr} = 10^{-4}$, weight decay $= 10^{-4}$), ReduceLROnPlateau scheduler, mixed-precision (`torch.cuda.amp.autocast`), and early stopping monitoring Macro-F1.

---

## 7. Model Interpretability: 3D Grad-CAM

To ensure the neural network is attending to clinically meaningful neurodegenerative patterns (e.g. ventricular enlargement, medial temporal lobe / hippocampal atrophy) rather than background artifacts:
- 3D Grad-CAM computes gradients at the final convolutional stage (`layer4[-1]`).
- Activations are weighted and trilinearly interpolated back to $(96 \times 96 \times 96)$.
- Heatmaps are overlaid onto Sagittal, Coronal, and Axial slices and saved to `reports/gradcam/`.
- Every image is watermarked:  
  `"Model attention visualization — not a clinical interpretation."`

---

## 8. Installation & Setup

### Requirements
- Windows 10/11, Linux, or macOS.
- Python 3.11 or 3.12 (managed automatically via `uv`).
- NVIDIA GPU with $\ge 4\text{ GB}$ VRAM recommended (CPU fallback supported).

### Setup Environment
```bash
# Using uv (recommended)
uv venv .venv --python 3.11
.venv\Scripts\activate

# Install PyTorch with CUDA 12.4
uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

# Install pipeline dependencies
uv pip install -r requirements.txt
```

---

## 9. Running the Pipeline

### 1. Data Discovery & Validation
```bash
python src/data_discovery.py
python src/data_validation.py
```

### 2. Pre-Training Safety Verification Sequence
```bash
python src/safety_checks.py
```

### 3. Model Training
```bash
python src/train.py
```

### 4. Comprehensive Evaluation
```bash
python src/evaluate.py
```

### 5. CLI Inference
```bash
python src/inference.py "data/raw/disc1/OAS1_0001_MR1/PROCESSED/MPRAGE/T88_111/OAS1_0001_MR1_mpr_n4_anon_111_t88_masked_gfc.img"
```

### 6. Launch FastAPI Server
```bash
uvicorn api.main:app --host 0.0.0.0 --port 8000 --reload
```

Interactive API documentation available at: `http://localhost:8000/docs`

---

## 10. Frontend Integration (MindCare NER)

The module is integrated into the MindCare NER platform:
1. Start FastAPI backend on port 8000.
2. Start MindCare NER frontend:
   ```bash
   cd "C:\Users\LENOVO\voice folder\SIH-2026"
   npm run dev:frontend
   ```
3. Click **"MRI Analysis"** in the top navigation bar.
4. Upload an Analyze `.img` + `.hdr` pair or NIfTI file to view the estimation, class probability distribution, and 3D Grad-CAM attention heatmap.

---

## 11. Ethical Considerations & Limitations

1. **Research Tool:** Designed strictly to assist research and education. Not certified as a Medical Device (SaMD).
2. **Dataset Specificity:** Trained on OASIS-1 T1-weighted MPRAGE 1.5T scans. Performance on other scanner field strengths (e.g. 3T, 7T) or different acquisition sequences may vary.
3. **Confidence Scores:** Confidence values reflect model softmax distributions and must never be interpreted as clinical certainty.
