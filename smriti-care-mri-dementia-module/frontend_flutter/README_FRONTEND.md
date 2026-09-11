# Smriti Care - Flutter Frontend Integration for MRI Analysis

This directory contains the Flutter client integration components for the AI-Assisted Brain MRI Analysis module.

## Files
- `models/mri_result.dart`: Data model deserializing JSON inference results (prediction, class_id, confidence, probabilities, low-confidence warning, Grad-CAM URL, disclaimer).
- `services/mri_service.dart`: HTTP client handling multipart MRI uploads, `/health`, `/model-info`, and `/predict`.
- `screens/mri_analysis_screen.dart`: Complete, elderly-accessible UI with high-contrast cards, file picker, test scan presets, step-by-step progress feedback, probability distribution bars, 3D Grad-CAM visualization, and non-dismissible Medical Disclaimer.

## Integration in Smriti Care App
1. Place these files inside your Flutter project at `lib/features/mri_analysis/`.
2. Add `http: ^1.2.0` to `pubspec.yaml`.
3. Register the route `/mri-analysis` in `lib/app.dart` pointing to `MriAnalysisScreen`.
4. Ensure the FastAPI backend is running on `http://127.0.0.1:8000` (or `http://10.0.2.2:8000` for Android emulator).
