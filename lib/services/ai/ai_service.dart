// lib/services/ai/ai_service.dart
//
// Primary AI Service Contract for MindCare NER.
//
// SAFETY MANDATES:
// 1. MUST NOT make emergency decisions or trigger SOS.
// 2. MUST NOT schedule medicine dosages or clinical prescriptions.
// 3. MUST NOT score cognitive games (scoring is deterministic).
// 4. Must operate 100% offline without uploading telemetry or audio.

import 'ai_model_status.dart';
import 'ai_request.dart';
import 'ai_response.dart';

abstract class AIService {
  /// Initializes the AI service and queries local model presence.
  Future<void> initialize();

  /// Whether the AI backend is currently loaded and ready for inference.
  bool get isAvailable;

  /// Current lifecycle status of the on-device model.
  AIModelStatus get status;

  /// Benchmark telemetry recorded for the active model session.
  AIModelBenchmarkMetrics get metrics;

  /// Generates a validated, dementia-safe conversational response.
  Future<AIResponse> generateResponse(AIRequest request);

  /// Cancels an in-flight generation task if currently active.
  Future<void> cancel();

  /// Releases model memory, handles, and background threads.
  Future<void> dispose();

  // ──────────────── Backward Compatibility Hooks ────────────────

  /// Legacy conversational helper.
  Future<String> getConversationalResponse({
    required String prompt,
    required String languageCode,
  });

  /// Legacy memory prompt helper.
  Future<List<String>> generateMemoryPrompts({
    required String patientName,
    required String topic,
    required String languageCode,
  });
}
