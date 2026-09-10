// lib/core/services/mri_screening_service.dart
//
// MRI Screening Service for SmritiCare.
// Manages communication with external Python/FastAPI AI backend.
//
// Expected flow:
// Flutter App -> Select/upload MRI image -> FastAPI REST API -> AI model -> Prediction response -> Flutter result screen.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/mri_models.dart';

class MriScreeningService {
  MriScreeningService._();
  static final MriScreeningService instance = MriScreeningService._();

  String _apiBaseUrl = defaultApiUrl;

  static String get defaultApiUrl {
    if (kIsWeb) return 'http://localhost:8000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    } catch (_) {}
    return 'http://localhost:8000';
  }

  String get apiBaseUrl => _apiBaseUrl;

  void setBaseUrl(String url) {
    var cleanUrl = url.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    _apiBaseUrl = cleanUrl;
  }

  /// Check whether the FastAPI server is reachable
  Future<bool> checkBackendHealth() async {
    try {
      final uri = Uri.parse('$_apiBaseUrl/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Send MRI scan image to FastAPI backend
  /// POST /api/v1/mri/analyze
  Future<MriScanResult> analyzeMriScan({
    required String patientId,
    required List<int> imageBytes,
    required String fileName,
  }) async {
    final timestamp = DateTime.now();
    final scanId = 'mri_${timestamp.millisecondsSinceEpoch}';

    try {
      final uri = Uri.parse('$_apiBaseUrl/api/v1/mri/analyze');
      final request = http.MultipartRequest('POST', uri);
      request.fields['patient_id'] = patientId;
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: fileName,
        ),
      );

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return MriScanResult.fromMap({
          ...data,
          'scanId': scanId,
          'patientId': patientId,
          'status': 'completed',
          'serverUrl': _apiBaseUrl,
          'imageName': fileName,
        });
      } else {
        return MriScanResult(
          scanId: scanId,
          patientId: patientId,
          prediction: 'Analysis Inconclusive',
          predictionClass: MriPredictionClass.inconclusive,
          confidenceScore: 0.0,
          recommendation:
              'Server responded with HTTP ${response.statusCode}. Please verify image format and backend configuration.',
          status: 'failed',
          timestamp: timestamp,
          serverUrl: _apiBaseUrl,
          imageName: fileName,
        );
      }
    } catch (e) {
      debugPrint('MriScreeningService network note: $e');
      // Graceful offline fallback: Mark clearly as pending backend integration
      return MriScanResult(
        scanId: scanId,
        patientId: patientId,
        prediction: 'Pending Backend Connection',
        predictionClass: MriPredictionClass.inconclusive,
        confidenceScore: 0.0,
        recommendation:
            'Could not connect to FastAPI server at $_apiBaseUrl. Ensure your Python backend is running on the host machine or update the server URL in Settings.',
        status: 'pending_connection',
        timestamp: timestamp,
        serverUrl: _apiBaseUrl,
        imageName: fileName,
      );
    }
  }

  /// Sample demonstration response for design review & testing when server is not running
  MriScanResult generateDemoResult({
    required String patientId,
    required String sampleType,
    required String fileName,
  }) {
    final timestamp = DateTime.now();
    final scanId = 'demo_${timestamp.millisecondsSinceEpoch}';

    switch (sampleType.toLowerCase()) {
      case 'mci':
        return MriScanResult(
          scanId: scanId,
          patientId: patientId,
          prediction: 'Mild Cognitive Impairment (MCI) Patterns Detected',
          predictionClass: MriPredictionClass.mildCognitiveImpairment,
          confidenceScore: 0.88,
          recommendation:
              'Slight hippocampal volume variance detected in temporal lobe. Recommended: Follow-up cognitive evaluation and consultation with neurologist.',
          status: 'completed',
          timestamp: timestamp,
          serverUrl: 'Demo Offline Mode',
          imageName: fileName,
        );
      case 'dementia':
        return MriScanResult(
          scanId: scanId,
          patientId: patientId,
          prediction: 'Potential Structural Atrophy Detected',
          predictionClass: MriPredictionClass.dementiaRisk,
          confidenceScore: 0.91,
          recommendation:
              'Ventricle enlargement and cortical thinning detected. Clinical correlation with comprehensive neurocognitive battery strongly suggested.',
          status: 'completed',
          timestamp: timestamp,
          serverUrl: 'Demo Offline Mode',
          imageName: fileName,
        );
      default:
        return MriScanResult(
          scanId: scanId,
          patientId: patientId,
          prediction: 'Cognitively Normal (Age-Appropriate)',
          predictionClass: MriPredictionClass.normal,
          confidenceScore: 0.96,
          recommendation:
              'No significant structural atrophy or hippocampal volume reduction detected for this age cohort. Continue daily cognitive exercises.',
          status: 'completed',
          timestamp: timestamp,
          serverUrl: 'Demo Offline Mode',
          imageName: fileName,
        );
    }
  }
}
