// lib/services/ai/ai_model_status.dart
//
// AI Model Lifecycle Status and Device Benchmark Metrics for MindCare NER.

/// Lifecycle states for on-device AI models.
enum AIModelStatus {
  /// Model weights file is not present on the device storage.
  notInstalled,

  /// Model weights are currently loading into device RAM.
  loading,

  /// Model is loaded, warmed up, and ready for local inference.
  ready,

  /// Model is temporarily unavailable or unsupported on the current hardware.
  unavailable,

  /// An error occurred during initialization, loading, or execution.
  error,
}

/// Performance and resource telemetry recorded locally on-device.
///
/// NOTE: This data is strictly technical telemetry for caregiver diagnostics.
/// It contains NO sensitive patient information or conversational transcripts.
class AIModelBenchmarkMetrics {
  /// Resident RAM allocated by the model process in megabytes (MB).
  final double ramUsageMb;

  /// Time taken to map and load model weights from storage into memory in milliseconds.
  final int loadTimeMs;

  /// Latency until the first token or complete response is generated in milliseconds.
  final int firstResponseLatencyMs;

  /// Generation speed in tokens per second.
  final double tokensPerSecond;

  /// Physical size of the model weight file on device storage in megabytes.
  final double modelSizeMb;

  /// Active model identifier and quantization descriptor.
  final String modelVersion;

  /// Explicit flag verifying that execution was executed 100% locally without network requests.
  final bool isFullyOffline;

  const AIModelBenchmarkMetrics({
    this.ramUsageMb = 0.0,
    this.loadTimeMs = 0,
    this.firstResponseLatencyMs = 0,
    this.tokensPerSecond = 0.0,
    this.modelSizeMb = 0.0,
    this.modelVersion = 'Qwen3-0.6B-Q4_K_M',
    this.isFullyOffline = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'ramUsageMb': ramUsageMb,
      'loadTimeMs': loadTimeMs,
      'firstResponseLatencyMs': firstResponseLatencyMs,
      'tokensPerSecond': tokensPerSecond,
      'modelSizeMb': modelSizeMb,
      'modelVersion': modelVersion,
      'isFullyOffline': isFullyOffline,
    };
  }

  factory AIModelBenchmarkMetrics.fromMap(Map<String, dynamic> map) {
    return AIModelBenchmarkMetrics(
      ramUsageMb: (map['ramUsageMb'] as num?)?.toDouble() ?? 0.0,
      loadTimeMs: (map['loadTimeMs'] as num?)?.toInt() ?? 0,
      firstResponseLatencyMs:
          (map['firstResponseLatencyMs'] as num?)?.toInt() ?? 0,
      tokensPerSecond: (map['tokensPerSecond'] as num?)?.toDouble() ?? 0.0,
      modelSizeMb: (map['modelSizeMb'] as num?)?.toDouble() ?? 0.0,
      modelVersion: (map['modelVersion'] as String?) ?? 'Qwen3-0.6B-Q4_K_M',
      isFullyOffline: (map['isFullyOffline'] as bool?) ?? true,
    );
  }
}
