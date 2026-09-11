// lib/core/models/mri_models.dart
//
// Data models for MRI AI Screening & FastAPI Backend Integration.
// FIX: Models derived from REAL backend output fields (inference.py result dict).
// FIX: Added MriUploadedFile for local caregiver file storage metadata.
//
// Real backend output fields (from inference.py):
//   prediction, class_id, confidence, probabilities, display_probabilities,
//   is_low_confidence, clinical_note, disclaimer, label_header, model_info

import 'dart:convert';

enum MriPredictionClass {
  normal,
  veryMild,
  dementia,
  inconclusive,
}

enum MriFileCategory {
  mri,
  images,
  pdf,
  presentations,
  other,
}

// ── Uploaded File Metadata ────────────────────────────────────────────────────

/// Metadata record for every file the caregiver uploads.
/// Stored as JSON in app-local storage — never uploaded to cloud.
// FIX: Added local caregiver file storage metadata model
class MriUploadedFile {
  final String id;
  final String originalFileName;
  final String localFilePath;
  final MriFileCategory category;
  final String fileExtension;
  final int fileSizeBytes;
  final DateTime uploadedAt;
  final String caregiverId;
  final bool isMriCompatible;
  final String predictionStatus; // 'not_analyzed', 'analyzing', 'completed', 'failed', 'unsupported'
  final String? scanResultId;
  final String? hdrFilePath;     // For Analyze 7.5 .img — path to paired .hdr file

  const MriUploadedFile({
    required this.id,
    required this.originalFileName,
    required this.localFilePath,
    required this.category,
    required this.fileExtension,
    required this.fileSizeBytes,
    required this.uploadedAt,
    required this.caregiverId,
    required this.isMriCompatible,
    required this.predictionStatus,
    this.scanResultId,
    this.hdrFilePath,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'originalFileName': originalFileName,
    'localFilePath': localFilePath,
    'category': category.name,
    'fileExtension': fileExtension,
    'fileSizeBytes': fileSizeBytes,
    'uploadedAt': uploadedAt.toIso8601String(),
    'caregiverId': caregiverId,
    'isMriCompatible': isMriCompatible,
    'predictionStatus': predictionStatus,
    'scanResultId': scanResultId,
    'hdrFilePath': hdrFilePath,
  };

  factory MriUploadedFile.fromMap(Map<String, dynamic> map) {
    MriFileCategory cat = MriFileCategory.other;
    final catStr = (map['category'] ?? '').toString().toLowerCase();
    if (catStr == 'mri') {
      cat = MriFileCategory.mri;
    } else if (catStr == 'images') {
      cat = MriFileCategory.images;
    } else if (catStr == 'pdf') {
      cat = MriFileCategory.pdf;
    } else if (catStr == 'presentations') {
      cat = MriFileCategory.presentations;
    }

    return MriUploadedFile(
      id: map['id'] ?? '',
      originalFileName: map['originalFileName'] ?? '',
      localFilePath: map['localFilePath'] ?? '',
      category: cat,
      fileExtension: map['fileExtension'] ?? '',
      fileSizeBytes: (map['fileSizeBytes'] as num?)?.toInt() ?? 0,
      uploadedAt: map['uploadedAt'] != null
          ? DateTime.tryParse(map['uploadedAt']) ?? DateTime.now()
          : DateTime.now(),
      caregiverId: map['caregiverId'] ?? '',
      isMriCompatible: map['isMriCompatible'] == true,
      predictionStatus: map['predictionStatus'] ?? 'not_analyzed',
      scanResultId: map['scanResultId'],
      hdrFilePath: map['hdrFilePath'],
    );
  }

  String toJson() => jsonEncode(toMap());
  factory MriUploadedFile.fromJson(String source) =>
      MriUploadedFile.fromMap(jsonDecode(source) as Map<String, dynamic>);

  MriUploadedFile copyWith({
    String? predictionStatus,
    String? scanResultId,
    String? hdrFilePath,
  }) => MriUploadedFile(
    id: id, originalFileName: originalFileName,
    localFilePath: localFilePath, category: category,
    fileExtension: fileExtension, fileSizeBytes: fileSizeBytes,
    uploadedAt: uploadedAt, caregiverId: caregiverId,
    isMriCompatible: isMriCompatible,
    predictionStatus: predictionStatus ?? this.predictionStatus,
    scanResultId: scanResultId ?? this.scanResultId,
    hdrFilePath: hdrFilePath ?? this.hdrFilePath,
  );

  String get formattedSize {
    if (fileSizeBytes < 1024) return '${fileSizeBytes}B';
    if (fileSizeBytes < 1024 * 1024) return '${(fileSizeBytes / 1024).toStringAsFixed(1)}KB';
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

// ── MRI Scan Result ───────────────────────────────────────────────────────────

/// AI prediction result parsed from the REAL FastAPI /predict response.
/// Fields derived from backend/inference.py result dict.
// FIX: MRI result model derived from real backend output fields
class MriScanResult {
  final String scanId;
  final String patientId;       // caregiverId used here for record-keeping
  final String prediction;      // e.g. "Normal", "Very Mild Dementia", "Dementia (Mild/Moderate)"
  final MriPredictionClass predictionClass;
  final int classId;            // 0=Normal, 1=Very Mild, 2=Dementia
  final double confidenceScore; // 0.0–1.0 (from backend 'confidence' field)

  // Probabilities from backend — key=class_key (normal/very_mild/dementia), value=probability
  final Map<String, double>? probabilities;         // internal key form
  final Map<String, double>? displayProbabilities;  // human-readable labels

  final bool isLowConfidence;
  final String clinicalNote;    // threshold warning from backend
  final String recommendation;  // our Flutter-side summary
  final String disclaimer;
  final String status;          // 'completed', 'failed'
  final DateTime timestamp;
  final String serverUrl;
  final String? imageName;
  final String? localFilePath;
  final Map<String, dynamic>? modelInfo; // architecture, checkpoint, device
  // FIX: Added doctor review fields for Doctor Dashboard MRI screening
  final String? reviewedByDoctorId;
  final DateTime? reviewedAt;

  bool get isReviewed => reviewedByDoctorId != null;

  const MriScanResult({
    required this.scanId,
    required this.patientId,
    required this.prediction,
    required this.predictionClass,
    this.classId = 0,
    required this.confidenceScore,
    this.probabilities,
    this.displayProbabilities,
    this.isLowConfidence = false,
    this.clinicalNote = '',
    required this.recommendation,
    this.disclaimer = 'AI-generated MRI screening results are for research and decision-support purposes only and are not a medical diagnosis. Clinical interpretation must be performed by a qualified healthcare professional.',
    required this.status,
    required this.timestamp,
    required this.serverUrl,
    this.imageName,
    this.localFilePath,
    this.modelInfo,
    this.reviewedByDoctorId,
    this.reviewedAt,
  });

  /// Parse directly from the backend /predict JSON response.
  // FIX: fromBackendMap maps real backend JSON fields (inference.py output)
  factory MriScanResult.fromBackendMap(
    Map<String, dynamic> data, {
    required String scanId,
    required String caregiverId,
    required String serverUrl,
    String? imageName,
    String? localFilePath,
  }) {
    final predStr = (data['prediction'] ?? '').toString();
    final classIdRaw = (data['class_id'] as num?)?.toInt() ?? 0;
    final confidence = (data['confidence'] as num?)?.toDouble() ?? 0.0;

    MriPredictionClass predClass;
    switch (classIdRaw) {
      case 0:
        predClass = MriPredictionClass.normal;
        break;
      case 1:
        predClass = MriPredictionClass.veryMild;
        break;
      case 2:
        predClass = MriPredictionClass.dementia;
        break;
      default:
        predClass = MriPredictionClass.inconclusive;
    }

    Map<String, double>? probs;
    final rawProbs = data['probabilities'];
    if (rawProbs is Map) {
      probs = rawProbs.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
    }

    Map<String, double>? displayProbs;
    final rawDisplay = data['display_probabilities'];
    if (rawDisplay is Map) {
      displayProbs = rawDisplay.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
    }

    final isLow = data['is_low_confidence'] == true;
    final clinNote = (data['clinical_note'] ?? '').toString();
    final disclaimer = (data['disclaimer'] ??
        'AI-generated MRI screening results are for research and decision-support purposes only and are not a medical diagnosis. Clinical interpretation must be performed by a qualified healthcare professional.')
        .toString();

    // Build Flutter-facing recommendation from clinical_note + prediction
    String rec;
    if (isLow) {
      rec = '$clinNote Results should be interpreted with caution.';
    } else {
      switch (classIdRaw) {
        case 0:
          rec = 'No significant dementia markers detected. Continue routine cognitive monitoring.';
          break;
        case 1:
          rec = 'Very mild dementia patterns detected. Clinical follow-up evaluation recommended.';
          break;
        case 2:
          rec = 'Dementia markers detected. Urgent consultation with a neurologist is strongly recommended.';
          break;
        default:
          rec = clinNote.isNotEmpty ? clinNote : 'Consult a healthcare professional for clinical interpretation.';
      }
    }

    Map<String, dynamic>? modelInfo;
    if (data['model_info'] is Map) {
      modelInfo = Map<String, dynamic>.from(data['model_info'] as Map);
    }

    return MriScanResult(
      scanId: scanId,
      patientId: caregiverId,
      prediction: predStr,
      predictionClass: predClass,
      classId: classIdRaw,
      confidenceScore: confidence,
      probabilities: probs,
      displayProbabilities: displayProbs,
      isLowConfidence: isLow,
      clinicalNote: clinNote,
      recommendation: rec,
      disclaimer: disclaimer,
      status: 'completed',
      timestamp: DateTime.now(),
      serverUrl: serverUrl,
      imageName: imageName,
      localFilePath: localFilePath,
      modelInfo: modelInfo,
    );
  }

  // FIX: Added copyWith for updating MRI review status
  MriScanResult copyWith({
    String? reviewedByDoctorId,
    DateTime? reviewedAt,
    String? status,
  }) => MriScanResult(
    scanId: scanId,
    patientId: patientId,
    prediction: prediction,
    predictionClass: predictionClass,
    classId: classId,
    confidenceScore: confidenceScore,
    probabilities: probabilities,
    displayProbabilities: displayProbabilities,
    isLowConfidence: isLowConfidence,
    clinicalNote: clinicalNote,
    recommendation: recommendation,
    disclaimer: disclaimer,
    status: status ?? this.status,
    timestamp: timestamp,
    serverUrl: serverUrl,
    imageName: imageName,
    localFilePath: localFilePath,
    modelInfo: modelInfo,
    reviewedByDoctorId: reviewedByDoctorId ?? this.reviewedByDoctorId,
    reviewedAt: reviewedAt ?? this.reviewedAt,
  );

  Map<String, dynamic> toMap() => {
    'scanId': scanId,
    'patientId': patientId,
    'prediction': prediction,
    'predictionClass': predictionClass.name,
    'classId': classId,
    'confidenceScore': confidenceScore,
    'probabilities': probabilities,
    'displayProbabilities': displayProbabilities,
    'isLowConfidence': isLowConfidence,
    'clinicalNote': clinicalNote,
    'recommendation': recommendation,
    'disclaimer': disclaimer,
    'status': status,
    'timestamp': timestamp.toIso8601String(),
    'serverUrl': serverUrl,
    'imageName': imageName,
    'localFilePath': localFilePath,
    'modelInfo': modelInfo,
    'reviewedByDoctorId': reviewedByDoctorId,
    'reviewedAt': reviewedAt?.toIso8601String(),
  };

  factory MriScanResult.fromMap(Map<String, dynamic> map) {
    MriPredictionClass pClass = MriPredictionClass.inconclusive;
    final clsStr = (map['predictionClass'] ?? '').toString().toLowerCase();
    if (clsStr == 'normal') {
      pClass = MriPredictionClass.normal;
    } else if (clsStr == 'verymild' || clsStr == 'very_mild') {
      pClass = MriPredictionClass.veryMild;
    } else if (clsStr == 'dementia') {
      pClass = MriPredictionClass.dementia;
    }

    Map<String, double>? probs;
    if (map['probabilities'] is Map) {
      probs = (map['probabilities'] as Map).map(
          (k, v) => MapEntry(k.toString(), (v as num).toDouble()));
    }
    Map<String, double>? displayProbs;
    if (map['displayProbabilities'] is Map) {
      displayProbs = (map['displayProbabilities'] as Map).map(
          (k, v) => MapEntry(k.toString(), (v as num).toDouble()));
    }

    return MriScanResult(
      scanId: map['scanId'] ?? 'mri_${DateTime.now().millisecondsSinceEpoch}',
      patientId: map['patientId'] ?? '',
      prediction: map['prediction'] ?? '',
      predictionClass: pClass,
      classId: (map['classId'] as num?)?.toInt() ?? 0,
      confidenceScore: (map['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      probabilities: probs,
      displayProbabilities: displayProbs,
      isLowConfidence: map['isLowConfidence'] == true,
      clinicalNote: map['clinicalNote'] ?? '',
      recommendation: map['recommendation'] ?? '',
      disclaimer: map['disclaimer'] ?? '',
      status: map['status'] ?? 'completed',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      serverUrl: map['serverUrl'] ?? '',
      imageName: map['imageName'],
      localFilePath: map['localFilePath'],
      modelInfo: map['modelInfo'] is Map ? Map<String, dynamic>.from(map['modelInfo'] as Map) : null,
      reviewedByDoctorId: map['reviewedByDoctorId'] as String?,
      reviewedAt: map['reviewedAt'] != null
          ? DateTime.tryParse(map['reviewedAt'].toString())
          : null,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory MriScanResult.fromJson(String source) =>
      MriScanResult.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
