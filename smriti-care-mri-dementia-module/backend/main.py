"""
FastAPI Server for Smriti Care AI-Assisted Brain MRI Dementia Severity Estimation.
Endpoints:
- POST /predict: Accepts NIfTI (.nii, .nii.gz) or Analyze (.img + .hdr), runs preprocessing & inference
- GET /health: Health check, device, model status, and disclaimer
- GET /model-info: Model architecture, class mapping, held-out test benchmark metrics, and disclaimers
- GET /static/gradcam/{filename}: Serves Grad-CAM attention visualization plots
"""

import os
import sys
import shutil
import tempfile
from pathlib import Path
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse

# Ensure backend root is in sys.path
backend_dir = os.path.abspath(os.path.dirname(__file__))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

import torch_loader

from utils import (
    load_config, get_device, check_gpu_memory,
    MEDICAL_DISCLAIMER, LABEL_HEADER, LOW_CONFIDENCE_WARNING
)
from inference import MRIInferencePipeline

# Initialize FastAPI App
app = FastAPI(
    title="Smriti Care - AI-Assisted MRI Dementia Severity Estimation API",
    description="3D Brain MRI Volumetric Analysis Service for Research & Educational Assistance.",
    version="1.0.0"
)

# Enable CORS for Flutter Web, Desktop, Mobile, and API consumers
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

config = load_config()
pipeline = None
try:
    pipeline = MRIInferencePipeline()
    print(f"[SmritiCare MRI API] Pipeline initialized successfully (Model loaded: {pipeline.is_ready()})")
except Exception as e:
    print(f"[SmritiCare MRI API] Notice: Pipeline deferred initialization ({e})")

# Static mount for Grad-CAM visualizations
gradcam_dir = os.path.join(backend_dir, config["paths"].get("gradcam_dir", "reports/gradcam"))
os.makedirs(gradcam_dir, exist_ok=True)
app.mount("/static/gradcam", StaticFiles(directory=gradcam_dir), name="gradcam")

# Enforce 60MB maximum upload limit
MAX_UPLOAD_BYTES = 60 * 1024 * 1024


@app.get("/")
def root():
    return {
        "service": "Smriti Care AI-Assisted Brain MRI Severity Estimation API",
        "label_header": LABEL_HEADER,
        "disclaimer": MEDICAL_DISCLAIMER,
        "docs_url": "/docs",
        "health_check": "/health",
        "model_info": "/model-info"
    }


@app.get("/health")
def health():
    device, dev_info = get_device()
    is_loaded = pipeline is not None and pipeline.is_ready()
    return {
        "status": "online",
        "service": LABEL_HEADER,
        "device": dev_info,
        "gpu_memory": check_gpu_memory(),
        "model_loaded": is_loaded,
        "active_model": "best_model_disc5.pth",
        "disclaimer": MEDICAL_DISCLAIMER
    }


@app.get("/model-info")
def model_info():
    is_loaded = pipeline is not None and pipeline.is_ready()
    class_map = pipeline.class_names if pipeline else {
        0: "Normal",
        1: "Very Mild Dementia",
        2: "Dementia (Mild/Moderate)"
    }

    # Standard held-out frozen test benchmark metrics (OASIS-1 10-subject benchmark)
    benchmark_metrics = {
        "dataset": "OASIS-1 Cross-Sectional (Discs 1-5)",
        "total_labeled_subjects": 94,
        "split_distribution": {"train": 68, "val": 16, "frozen_test": 10},
        "frozen_test_accuracy": 0.500,
        "frozen_test_macro_f1": 0.3385,
        "very_mild_recall": 0.333,
        "dementia_recall": 0.000,
        "evaluation_type": "Experimental Held-Out Benchmark (Not Clinical Validation)"
    }

    return {
        "service": LABEL_HEADER,
        "disclaimer": MEDICAL_DISCLAIMER,
        "architecture": config["model"]["architecture"],
        "active_checkpoint": config["paths"].get("active_checkpoint", "best_model_disc5.pth"),
        "model_loaded": is_loaded,
        "target_volume_shape": config["preprocessing"]["target_shape"],
        "confidence_threshold": config["inference"]["confidence_threshold"],
        "class_mapping": class_map,
        "benchmark_metrics": benchmark_metrics,
        "version": "1.0.0"
    }


@app.post("/predict")
async def predict_mri(
    file: UploadFile = File(..., description="MRI volume file (.nii, .nii.gz, or .img)"),
    hdr_file: UploadFile = File(None, description="Paired Analyze 7.5 .hdr file (required if primary is .img)"),
    generate_gradcam: bool = False
):
    global pipeline
    if pipeline is None:
        try:
            pipeline = MRIInferencePipeline()
        except Exception as e:
            raise HTTPException(
                status_code=503,
                detail=f"Inference pipeline initialization failure: {str(e)}"
            )

    if not pipeline.is_ready():
        raise HTTPException(
            status_code=503,
            detail=(
                "Model checkpoint 'best_model_disc5.pth' is not available. "
                "Please place the checkpoint in backend/models/ directory."
            )
        )

    if not file or not file.filename:
        raise HTTPException(status_code=400, detail="Empty upload. Please provide a valid MRI scan.")

    filename = file.filename.lower()
    is_analyze = filename.endswith(".img")
    is_nifti = filename.endswith(".nii") or filename.endswith(".nii.gz")

    if not (is_analyze or is_nifti):
        raise HTTPException(
            status_code=400,
            detail="Unsupported file format. Please upload NIfTI (.nii, .nii.gz) or Analyze 7.5 pair (.img + .hdr)."
        )

    if is_analyze and hdr_file is None:
        raise HTTPException(
            status_code=400,
            detail="Analyze 7.5 format requires both the data file (.img) and header file (.hdr)."
        )

    temp_dir = tempfile.mkdtemp(prefix="mri_upload_")
    try:
        dest_img_path = os.path.join(temp_dir, file.filename)
        content = await file.read()

        if len(content) == 0:
            raise HTTPException(status_code=400, detail="Uploaded file is empty (0 bytes).")

        if len(content) > MAX_UPLOAD_BYTES:
            raise HTTPException(
                status_code=413,
                detail=f"File exceeds maximum allowed size of {MAX_UPLOAD_BYTES // (1024**2)} MB."
            )

        with open(dest_img_path, "wb") as f:
            f.write(content)

        dest_hdr_path = None
        if is_analyze and hdr_file:
            dest_hdr_path = os.path.join(temp_dir, hdr_file.filename)
            hdr_content = await hdr_file.read()
            with open(dest_hdr_path, "wb") as f:
                f.write(hdr_content)

        session_id = Path(file.filename).stem
        if session_id.endswith(".nii"):
            session_id = Path(session_id).stem

        result = pipeline.predict(
            mri_path=dest_img_path,
            hdr_path=dest_hdr_path,
            generate_gradcam=generate_gradcam,
            session_id=session_id
        )

        if "gradcam_path" in result:
            basename = os.path.basename(result["gradcam_path"])
            result["gradcam_url"] = f"/static/gradcam/{basename}"

        return JSONResponse(content=result)

    except HTTPException:
        raise
    except FileNotFoundError as fnf:
        raise HTTPException(status_code=400, detail=f"File validation error: {str(fnf)}")
    except Exception as e:
        # Graceful user-friendly message without leaking internal system traces
        err_msg = str(e)
        if "nibabel" in err_msg.lower() or "header" in err_msg.lower():
            detail_msg = "Corrupted or invalid MRI header structure. Please verify the NIfTI/Analyze file."
        elif "empty" in err_msg.lower():
            detail_msg = "MRI volume contains no brain voxels after extraction."
        else:
            detail_msg = f"MRI Preprocessing or Inference failed: {err_msg}"
        raise HTTPException(status_code=422, detail=detail_msg)
    finally:
        shutil.rmtree(temp_dir, ignore_errors=True)
