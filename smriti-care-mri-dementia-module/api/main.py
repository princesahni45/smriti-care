"""
FastAPI Backend for AI-Assisted Brain MRI Dementia Severity Estimation.
Endpoints:
- POST /predict: Accepts Analyze (.img + .hdr) or NIfTI (.nii/.nii.gz) files, runs inference
- GET /health: Health check, system memory, CUDA availability
- GET /model-info: Returns model architecture, class mappings, metrics, and disclaimers
- Static mount for /gradcam visualizations
"""

import os
import sys

# Ensure project root is in sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

import shutil
import tempfile
from pathlib import Path
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse

from src.utils import (
    load_config, get_device, check_gpu_memory,
    MEDICAL_DISCLAIMER, LABEL_HEADER, LOW_CONFIDENCE_WARNING
)
from src.inference import MRIInferencePipeline

# Initialize FastAPI App
app = FastAPI(
    title="AI-Assisted Dementia Severity Estimation API",
    description="Volumetric 3D Brain MRI analysis service for research and educational assistance.",
    version="1.0.0"
)

# Enable CORS for frontend integration (Vite dev server, Express backend, etc.)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load pipeline singleton
config = load_config()
pipeline = None
try:
    pipeline = MRIInferencePipeline()
    print("[API] MRI Inference Pipeline loaded successfully.")
except Exception as e:
    print(f"[API] Warning: Pipeline will be loaded on demand ({e})")

# Mount static reports directory for Grad-CAM retrieval
gradcam_dir = config['paths']['gradcam_dir']
os.makedirs(gradcam_dir, exist_ok=True)
app.mount("/static/gradcam", StaticFiles(directory=gradcam_dir), name="gradcam")

# Enforce 60MB max upload limit
MAX_UPLOAD_BYTES = 60 * 1024 * 1024


@app.get("/")
def root():
    return {
        "service": LABEL_HEADER,
        "disclaimer": MEDICAL_DISCLAIMER,
        "docs_url": "/docs",
        "health_check": "/health"
    }


@app.get("/health")
def health():
    device, dev_info = get_device()
    return {
        "status": "online",
        "service": LABEL_HEADER,
        "device": dev_info,
        "gpu_memory": check_gpu_memory(),
        "model_loaded": pipeline is not None and pipeline.model is not None,
        "disclaimer": MEDICAL_DISCLAIMER
    }


@app.get("/model-info")
def model_info():
    models_dir = config['paths']['models_dir']
    config_file = os.path.join(models_dir, "model_config.json")
    metrics_file = os.path.join(config['paths']['reports_dir'], "metrics.json")

    model_metadata = {}
    if os.path.exists(config_file):
        import json
        with open(config_file, "r") as f:
            model_metadata = json.load(f)

    eval_metrics = {}
    if os.path.exists(metrics_file):
        import json
        with open(metrics_file, "r") as f:
            eval_metrics = json.load(f)

    return {
        "service": LABEL_HEADER,
        "disclaimer": MEDICAL_DISCLAIMER,
        "architecture": config['model']['architecture'],
        "target_volume_shape": config['preprocessing']['target_shape'],
        "confidence_threshold": config['inference']['confidence_threshold'],
        "class_mapping": pipeline.class_names if pipeline else {},
        "training_metadata": model_metadata,
        "test_metrics": eval_metrics
    }


@app.post("/predict")
async def predict_mri(
    file: UploadFile = File(..., description="MRI file (.img, .nii, or .nii.gz)"),
    hdr_file: UploadFile = File(None, description="Paired Analyze 7.5 .hdr file (required if file is .img)")
):
    global pipeline
    if pipeline is None:
        try:
            pipeline = MRIInferencePipeline()
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Failed to initialize inference pipeline: {e}")

    filename = file.filename.lower()
    is_analyze = filename.endswith('.img')
    is_nifti = filename.endswith('.nii') or filename.endswith('.nii.gz')

    if not (is_analyze or is_nifti):
        raise HTTPException(
            status_code=400,
            detail="Unsupported format. Please upload an Analyze 7.5 pair (.img + .hdr) or NIfTI (.nii, .nii.gz)."
        )

    if is_analyze and hdr_file is None:
        raise HTTPException(
            status_code=400,
            detail="Analyze 7.5 format requires both the data file (.img) and the header file (.hdr)."
        )

    # Safe temp directory for processing upload
    temp_dir = tempfile.mkdtemp(prefix="mri_upload_")
    try:
        # Save primary volume file
        dest_img_path = os.path.join(temp_dir, file.filename)
        content = await file.read()
        if len(content) > MAX_UPLOAD_BYTES:
            raise HTTPException(status_code=413, detail=f"File exceeds maximum allowed size of {MAX_UPLOAD_BYTES // (1024**2)} MB")

        with open(dest_img_path, "wb") as f:
            f.write(content)

        # Save header file if Analyze pair
        dest_hdr_path = None
        if is_analyze and hdr_file:
            dest_hdr_path = os.path.join(temp_dir, hdr_file.filename)
            hdr_content = await hdr_file.read()
            with open(dest_hdr_path, "wb") as f:
                f.write(hdr_content)

        # Execute inference pipeline with Grad-CAM
        session_id = Path(file.filename).stem
        result = pipeline.predict(
            mri_path=dest_img_path,
            hdr_path=dest_hdr_path,
            generate_gradcam=True,
            session_id=session_id
        )

        # Adjust gradcam URL for client download if available
        if "gradcam_path" in result:
            basename = os.path.basename(result["gradcam_path"])
            result["gradcam_url"] = f"/static/gradcam/{basename}"

        return JSONResponse(content=result)

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Inference error: {str(e)}")
    finally:
        # Clean up temporary upload files
        shutil.rmtree(temp_dir, ignore_errors=True)
