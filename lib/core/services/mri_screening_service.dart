// lib/core/services/mri_screening_service.dart
//
// FIX: Updated MRI Screening Service for SmritiCare.
// Uses the REAL FastAPI backend POST /predict endpoint.
// Handles both NIfTI (.nii / .nii.gz) and Analyze 7.5 (.img + .hdr pair).
// No fake/demo predictions — only returns real backend results.
//
// Backend endpoint: POST /predict
// Parameters:
//   file: UploadFile (.nii, .nii.gz, or .img)
//   hdr_file: UploadFile (required when file is .img)
//   generate_gradcam: bool (optional, default false)

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/mri_models.dart';
import '../../config/api_config.dart';

class MriScreeningService {
  MriScreeningService._();
  static final MriScreeningService instance = MriScreeningService._();

  // FIX: URL comes from ApiConfig — update ApiConfig.baseUrl for your physical device IP
  String _apiBaseUrl = ApiConfig.baseUrl;

  String get apiBaseUrl => _apiBaseUrl;

  void setBaseUrl(String url) {
    var cleanUrl = url.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    _apiBaseUrl = cleanUrl;
  }

  // ── Health Check ──────────────────────────────────────────────────────────

  // FIX: Added FastAPI MRI integration — health check
  Future<bool> checkBackendHealth() async {
    try {
      final uri = Uri.parse('$_apiBaseUrl${ApiConfig.healthEndpoint}');
      final response = await http
          .get(uri)
          .timeout(Duration(seconds: ApiConfig.healthTimeoutSeconds));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getHealthDetails() async {
    try {
      final uri = Uri.parse('$_apiBaseUrl${ApiConfig.healthEndpoint}');
      final response = await http
          .get(uri)
          .timeout(Duration(seconds: ApiConfig.healthTimeoutSeconds));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── MRI File Analysis ─────────────────────────────────────────────────────

  /// Sends a real MRI file to POST /predict and returns the prediction result.
  ///
  /// Supported formats (from backend preprocessing.py):
  ///   - .nii      → send as single file
  ///   - .nii.gz   → send as single file
  ///   - .img      → send as 'file'; must also provide [hdrPath] for 'hdr_file'
  ///
  /// Returns [MriScanResult] with status='completed' on success.
  /// On any failure (offline, timeout, model error) returns a result with status='failed'.
  // FIX: Connected real PyTorch model via FastAPI multipart upload
  Future<MriScanResult> analyzeMriFile({
    required String filePath,
    required String fileName,
    required String caregiverId,
    String? hdrPath, // Required for Analyze 7.5 .img files
    bool generateGradcam = false,
  }) async {
    final timestamp = DateTime.now();
    final scanId = 'mri_${timestamp.millisecondsSinceEpoch}';

    try {
      final uri = Uri.parse('$_apiBaseUrl${ApiConfig.predictMriEndpoint}');
      final request = http.MultipartRequest('POST', uri);

      // Add query param for gradcam
      if (generateGradcam) {
        request.fields['generate_gradcam'] = 'true';
      }

      // Attach the primary MRI file
      final fileToUpload = await http.MultipartFile.fromPath(
        'file',
        filePath,
        filename: fileName,
      );
      request.files.add(fileToUpload);

      // Attach .hdr pair file if this is Analyze 7.5 .img format
      if (hdrPath != null && hdrPath.isNotEmpty) {
        final hdrFile = File(hdrPath);
        if (await hdrFile.exists()) {
          final hdrUpload = await http.MultipartFile.fromPath(
            'hdr_file',
            hdrPath,
            filename: hdrPath.split(Platform.pathSeparator).last,
          );
          request.files.add(hdrUpload);
        }
      }

      final streamedResponse = await request
          .send()
          .timeout(Duration(seconds: ApiConfig.uploadTimeoutSeconds));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return MriScanResult.fromBackendMap(data,
            scanId: scanId,
            caregiverId: caregiverId,
            serverUrl: _apiBaseUrl,
            imageName: fileName);
      } else if (response.statusCode == 503) {
        // Model not loaded (checkpoint missing)
        String detail = 'AI model is not loaded on the server.';
        try {
          final errData = jsonDecode(response.body) as Map<String, dynamic>;
          detail = errData['detail']?.toString() ?? detail;
        } catch (_) {}
        return MriScanResult(
          scanId: scanId,
          patientId: caregiverId,
          prediction: 'Model Not Available',
          predictionClass: MriPredictionClass.inconclusive,
          confidenceScore: 0.0,
          recommendation: detail,
          status: 'failed',
          timestamp: timestamp,
          serverUrl: _apiBaseUrl,
          imageName: fileName,
        );
      } else if (response.statusCode == 400 || response.statusCode == 422) {
        String detail = 'Invalid file or format not supported by the backend.';
        try {
          final errData = jsonDecode(response.body) as Map<String, dynamic>;
          detail = errData['detail']?.toString() ?? detail;
        } catch (_) {}
        return MriScanResult(
          scanId: scanId,
          patientId: caregiverId,
          prediction: 'Invalid MRI File',
          predictionClass: MriPredictionClass.inconclusive,
          confidenceScore: 0.0,
          recommendation: detail,
          status: 'failed',
          timestamp: timestamp,
          serverUrl: _apiBaseUrl,
          imageName: fileName,
        );
      } else {
        return MriScanResult(
          scanId: scanId,
          patientId: caregiverId,
          prediction: 'Analysis Inconclusive',
          predictionClass: MriPredictionClass.inconclusive,
          confidenceScore: 0.0,
          recommendation: 'Server responded with HTTP ${response.statusCode}.',
          status: 'failed',
          timestamp: timestamp,
          serverUrl: _apiBaseUrl,
          imageName: fileName,
        );
      }
    } on SocketException {
      return _offlineResult(scanId, caregiverId, fileName, timestamp);
    } on http.ClientException {
      return _offlineResult(scanId, caregiverId, fileName, timestamp);
    } catch (e) {
      debugPrint('MriScreeningService error: $e');
      return MriScanResult(
        scanId: scanId,
        patientId: caregiverId,
        prediction: 'Analysis Failed',
        predictionClass: MriPredictionClass.inconclusive,
        confidenceScore: 0.0,
        recommendation: 'Unexpected error: ${e.toString().split('\n').first}',
        status: 'failed',
        timestamp: timestamp,
        serverUrl: _apiBaseUrl,
        imageName: fileName,
      );
    }
  }

  MriScanResult _offlineResult(String scanId, String caregiverId,
          String fileName, DateTime timestamp) =>
      MriScanResult(
        scanId: scanId,
        patientId: caregiverId,
        prediction: 'Backend Offline',
        predictionClass: MriPredictionClass.inconclusive,
        confidenceScore: 0.0,
        recommendation: 'Cannot connect to FastAPI backend at $_apiBaseUrl.\n'
            'Ensure the Python server is running:\n'
            'cd smriti-care-mri-dementia-module/backend\n'
            'uvicorn main:app --host 0.0.0.0 --port 8000',
        status: 'failed',
        timestamp: timestamp,
        serverUrl: _apiBaseUrl,
        imageName: fileName,
      );
}
