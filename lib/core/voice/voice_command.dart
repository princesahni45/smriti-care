// lib/core/voice/voice_command.dart
//
// Represents a raw voice or text command received by the SmritiCare Voice Assistant.

/// Encapsulates user speech or text input for intent processing.
class VoiceCommand {
  /// The transcript or typed text.
  final String text;

  /// ISO language code ('en', 'hi', 'as', etc.).
  final String languageCode;

  /// Timestamp when the input was recorded.
  final DateTime timestamp;

  /// Recognition confidence score between 0.0 and 1.0.
  final double confidence;

  /// Indicates whether the speech recognition result is final or intermediate.
  final bool isFinal;

  /// True if input came via speech recognition; false if entered via text fallback.
  final bool isVoiceInput;

  VoiceCommand({
    required this.text,
    this.languageCode = 'en',
    DateTime? timestamp,
    this.confidence = 1.0,
    this.isFinal = true,
    this.isVoiceInput = true,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Normalized trimmed lowercase text for robust matching.
  String get normalizedText => text.trim().toLowerCase();

  /// Creates a text-fallback command.
  factory VoiceCommand.fromText(
    String text, {
    String languageCode = 'en',
  }) {
    return VoiceCommand(
      text: text,
      languageCode: languageCode,
      confidence: 1.0,
      isFinal: true,
      isVoiceInput: false,
    );
  }

  VoiceCommand copyWith({
    String? text,
    String? languageCode,
    DateTime? timestamp,
    double? confidence,
    bool? isFinal,
    bool? isVoiceInput,
  }) {
    return VoiceCommand(
      text: text ?? this.text,
      languageCode: languageCode ?? this.languageCode,
      timestamp: timestamp ?? this.timestamp,
      confidence: confidence ?? this.confidence,
      isFinal: isFinal ?? this.isFinal,
      isVoiceInput: isVoiceInput ?? this.isVoiceInput,
    );
  }

  @override
  String toString() =>
      'VoiceCommand(text: "$text", lang: $languageCode, conf: ${confidence.toStringAsFixed(2)}, final: $isFinal, voice: $isVoiceInput)';
}
