// lib/services/voice/voice_intent_router.dart
//
// Interface and models for deterministic routing of recognized voice commands.
//
// SAFETY RULE:
// Intent routing uses deterministic pattern matching (regex, keywords) for
// all application actions. LLMs/Qwen are used solely for explanation or rephrasing
// and never for unverified command classification or execution.

/// The 10 safe deterministic intents supported by MindCare NER.
enum VoiceIntentType {
  openGames,
  startMemoryGame,
  showTodayReminders,
  readNextReminder,
  repeatInstruction,
  openCaregiverHelp,
  openSettings,
  goHome,
  cancel,
  unknown;

  /// Whether this intent normally requires explicit elderly confirmation.
  bool get defaultRequiresConfirmation {
    switch (this) {
      case VoiceIntentType.openCaregiverHelp:
      case VoiceIntentType.goHome:
      case VoiceIntentType.cancel:
        return true;
      case VoiceIntentType.openGames:
      case VoiceIntentType.startMemoryGame:
      case VoiceIntentType.showTodayReminders:
      case VoiceIntentType.readNextReminder:
      case VoiceIntentType.repeatInstruction:
      case VoiceIntentType.openSettings:
      case VoiceIntentType.unknown:
        return false;
    }
  }

  /// Human-readable intent identifier.
  String get intentName {
    switch (this) {
      case VoiceIntentType.openGames:
        return 'openGames';
      case VoiceIntentType.startMemoryGame:
        return 'startMemoryGame';
      case VoiceIntentType.showTodayReminders:
        return 'showTodayReminders';
      case VoiceIntentType.readNextReminder:
        return 'readNextReminder';
      case VoiceIntentType.repeatInstruction:
        return 'repeatInstruction';
      case VoiceIntentType.openCaregiverHelp:
        return 'openCaregiverHelp';
      case VoiceIntentType.openSettings:
        return 'openSettings';
      case VoiceIntentType.goHome:
        return 'goHome';
      case VoiceIntentType.cancel:
        return 'cancel';
      case VoiceIntentType.unknown:
        return 'unknown';
    }
  }
}

/// Structured outcome of deterministic voice intent routing.
class VoiceIntentResult {
  final VoiceIntentType type;
  final double confidence;
  final String normalizedUtterance;
  final String detectedLanguage;
  final bool requiresConfirmation;
  final String? confirmationPrompt;
  final String? actionRoute;
  final bool isSafetyViolation;
  final String? safetyViolationReason;
  final String? safeFallbackMessage;
  final Map<String, dynamic> parameters;

  const VoiceIntentResult({
    required this.type,
    required this.confidence,
    this.normalizedUtterance = '',
    this.detectedLanguage = 'en',
    this.requiresConfirmation = false,
    this.confirmationPrompt,
    this.actionRoute,
    this.isSafetyViolation = false,
    this.safetyViolationReason,
    this.safeFallbackMessage,
    this.parameters = const {},
  });

  /// Factory for unknown or low-confidence voice input.
  factory VoiceIntentResult.unknown({
    required String normalizedUtterance,
    required String detectedLanguage,
    double confidence = 0.0,
    String? safeFallbackMessage,
  }) {
    return VoiceIntentResult(
      type: VoiceIntentType.unknown,
      confidence: confidence,
      normalizedUtterance: normalizedUtterance,
      detectedLanguage: detectedLanguage,
      safeFallbackMessage: safeFallbackMessage ??
          'I could not understand that request. You can say: Open Games, Show Reminders, or Help.',
    );
  }

  /// Factory for intercepted safety violations.
  factory VoiceIntentResult.safetyViolation({
    required String normalizedUtterance,
    required String detectedLanguage,
    required String reason,
    required String safeGuidance,
  }) {
    return VoiceIntentResult(
      type: VoiceIntentType.unknown,
      confidence: 0.0,
      normalizedUtterance: normalizedUtterance,
      detectedLanguage: detectedLanguage,
      isSafetyViolation: true,
      safetyViolationReason: reason,
      safeFallbackMessage: safeGuidance,
    );
  }
}

/// Contract for voice intent classification.
abstract class VoiceIntentRouter {
  /// Resolves raw recognized text into a deterministic intent result.
  Future<VoiceIntentResult> resolveIntent(
    String utterance,
    String languageCode, {
    double asrConfidence = 1.0,
  });
}
