// lib/services/ai/ai_request.dart
//
// Structured Request Model for MindCare NER on-device AI.

/// Scope of conversational assistance permitted for the proof of concept.
enum AIContextType {
  /// Friendly, reassuring greeting.
  greeting,

  /// Clear, simple explanation of a cognitive game.
  gameExplanation,

  /// Gentle repetition of an existing reminder.
  reminderRepeat,

  /// Non-medical, day-to-day conversational questions.
  generalQuery,

  /// Guiding the patient to connect with their caregiver.
  caregiverAssistance,
}

class AIRequest {
  /// The user utterance, question, or trigger prompt.
  final String prompt;

  /// Target language code ('en', 'hi', 'as').
  final String languageCode;

  /// Name of the patient for warm personalization.
  final String patientName;

  /// Permitted context type.
  final AIContextType contextType;

  /// Additional contextual metadata (e.g. reminder text, game title).
  final Map<String, dynamic> metadata;

  const AIRequest({
    required this.prompt,
    required this.languageCode,
    this.patientName = 'Friend',
    this.contextType = AIContextType.generalQuery,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'prompt': prompt,
      'languageCode': languageCode,
      'patientName': patientName,
      'contextType': contextType.name,
      'metadata': metadata,
    };
  }
}
