// lib/config/api_config.dart
//
// FIX: Centralized API configuration for SmritiCare FastAPI backend.
// When testing on a physical Android phone on the same Wi-Fi as your laptop,
// replace the IP below with your laptop's LAN IPv4 address.
//
// How to find your laptop's LAN IP:
//   Windows: Open Command Prompt → type: ipconfig
//            Look for "IPv4 Address" under your Wi-Fi adapter (e.g. 192.168.1.105)
//   Mac/Linux: Open Terminal → type: ifconfig | grep "inet "
//
// IMPORTANT: Do NOT use localhost or 127.0.0.1 — those point to the phone itself.
//
// Examples:
//   Physical phone on same Wi-Fi : 'http://192.168.1.105:8000'  ← UPDATE THIS
//   Android emulator              : 'http://10.0.2.2:8000'

class ApiConfig {
  ApiConfig._();

  // ── FIX: Replace 192.168.x.x with your laptop's actual Wi-Fi IPv4 address ──
  // FIX: Configured MRI backend for physical Android device
  static const String baseUrl = 'http://10.109.253.252:8000';

  // Endpoint paths — from the REAL backend main.py
  static const String healthEndpoint = '/health';
  static const String predictMriEndpoint =
      '/predict'; // POST /predict in backend/main.py
  static const String modelInfoEndpoint = '/model-info';

  // HTTP timeouts
  static const int healthTimeoutSeconds = 5;
  static const int uploadTimeoutSeconds = 60; // 3D volumes can be large

  // ── MRI-compatible file extensions supported by the REAL preprocessing pipeline ──
  // Source: backend/preprocessing.py load_analyze_volume()
  //   - NIfTI:    .nii, .nii.gz
  //   - Analyze 7.5: .img (requires paired .hdr file)
  //
  // NOTE: .img files require a matching .hdr file in the same folder.
  //       DICOM (.dcm) is NOT directly supported by this backend.
  static const List<String> mriCompatibleExtensions = [
    'nii', // NIfTI uncompressed
    'nii.gz', // NIfTI gzip compressed
    'img', // Analyze 7.5 image data (needs .hdr pair)
  ];

  // Extensions that are saved locally but NOT sent to the AI model
  static const List<String> documentOnlyExtensions = [
    'pdf',
    'ppt',
    'pptx',
    'doc',
    'docx',
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
    'tiff',
    'tif',
    'webp',
    'dcm', // DICOM — not supported by this backend
    'hdr', // Analyze header alone — needs .img pair
    'mgz', // FreeSurfer — not supported
    'mgh', // FreeSurfer — not supported
  ];
}
