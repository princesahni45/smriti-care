@echo off
REM ─────────────────────────────────────────────────────────────────────────────
REM  SmritiCare MRI AI Backend Startup Script
REM  Starts the FastAPI server serving the real 3D ResNet-10 dementia model.
REM
REM  Prerequisites:
REM    1. Python 3.11 or 3.12 installed
REM    2. Virtual environment created and activated (or use uv):
REM
REM       Option A - pip:
REM         python -m venv .venv
REM         .venv\Scripts\activate
REM         pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
REM         pip install -r requirements.txt
REM
REM       Option B - uv (faster):
REM         uv venv .venv --python 3.11
REM         .venv\Scripts\activate
REM         uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
REM         uv pip install -r requirements.txt
REM
REM  Run this script from the SmritiCare project root:
REM    .\start_mri_backend.cmd
REM
REM  After starting, test health at:
REM    http://localhost:8000/health
REM    http://localhost:8000/docs   (Swagger UI)
REM
REM  For Flutter on a PHYSICAL ANDROID PHONE, find your laptop's LAN IP:
REM    ipconfig  →  look for IPv4 Address under your Wi-Fi adapter
REM    Example: 192.168.1.105
REM    Then update lib\config\api_config.dart:
REM      static const String baseUrl = 'http://192.168.1.105:8000';
REM ─────────────────────────────────────────────────────────────────────────────

echo.
echo  ╔══════════════════════════════════════════════════════════════╗
echo  ║   SmritiCare AI-Assisted MRI Dementia Screening Backend     ║
echo  ║   3D ResNet-10 · OASIS-1 · best_model_disc5.pth            ║
echo  ╚══════════════════════════════════════════════════════════════╝
echo.
echo  Model:     3D ResNet-10 (resnet10_3d)
echo  Weights:   smriti-care-mri-dementia-module\backend\models\best_model_disc5.pth
echo  Classes:   Normal / Very Mild Dementia / Dementia (Mild/Moderate)
echo  Input:     96x96x96 voxel volumes
echo  Formats:   .nii  .nii.gz  .img+.hdr (Analyze 7.5)
echo  Endpoint:  POST http://0.0.0.0:8000/predict
echo  Health:    GET  http://0.0.0.0:8000/health
echo.
echo  Starting FastAPI backend server...
echo.

REM Change into backend directory and launch uvicorn
cd smriti-care-mri-dementia-module\backend
uvicorn main:app --host 0.0.0.0 --port 8000 --reload

echo.
echo  Server stopped.
pause
