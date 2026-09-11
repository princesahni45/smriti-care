// lib/services/voice/asr_request.dart
//
// Structured ASR Processing Request for MindCare NER.

class ASRRequest {
  /// Target language code ('en', 'hi', 'as').
  final String languageCode;

  /// Raw audio PCM bytes (16kHz, 16-bit mono) captured in volatile memory.
  final List<int> audioBytes;

  /// Duration of the recorded utterance in milliseconds.
  final int durationMs;

  /// Timestamp when audio capture completed.
  final DateTime timestamp;

  const ASRRequest({
    required this.languageCode,
    required this.audioBytes,
    required this.durationMs,
    required this.timestamp,
  });
}
