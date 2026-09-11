// lib/features/mri_analysis/services/mri_service.dart
//
// HTTP Service client for Smriti Care AI-Assisted MRI Dementia Severity Estimation API.

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/mri_result.dart';

class MriService {
  MriService._();
  static final MriService instance = MriService._();

  // Configurable host address.
  // Defaults to localhost (127.0.0.1:8000). For Android emulator, use 10.0.2.2:8000.
  String _baseUrl = 'http://127.0.0.1:8000';

  String get baseUrl => _baseUrl;

  void setBaseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// Health check query
  Future<Map<String, dynamic>> checkHealth() async {
    try {
      final uri = Uri.parse('$_baseUrl/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        return {'status': 'error', 'code': response.statusCode};
      }
    } catch (e) {
      return {'status': 'offline', 'error': e.toString()};
    }
  }

  /// Model metadata query
  Future<Map<String, dynamic>> getModelInfo() async {
    final uri = Uri.parse('$_baseUrl/model-info');
    final response = await http.get(uri).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
          'Failed to load model info (HTTP ${response.statusCode})');
    }
  }

  /// Post MRI bytes for inference
  Future<MriResult> predictBytes({
    required Uint8List mriBytes,
    required String filename,
    Uint8List? hdrBytes,
    String? hdrFilename,
    bool generateGradcam = true,
  }) async {
    final uri =
        Uri.parse('$_baseUrl/predict?generate_gradcam=$generateGradcam');
    final request = http.MultipartRequest('POST', uri);

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        mriBytes,
        filename: filename,
      ),
    );

    if (hdrBytes != null && hdrFilename != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'hdr_file',
          hdrBytes,
          filename: hdrFilename,
        ),
      );
    }

    final streamedResponse = await request.send().timeout(
          const Duration(minutes: 2),
          onTimeout: () => throw Exception(
              'MRI processing request timed out (limit: 2 minutes)'),
        );

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          json.decode(utf8.decode(response.bodyBytes));
      return MriResult.fromJson(data);
    } else {
      String errorMessage =
          'Inference server error (HTTP ${response.statusCode})';
      try {
        final errJson = json.decode(utf8.decode(response.bodyBytes));
        if (errJson is Map && errJson.containsKey('detail')) {
          errorMessage = errJson['detail'].toString();
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }
}
