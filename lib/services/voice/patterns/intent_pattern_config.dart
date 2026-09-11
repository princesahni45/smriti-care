// lib/services/voice/patterns/intent_pattern_config.dart
//
// Structured schema for language-specific voice intent patterns.

import '../voice_intent_router.dart';

class IntentPatternDefinition {
  final VoiceIntentType type;
  final List<String> phrases;
  final List<RegExp> patterns;
  final String confirmationPrompt;
  final String executionFeedback;
  final String? actionRoute;
  final bool requiresConfirmation;

  const IntentPatternDefinition({
    required this.type,
    this.phrases = const [],
    this.patterns = const [],
    required this.confirmationPrompt,
    required this.executionFeedback,
    this.actionRoute,
    this.requiresConfirmation = false,
  });

  /// Tests whether normalized text matches this intent.
  bool matches(String normalizedText) {
    for (final phrase in phrases) {
      if (normalizedText == phrase || normalizedText.contains(phrase)) {
        return true;
      }
    }
    for (final pattern in patterns) {
      if (pattern.hasMatch(normalizedText)) {
        return true;
      }
    }
    return false;
  }
}
