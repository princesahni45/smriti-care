// lib/core/ai/ai_response_validator.dart
//
// Strict output validator for local SLM text generations.
//
// Security & Safety Guarantees:
// 1. Output never executes actions directly; maps strictly to predefined VoiceIntent values.
// 2. Blocks any attempt to mutate medicines, patient records, caregiver settings, or delete data.
// 3. Blocks navigation injection or arbitrary code execution.
// 4. Returns VoiceIntent.unknown for invalid, ambiguous, or untrusted output.

import '../voice/voice_intent.dart';
import 'ai_context_builder.dart';

/// Validator that inspects raw on-device model output and maps it exclusively
/// to safe, approved [VoiceIntent] values.
class AiResponseValidator {
  const AiResponseValidator();

  /// Prohibited keywords that trigger immediate rejection as untrusted.
  static const Set<String> _forbiddenTokens = {
    'delete',
    'drop',
    'erase',
    'modify',
    'medicine',
    'medication',
    'prescription',
    'pin',
    'password',
    'caregiver_pin',
    'settings',
    'navigate',
    'router',
    'eval',
    'exec',
    'system',
    'override',
  };

  /// Validates raw string output from the local SLM and maps it to a canonical [VoiceIntent].
  VoiceIntent validateAndMap({
    required String rawOutput,
    required AiContext context,
    required String originalUserPrompt,
  }) {
    final clean = rawOutput.trim().toUpperCase();

    if (clean.isEmpty) {
      return VoiceIntent.unknown(originalUserPrompt);
    }

    // 1. Security Check: Reject forbidden mutation or tampering attempts
    final lower = rawOutput.toLowerCase();
    for (final forbidden in _forbiddenTokens) {
      if (lower.contains(forbidden) && !_isBenignIntentToken(clean)) {
        return VoiceIntent(
          type: VoiceIntentType.unknown,
          confidence: 0.0,
          matchedPhrase: originalUserPrompt,
        );
      }
    }

    // 2. Canonical Intent Mapping
    final intentType = _mapStringToIntentType(clean);
    if (intentType == null || intentType == VoiceIntentType.unknown) {
      return VoiceIntent.unknown(originalUserPrompt);
    }

    // 3. Sensitive Action Safety Tagging (requires explicit user confirmation)
    final isSensitive = intentType == VoiceIntentType.CALL_CAREGIVER;

    // 4. Construct validated, immutable VoiceIntent
    return VoiceIntent(
      type: intentType,
      confidence: 0.85,
      matchedPhrase: originalUserPrompt,
      isSensitive: isSensitive,
      slots: _buildSafeSlots(intentType, context),
    );
  }

  /// Maps an uppercase token to an approved [VoiceIntentType].
  static VoiceIntentType? _mapStringToIntentType(String token) {
    // Extract first token in case model added extra whitespace or punctuation
    final normalized = token
        .replaceAll(RegExp(r'[^A-Z_]'), ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .firstOrNull;

    if (normalized == null) return null;

    switch (normalized) {
      case 'OPEN_HOME':
        return VoiceIntentType.OPEN_HOME;
      case 'OPEN_GAMES':
        return VoiceIntentType.OPEN_GAMES;
      case 'OPEN_MEMORY_GAME':
        return VoiceIntentType.OPEN_MEMORY_GAME;
      case 'OPEN_WORD_RECALL':
        return VoiceIntentType.OPEN_WORD_RECALL;
      case 'OPEN_DIFFERENT_OBJECT':
        return VoiceIntentType.OPEN_DIFFERENT_OBJECT;
      case 'OPEN_REMINDERS':
        return VoiceIntentType.OPEN_REMINDERS;
      case 'READ_NEXT_REMINDER':
        return VoiceIntentType.READ_NEXT_REMINDER;
      case 'OPEN_DAILY_ROUTINE':
        return VoiceIntentType.OPEN_DAILY_ROUTINE;
      case 'OPEN_HELP':
        return VoiceIntentType.OPEN_HELP;
      case 'CALL_CAREGIVER':
        return VoiceIntentType.CALL_CAREGIVER;
      case 'CHANGE_LANGUAGE':
        return VoiceIntentType.CHANGE_LANGUAGE;
      case 'GO_BACK':
        return VoiceIntentType.GO_BACK;
      case 'CANCEL':
        return VoiceIntentType.CANCEL;
      case 'UNKNOWN':
        return VoiceIntentType.unknown;
      default:
        return null;
    }
  }

  static bool _isBenignIntentToken(String clean) {
    return AiContextBuilder.approvedCanonicalIntents.contains(clean);
  }

  static Map<String, dynamic> _buildSafeSlots(
    VoiceIntentType type,
    AiContext context,
  ) {
    switch (type) {
      case VoiceIntentType.OPEN_HOME:
        return const {'targetRoute': '/dashboard'};
      case VoiceIntentType.OPEN_GAMES:
        return const {'targetRoute': '/games'};
      case VoiceIntentType.OPEN_MEMORY_GAME:
        return const {
          'targetRoute': '/games/memory-match',
          'gameId': 'memory-match'
        };
      case VoiceIntentType.OPEN_WORD_RECALL:
        return const {
          'targetRoute': '/games/word-recall',
          'gameId': 'word-recall'
        };
      case VoiceIntentType.OPEN_DIFFERENT_OBJECT:
        return const {
          'targetRoute': '/games/different-object',
          'gameId': 'different-object'
        };
      case VoiceIntentType.OPEN_REMINDERS:
        return const {'targetRoute': '/dashboard'};
      case VoiceIntentType.OPEN_DAILY_ROUTINE:
        return const {'targetRoute': '/games/routine'};
      case VoiceIntentType.OPEN_HELP:
        return const {'targetRoute': '/placeholder/help'};
      case VoiceIntentType.CALL_CAREGIVER:
        return const {'targetRoute': '/caregiver-confirm'};
      case VoiceIntentType.CHANGE_LANGUAGE:
        return const {'targetRoute': '/language-select'};
      default:
        return const {};
    }
  }
}
