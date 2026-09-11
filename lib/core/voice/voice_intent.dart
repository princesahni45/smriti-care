// lib/core/voice/voice_intent.dart
//
// Represents semantic intents recognized from voice or text input.
// ignore_for_file: constant_identifier_names

/// Canonical intent types supported by SmritiCare Voice Assistant.
enum VoiceIntentType {
  // ── PREDEFINED CANONICAL INTENTS (MindCare NER Specification) ─────────────
  /// Return to the Home / Dashboard screen or Take Me Home.
  OPEN_HOME,

  /// Open the Cognitive Games hub.
  OPEN_GAMES,

  /// Launch the Memory Match cognitive game.
  OPEN_MEMORY_GAME,

  /// Launch the Word Recall mini-game.
  OPEN_WORD_RECALL,

  /// Launch the Different Object (odd-one-out) mini-game.
  OPEN_DIFFERENT_OBJECT,

  /// Open the Reminders and Medications schedule screen.
  OPEN_REMINDERS,

  /// Read out the next upcoming medicine or task reminder.
  READ_NEXT_REMINDER,

  /// Open the Daily Routine sequence.
  OPEN_DAILY_ROUTINE,

  /// Open help / speak guidance on voice assistant usage.
  OPEN_HELP,

  /// Adjust game difficulty deterministically via adaptive difficulty mechanism.
  ADAPTIVE_DIFFICULTY,

  /// Read the next scheduled routine activity.
  READ_NEXT_ROUTINE,

  /// Call caregiver / trigger emergency SOS alert (Sensitive).
  CALL_CAREGIVER,

  /// Switch active voice and UI language.
  CHANGE_LANGUAGE,

  /// Navigate back to the previous screen.
  GO_BACK,

  /// Cancel current interaction or abort pending action.
  CANCEL,

  /// Ambiguous or unrecognized utterance.
  UNKNOWN,

  // ── BACKWARD-COMPATIBILITY ALIASES ───────────────────────────────────────
  navigate,
  openGames,
  playGame,
  checkReminders,
  addReminder,
  emergencySos,
  takeMeHome,
  changeLanguage,
  checkStatus,
  openCaregiver,
  help,
  confirm,
  cancel,
  unknown;

  /// Returns canonical uppercase intent name string.
  String get nameCode {
    switch (this) {
      case VoiceIntentType.OPEN_HOME:
      case VoiceIntentType.navigate:
      case VoiceIntentType.takeMeHome:
        return 'OPEN_HOME';
      case VoiceIntentType.OPEN_GAMES:
      case VoiceIntentType.openGames:
        return 'OPEN_GAMES';
      case VoiceIntentType.OPEN_MEMORY_GAME:
        return 'OPEN_MEMORY_GAME';
      case VoiceIntentType.OPEN_WORD_RECALL:
        return 'OPEN_WORD_RECALL';
      case VoiceIntentType.OPEN_DIFFERENT_OBJECT:
        return 'OPEN_DIFFERENT_OBJECT';
      case VoiceIntentType.OPEN_REMINDERS:
      case VoiceIntentType.checkReminders:
        return 'OPEN_REMINDERS';
      case VoiceIntentType.READ_NEXT_REMINDER:
        return 'READ_NEXT_REMINDER';
      case VoiceIntentType.OPEN_DAILY_ROUTINE:
        return 'OPEN_DAILY_ROUTINE';
      case VoiceIntentType.ADAPTIVE_DIFFICULTY:
        return 'ADAPTIVE_DIFFICULTY';
      case VoiceIntentType.READ_NEXT_ROUTINE:
        return 'READ_NEXT_ROUTINE';
      case VoiceIntentType.OPEN_HELP:
      case VoiceIntentType.help:
        return 'OPEN_HELP';
      case VoiceIntentType.CALL_CAREGIVER:
      case VoiceIntentType.emergencySos:
      case VoiceIntentType.openCaregiver:
        return 'CALL_CAREGIVER';
      case VoiceIntentType.CHANGE_LANGUAGE:
      case VoiceIntentType.changeLanguage:
        return 'CHANGE_LANGUAGE';
      case VoiceIntentType.GO_BACK:
        return 'GO_BACK';
      case VoiceIntentType.CANCEL:
      case VoiceIntentType.cancel:
        return 'CANCEL';
      case VoiceIntentType.UNKNOWN:
      case VoiceIntentType.unknown:
      default:
        return 'UNKNOWN';
    }
  }
}

/// Represents a parsed intent with confidence and extracted parameter slots.
class VoiceIntent {
  /// The classified intent category.
  final VoiceIntentType type;

  /// Classification confidence between 0.0 and 1.0.
  final double confidence;

  /// Extracted key-value parameters (e.g., targetRoute, gameId, languageCode).
  final Map<String, dynamic> slots;

  /// The raw matched phrase or pattern that triggered this intent.
  final String matchedPhrase;

  /// Whether this intent triggers a sensitive operation requiring user confirmation.
  final bool isSensitive;

  const VoiceIntent({
    required this.type,
    this.confidence = 1.0,
    this.slots = const {},
    this.matchedPhrase = '',
    this.isSensitive = false,
  });

  /// Factory for unrecognized / ambiguous commands.
  factory VoiceIntent.unknown([String phrase = '']) {
    return VoiceIntent(
      type: VoiceIntentType.unknown,
      confidence: 0.0,
      matchedPhrase: phrase,
      isSensitive: false,
    );
  }

  /// Factory for affirmative confirmation.
  factory VoiceIntent.confirm([String phrase = '']) {
    return VoiceIntent(
      type: VoiceIntentType.confirm,
      confidence: 1.0,
      matchedPhrase: phrase,
      isSensitive: false,
    );
  }

  /// Factory for cancellation.
  factory VoiceIntent.cancel([String phrase = '']) {
    return VoiceIntent(
      type: VoiceIntentType.cancel,
      confidence: 1.0,
      matchedPhrase: phrase,
      isSensitive: false,
    );
  }

  /// Convenience getter for target route slot if present.
  String? get targetRoute => slots['targetRoute'] as String?;

  /// Convenience getter for game ID slot if present.
  String? get gameId => slots['gameId'] as String?;

  /// Convenience getter for language code slot if present.
  String? get languageCode => slots['languageCode'] as String?;

  VoiceIntent copyWith({
    VoiceIntentType? type,
    double? confidence,
    Map<String, dynamic>? slots,
    String? matchedPhrase,
    bool? isSensitive,
  }) {
    return VoiceIntent(
      type: type ?? this.type,
      confidence: confidence ?? this.confidence,
      slots: slots ?? this.slots,
      matchedPhrase: matchedPhrase ?? this.matchedPhrase,
      isSensitive: isSensitive ?? this.isSensitive,
    );
  }

  @override
  String toString() =>
      'VoiceIntent(type: $type, conf: ${confidence.toStringAsFixed(2)}, slots: $slots, sensitive: $isSensitive)';
}
