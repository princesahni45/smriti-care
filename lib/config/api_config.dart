// lib/config/api_config.dart
//
// Centralized API configuration for SmritiCare FastAPI backend.
//
// Physical Android phone on the same Wi-Fi as your laptop:
// Replace wifiLanUrl with your laptop's LAN IPv4 address.
//
// Windows: Open Command Prompt and type:
//   ipconfig
// Look for IPv4 Address under your Wi-Fi adapter.
//
// IMPORTANT:
// Do NOT use localhost or 127.0.0.1 for a physical phone
// unless you are using ADB reverse.
//
// Physical phone with ADB reverse:
//   http://127.0.0.1:8000
//
// Android emulator:
//   http://10.0.2.2:8000

class ApiConfig {
  ApiConfig._();

  // ── Backend URLs ──────────────────────────────────────────────

  /// Central configurable default backend URL.
  /// Can be overridden at compile-time via:
  ///   flutter run --dart-define=BACKEND_URL=http://<YOUR_IP>:8000
  /// Defaults to the laptop's Mobile Hotspot IP or Wi-Fi LAN IP.
  static const String defaultUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://192.168.137.1:8000',
  );

  /// Active default URL used by services across the app.
  static const String baseUrl = defaultUrl;

  /// Mobile Hotspot IP (Windows Mobile Hotspot default is 192.168.137.1).
  static const String hotspotUrl = 'http://192.168.137.1:8000';

  /// Laptop Wi-Fi LAN IP (update as needed from `ipconfig`).
  static const String wifiLanUrl = 'http://10.21.226.78:8000';

  /// ADB reverse over USB cable.
  static const String usbUrl = 'http://127.0.0.1:8000';

  /// Android emulator URL.
  static const String emulatorUrl = 'http://10.0.2.2:8000';

  // ── Endpoint paths ────────────────────────────────────────────

  static const String healthEndpoint = '/health';

  // POST /predict in backend/main.py
  static const String predictMriEndpoint = '/predict';

  static const String modelInfoEndpoint = '/model-info';

  // ── HTTP timeouts ─────────────────────────────────────────────

  static const int healthTimeoutSeconds = 5;

  // 3D MRI volumes can be large.
  static const int uploadTimeoutSeconds = 60;

  // ── MRI-compatible file extensions ────────────────────────────
  //
  // Supported by the backend preprocessing pipeline:
  // - NIfTI: .nii, .nii.gz
  // - Analyze 7.5: .img (requires paired .hdr)
  // - Gzip compressed volume: .gz
  // - DICOM: .dcm, .dicom
  // - Compressed MRI archive: .zip
  //
  // NOTE:
  // .img files require a matching .hdr file in the same folder.

  static const List<String> mriCompatibleExtensions = [
    'nii', // NIfTI uncompressed
    'nii.gz', // NIfTI gzip compressed
    'gz', // Gzip compressed volume
    'dcm', // DICOM single slice/volume
    'dicom', // DICOM format
    'zip', // Compressed MRI archive
    'img', // Analyze 7.5 image data (needs .hdr pair)
  ];

  // ── Document-only extensions ──────────────────────────────────
  //
  // Saved locally but NOT sent to the AI model.

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
