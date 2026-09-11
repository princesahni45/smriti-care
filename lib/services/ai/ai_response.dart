// lib/services/ai/ai_response.dart
//
// Structured Response Model for MindCare NER on-device AI.

import 'ai_model_status.dart';

class AIResponse {
  /// The generated, validated, dementia-safe textual response.
  final String text;

  /// True if the response was served by the deterministic fallback engine.
  final bool isFallback;

  /// Generation latency in milliseconds.
  final int latencyMs;

  /// Approximate number of tokens generated.
  final int tokensGenerated;

  /// Generation speed in tokens per second.
  final double tokensPerSecond;

  /// Final status of the model at the conclusion of the request.
  final AIModelStatus status;

  /// Optional error or reason code if fallback was triggered.
  final String? failureReason;

  const AIResponse({
    required this.text,
    this.isFallback = false,
    this.latencyMs = 0,
    this.tokensGenerated = 0,
    this.tokensPerSecond = 0.0,
    this.status = AIModelStatus.ready,
    this.failureReason,
  });

  factory AIResponse.fallback({
    required String text,
    String? reason,
    AIModelStatus status = AIModelStatus.unavailable,
    int latencyMs = 5,
  }) {
    return AIResponse(
      text: text,
      isFallback: true,
      latencyMs: latencyMs,
      tokensGenerated: text.split(' ').length,
      tokensPerSecond: 100.0,
      status: status,
      failureReason: reason,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isFallback': isFallback,
      'latencyMs': latencyMs,
      'tokensGenerated': tokensGenerated,
      'tokensPerSecond': tokensPerSecond,
      'status': status.name,
      'failureReason': failureReason,
    };
  }
}
