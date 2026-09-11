// lib/services/voice/asr_model_status.dart
//
// ASR Model Status and Real-Time Benchmark Telemetry for MindCare NER.

/// Lifecycle status states for on-device ASR models.
enum ASRModelStatus {
  /// Acoustic model weights are not found on device storage.
  notInstalled,

  /// Model is currently loading into device RAM.
  loading,

  /// Model is ready for local offline audio inference.
  ready,

  /// Model is temporarily unavailable or language is unsupported.
  unavailable,

  /// Device is experiencing low RAM headroom (< 200 MB available).
  lowMemory,

  /// An error occurred during initialization or decoding.
  error,
}

/// Technical telemetry recorded on-device for developer/caregiver diagnostics.
/// Contains ZERO sensitive patient information or recorded audio data.
class ASRBenchmarkMetrics {
  /// Time taken to load acoustic model into RAM in milliseconds.
  final int loadTimeMs;

  /// Time taken to decode audio into text in milliseconds.
  final int recognitionTimeMs;

  /// Resident memory allocated by the ASR engine in megabytes.
  final double ramUsageMb;

  /// Recognized speech confidence (0.0 to 1.0).
  final double confidence;

  /// Language code evaluated during the benchmark session.
  final String languageCode;

  /// Flag confirming zero remote network calls were made.
  final bool isFullyOffline;

  /// Optional failure explanation if an error occurred.
  final String? failureReason;

  const ASRBenchmarkMetrics({
    this.loadTimeMs = 0,
    this.recognitionTimeMs = 0,
    this.ramUsageMb = 0.0,
    this.confidence = 0.0,
    this.languageCode = 'en',
    this.isFullyOffline = true,
    this.failureReason,
  });

  Map<String, dynamic> toMap() {
    return {
      'loadTimeMs': loadTimeMs,
      'recognitionTimeMs': recognitionTimeMs,
      'ramUsageMb': ramUsageMb,
      'confidence': confidence,
      'languageCode': languageCode,
      'isFullyOffline': isFullyOffline,
      'failureReason': failureReason,
    };
  }

  factory ASRBenchmarkMetrics.fromMap(Map<String, dynamic> map) {
    return ASRBenchmarkMetrics(
      loadTimeMs: (map['loadTimeMs'] as num?)?.toInt() ?? 0,
      recognitionTimeMs: (map['recognitionTimeMs'] as num?)?.toInt() ?? 0,
      ramUsageMb: (map['ramUsageMb'] as num?)?.toDouble() ?? 0.0,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      languageCode: (map['languageCode'] as String?) ?? 'en',
      isFullyOffline: (map['isFullyOffline'] as bool?) ?? true,
      failureReason: map['failureReason'] as String?,
    );
  }
}
