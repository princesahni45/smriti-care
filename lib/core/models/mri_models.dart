// lib/core/models/mri_models.dart
//
// Data models for MRI AI Screening & FastAPI Backend Integration.
// Strictly non-clinical: early assistance screening telemetry only.

import 'dart:convert';

enum MriPredictionClass {
  normal,
  mildCognitiveImpairment,
  dementiaRisk,
  inconclusive,
}

class MriScanResult {
  final String scanId;
  final String patientId;
  final String prediction; // 'Cognitively Normal', 'Mild Cognitive Impairment (MCI)', 'Dementia Risk'
  final MriPredictionClass predictionClass;
  final double confidenceScore; // 0.0 - 1.0
  final String recommendation;
  final String disclaimer;
  final String status; // 'completed', 'pending_connection', 'failed'
  final DateTime timestamp;
  final String serverUrl;
  final String? imageName;

  const MriScanResult({
    required this.scanId,
    required this.patientId,
    required this.prediction,
    required this.predictionClass,
    required this.confidenceScore,
    required this.recommendation,
    this.disclaimer =
        'AI screening aid only. Not a medical or clinical diagnosis. Please consult a qualified neurologist or radiologist.',
    required this.status,
    required this.timestamp,
    required this.serverUrl,
    this.imageName,
  });

  Map<String, dynamic> toMap() {
    return {
      'scanId': scanId,
      'patientId': patientId,
      'prediction': prediction,
      'predictionClass': predictionClass.name,
      'confidenceScore': confidenceScore,
      'recommendation': recommendation,
      'disclaimer': disclaimer,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'serverUrl': serverUrl,
      'imageName': imageName,
    };
  }

  factory MriScanResult.fromMap(Map<String, dynamic> map) {
    MriPredictionClass pClass = MriPredictionClass.normal;
    final clsStr = (map['predictionClass'] ?? '').toString().toLowerCase();
    if (clsStr.contains('mild') || clsStr.contains('mci')) {
      pClass = MriPredictionClass.mildCognitiveImpairment;
    } else if (clsStr.contains('dementia') || clsStr.contains('alzheimer')) {
      pClass = MriPredictionClass.dementiaRisk;
    } else if (clsStr.contains('inconclusive')) {
      pClass = MriPredictionClass.inconclusive;
    }

    return MriScanResult(
      scanId: map['scanId'] ?? 'mri_${DateTime.now().millisecondsSinceEpoch}',
      patientId: map['patientId'] ?? 'MC-2048',
      prediction: map['prediction'] ?? 'Cognitively Normal',
      predictionClass: pClass,
      confidenceScore: (map['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      recommendation: map['recommendation'] ?? 'Routine screening recommended.',
      disclaimer: map['disclaimer'] ??
          'AI screening aid only. Not a medical or clinical diagnosis.',
      status: map['status'] ?? 'completed',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      serverUrl: map['serverUrl'] ?? '',
      imageName: map['imageName'],
    );
  }

  String toJson() => jsonEncode(toMap());

  factory MriScanResult.fromJson(String source) =>
      MriScanResult.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
