// lib/services/voice/asr_result.dart
//
// Structured ASR Output Result with Acoustic Confidence and Metadata.

class ASRResult {
  /// The transcribed spoken text.
  final String recognizedText;

  /// Acoustic confidence score from 0.0 (unintelligible) to 1.0 (certain).
  final double confidence;

  /// Language code used during recognition ('en', 'hi', 'as').
  final String languageCode;

  /// Time taken to process the audio buffer in milliseconds.
  final int recognitionTimeMs;

  /// Whether valid human speech activity was detected in the buffer.
  final bool isSpeechDetected;

  /// Whether this result was produced by a fallback/default mechanism.
  final bool isFallback;

  /// Optional error reason if speech was not detected or decoding failed.
  final String? failureReason;

  const ASRResult({
    required this.recognizedText,
    this.confidence = 0.0,
    required this.languageCode,
    this.recognitionTimeMs = 0,
    this.isSpeechDetected = true,
    this.isFallback = false,
    this.failureReason,
  });

  /// Whether the audio buffer was recognized successfully with speech.
  bool get isSuccess =>
      isSpeechDetected && failureReason == null && recognizedText.isNotEmpty;

  /// Whether recognition failed due to an error or missing weights.
  bool get isFailed => failureReason != null;

  factory ASRResult.noSpeech({
    required String languageCode,
    int recognitionTimeMs = 0,
  }) {
    return ASRResult(
      recognizedText: '',
      confidence: 0.0,
      languageCode: languageCode,
      recognitionTimeMs: recognitionTimeMs,
      isSpeechDetected: false,
      isFallback: true,
      failureReason: 'No speech detected in audio buffer',
    );
  }

  factory ASRResult.failure({
    required String languageCode,
    required String reason,
    int recognitionTimeMs = 0,
  }) {
    return ASRResult(
      recognizedText: '',
      confidence: 0.0,
      languageCode: languageCode,
      recognitionTimeMs: recognitionTimeMs,
      isSpeechDetected: false,
      isFallback: true,
      failureReason: reason,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recognizedText': recognizedText,
      'confidence': confidence,
      'languageCode': languageCode,
      'recognitionTimeMs': recognitionTimeMs,
      'isSpeechDetected': isSpeechDetected,
      'isFallback': isFallback,
      'failureReason': failureReason,
    };
  }
}
