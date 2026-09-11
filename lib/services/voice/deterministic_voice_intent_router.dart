// lib/services/voice/deterministic_voice_intent_router.dart
//
// Deterministic rule-based implementation of VoiceIntentRouter.
//
// Enforces:
// 1. Text normalization.
// 2. Multilingual language detection (English, Hindi, Assamese).
// 3. Medical and operational safety guardrails.
// 4. ASR confidence threshold checks.
// 5. Explicit elderly confirmation flags on sensitive/navigational actions.
// 6. Safe fallbacks for unknown or out-of-scope commands.

import 'voice_intent_router.dart';
import 'text_normalizer.dart';
import 'language_detector.dart';
import 'voice_safety_guard.dart';
import 'patterns/intent_pattern_config.dart';
import 'patterns/intent_patterns_en.dart';
import 'patterns/intent_patterns_hi.dart';
import 'patterns/intent_patterns_as.dart';

class DeterministicVoiceIntentRouter implements VoiceIntentRouter {
  const DeterministicVoiceIntentRouter();

  @override
  Future<VoiceIntentResult> resolveIntent(
    String utterance,
    String languageCode, {
    double asrConfidence = 1.0,
  }) async {
    // 1. Normalize input text
    final normalized = TextNormalizer.normalize(utterance);
    if (normalized.isEmpty) {
      return VoiceIntentResult.unknown(
        normalizedUtterance: '',
        detectedLanguage: languageCode,
        confidence: 0.0,
        safeFallbackMessage:
            'No speech was recognized. Please try speaking again.',
      );
    }

    // 2. Detect language (Hindi, Assamese, or English)
    final detectedLang = LanguageDetector.detectLanguage(
      utterance,
      hintLanguageCode: languageCode,
    );

    // 3. Safety Guard: Check for prohibited commands (dosage changes, PIN modifications, diagnosis)
    final safetyViolation = VoiceSafetyGuard.checkSafetyViolation(normalized);
    if (safetyViolation != null) {
      return VoiceIntentResult.safetyViolation(
        normalizedUtterance: normalized,
        detectedLanguage: detectedLang,
        reason: safetyViolation.userFacingReason,
        safeGuidance: safetyViolation.safeAlternativeGuidance,
      );
    }

    // 4. Safety Guard: Disallow execution on uncertain ASR confidence
    if (!VoiceSafetyGuard.isAsrConfident(asrConfidence)) {
      return VoiceIntentResult.unknown(
        normalizedUtterance: normalized,
        detectedLanguage: detectedLang,
        confidence: asrConfidence,
        safeFallbackMessage:
            'Speech was not clear enough to perform an action. Please repeat or use the screen buttons.',
      );
    }

    // 5. Safety Guard: Medicine marked as taken requires explicit confirmation
    if (VoiceSafetyGuard.requiresMedicineTakenConfirmation(normalized)) {
      return VoiceIntentResult(
        type: VoiceIntentType.showTodayReminders,
        confidence: asrConfidence,
        normalizedUtterance: normalized,
        detectedLanguage: detectedLang,
        requiresConfirmation: true,
        confirmationPrompt: detectedLang == 'hi'
            ? 'क्या आप पुष्टि करते हैं कि आपने अपनी दवाई ले ली है?'
            : detectedLang == 'as'
                ? 'আপুনি নিশ্চিত নে যে আপুনি ঔষধ খালে?'
                : 'Please confirm: Did you take your scheduled medication?',
        actionRoute: '/reminders',
        parameters: const {'subAction': 'markMedicineTaken'},
      );
    }

    // 6. Match against language patterns
    final primaryPatterns = _getPatternsForLanguage(detectedLang);
    final match = _matchPatterns(normalized, primaryPatterns);

    if (match != null) {
      return VoiceIntentResult(
        type: match.type,
        confidence: asrConfidence,
        normalizedUtterance: normalized,
        detectedLanguage: detectedLang,
        requiresConfirmation: match.requiresConfirmation,
        confirmationPrompt: match.confirmationPrompt,
        actionRoute: match.actionRoute,
        parameters: {'feedback': match.executionFeedback},
      );
    }

    // 7. Fallback check against English patterns (handles transliteration or code-switching)
    if (detectedLang != 'en') {
      final fallbackMatch = _matchPatterns(normalized, englishIntentPatterns);
      if (fallbackMatch != null) {
        return VoiceIntentResult(
          type: fallbackMatch.type,
          confidence: asrConfidence,
          normalizedUtterance: normalized,
          detectedLanguage: detectedLang,
          requiresConfirmation: fallbackMatch.requiresConfirmation,
          confirmationPrompt: fallbackMatch.confirmationPrompt,
          actionRoute: fallbackMatch.actionRoute,
          parameters: {'feedback': fallbackMatch.executionFeedback},
        );
      }
    }

    // 8. Unknown command fallback
    return VoiceIntentResult.unknown(
      normalizedUtterance: normalized,
      detectedLanguage: detectedLang,
      confidence: asrConfidence,
      safeFallbackMessage: detectedLang == 'hi'
          ? 'यह आदेश समझ नहीं आया। आप कह सकते हैं: खेल खोलो, रिमाइंडर दिखाओ, या मदद।'
          : detectedLang == 'as'
              ? 'কথাষাৰ বুজিব পৰা নহ’ল। আপুনি ক’ব পাৰে: খেল খোলক, ৰিমাইণ্ডাৰ দেখুৱাওক, বা সহায়।'
              : 'I could not understand that request. You can say: Open Games, Show Reminders, or Help.',
    );
  }

  List<IntentPatternDefinition> _getPatternsForLanguage(String lang) {
    switch (lang) {
      case 'hi':
        return hindiIntentPatterns;
      case 'as':
        return assameseIntentPatterns;
      case 'en':
      default:
        return englishIntentPatterns;
    }
  }

  IntentPatternDefinition? _matchPatterns(
    String normalizedText,
    List<IntentPatternDefinition> patterns,
  ) {
    for (final pattern in patterns) {
      if (pattern.matches(normalizedText)) {
        return pattern;
      }
    }
    return null;
  }
}
