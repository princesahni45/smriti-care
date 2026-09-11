// test/voice_intent_router_test.dart
//
// Comprehensive unit tests for DeterministicVoiceIntentRouter.
// Validates:
// 1. All 10 safe intents in English (en).
// 2. All 10 safe intents in Hindi (hi).
// 3. All 10 safe intents in Assamese (as).
// 4. Prohibited medicine dosage alteration protection.
// 5. Prohibited caregiver PIN change protection.
// 6. Prohibited clinical/medical diagnosis protection.
// 7. Medicine taken confirmation requirement.
// 8. Low ASR confidence threshold (<0.60) rejection.
// 9. Text normalization and on-device language detection.

import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_care/services/voice/voice_intent_router.dart';
import 'package:smriti_care/services/voice/deterministic_voice_intent_router.dart';
import 'package:smriti_care/services/voice/text_normalizer.dart';
import 'package:smriti_care/services/voice/language_detector.dart';

void main() {
  const router = DeterministicVoiceIntentRouter();

  group('TextNormalizer & LanguageDetector Tests', () {
    test(
        'Normalizes text by removing punctuation, collapsing spaces, and lowercasing',
        () {
      expect(TextNormalizer.normalize('  Open,  Games!?? '), 'open games');
      expect(TextNormalizer.normalize('खेल, खोलो।'), 'खेल खोलो');
      expect(TextNormalizer.normalize('খেল... খোলক!'), 'খেল খোলক');
    });

    test('Detects language correctly based on Unicode script', () {
      expect(LanguageDetector.detectLanguage('Open games'), 'en');
      expect(LanguageDetector.detectLanguage('खेल खोलो'), 'hi');
      expect(LanguageDetector.detectLanguage('খেল খোলক'), 'as');
      expect(
          LanguageDetector.detectLanguage('khel kholo', hintLanguageCode: 'hi'),
          'hi');
      expect(
          LanguageDetector.detectLanguage('khel kholok',
              hintLanguageCode: 'as'),
          'as');
    });
  });

  group('English Intent Classification (10 Intents)', () {
    test('1. openGames', () async {
      final res = await router.resolveIntent('Open games please', 'en');
      expect(res.type, VoiceIntentType.openGames);
      expect(res.actionRoute, '/games');
    });

    test('2. startMemoryGame', () async {
      final res = await router.resolveIntent('Start memory game', 'en');
      expect(res.type, VoiceIntentType.startMemoryGame);
      expect(res.actionRoute, '/games/memory-match');
    });

    test('3. showTodayReminders', () async {
      final res = await router.resolveIntent('Show today reminders', 'en');
      expect(res.type, VoiceIntentType.showTodayReminders);
      expect(res.actionRoute, '/reminders');
    });

    test('4. readNextReminder', () async {
      final res = await router.resolveIntent('What is my next reminder', 'en');
      expect(res.type, VoiceIntentType.readNextReminder);
    });

    test('5. repeatInstruction', () async {
      final res = await router.resolveIntent('Repeat instruction again', 'en');
      expect(res.type, VoiceIntentType.repeatInstruction);
    });

    test('6. openCaregiverHelp', () async {
      final res =
          await router.resolveIntent('Call caregiver, I need help', 'en');
      expect(res.type, VoiceIntentType.openCaregiverHelp);
      expect(res.requiresConfirmation, isTrue);
    });

    test('7. openSettings', () async {
      final res = await router.resolveIntent('Open app settings', 'en');
      expect(res.type, VoiceIntentType.openSettings);
      expect(res.actionRoute, '/settings');
    });

    test('8. goHome', () async {
      final res = await router.resolveIntent('Take me home', 'en');
      expect(res.type, VoiceIntentType.goHome);
      expect(res.requiresConfirmation, isTrue);
    });

    test('9. cancel', () async {
      final res = await router.resolveIntent('Cancel and close', 'en');
      expect(res.type, VoiceIntentType.cancel);
      expect(res.requiresConfirmation, isTrue);
    });

    test('10. unknown', () async {
      final res = await router.resolveIntent(
          'Play some jazz music from the 1970s', 'en');
      expect(res.type, VoiceIntentType.unknown);
      expect(res.safeFallbackMessage, isNotNull);
    });
  });

  group('Hindi Intent Classification (10 Intents)', () {
    test('1. openGames', () async {
      final res = await router.resolveIntent('दिमागी खेल खोलो', 'hi');
      expect(res.type, VoiceIntentType.openGames);
      expect(res.actionRoute, '/games');
    });

    test('2. startMemoryGame', () async {
      final res = await router.resolveIntent('मेमोरी गेम शुरू करो', 'hi');
      expect(res.type, VoiceIntentType.startMemoryGame);
      expect(res.actionRoute, '/games/memory-match');
    });

    test('3. showTodayReminders', () async {
      final res = await router.resolveIntent('आज के रिमाइंडर दिखाओ', 'hi');
      expect(res.type, VoiceIntentType.showTodayReminders);
      expect(res.actionRoute, '/reminders');
    });

    test('4. readNextReminder', () async {
      final res = await router.resolveIntent('अगला रिमाइंडर पढ़ो', 'hi');
      expect(res.type, VoiceIntentType.readNextReminder);
    });

    test('5. repeatInstruction', () async {
      final res = await router.resolveIntent('फिर से बोलो', 'hi');
      expect(res.type, VoiceIntentType.repeatInstruction);
    });

    test('6. openCaregiverHelp', () async {
      final res = await router.resolveIntent(
          'देखभालकर्ता को बुलाओ मुझे मदद चाहिए', 'hi');
      expect(res.type, VoiceIntentType.openCaregiverHelp);
      expect(res.requiresConfirmation, isTrue);
    });

    test('7. openSettings', () async {
      final res = await router.resolveIntent('सेटिंग्स खोलो', 'hi');
      expect(res.type, VoiceIntentType.openSettings);
      expect(res.actionRoute, '/settings');
    });

    test('8. goHome', () async {
      final res = await router.resolveIntent('घर जाओ', 'hi');
      expect(res.type, VoiceIntentType.goHome);
      expect(res.requiresConfirmation, isTrue);
    });

    test('9. cancel', () async {
      final res = await router.resolveIntent('रद्द करो', 'hi');
      expect(res.type, VoiceIntentType.cancel);
      expect(res.requiresConfirmation, isTrue);
    });

    test('10. unknown', () async {
      final res = await router.resolveIntent('कल मौसम कैसा रहेगा', 'hi');
      expect(res.type, VoiceIntentType.unknown);
      expect(res.safeFallbackMessage, contains('यह आदेश समझ नहीं आया'));
    });
  });

  group('Assamese Intent Classification (10 Intents)', () {
    test('1. openGames', () async {
      final res = await router.resolveIntent('খেল খোলক', 'as');
      expect(res.type, VoiceIntentType.openGames);
      expect(res.actionRoute, '/games');
    });

    test('2. startMemoryGame', () async {
      final res = await router.resolveIntent('মেমৰি খেল আৰম্ভ কৰক', 'as');
      expect(res.type, VoiceIntentType.startMemoryGame);
      expect(res.actionRoute, '/games/memory-match');
    });

    test('3. showTodayReminders', () async {
      final res = await router.resolveIntent('আজিৰ ৰিমাইণ্ডাৰ দেখুৱাওক', 'as');
      expect(res.type, VoiceIntentType.showTodayReminders);
      expect(res.actionRoute, '/reminders');
    });

    test('4. readNextReminder', () async {
      final res = await router.resolveIntent('পৰৱৰ্তী ৰিমাইণ্ডাৰ পঢ়ক', 'as');
      expect(res.type, VoiceIntentType.readNextReminder);
    });

    test('5. repeatInstruction', () async {
      final res = await router.resolveIntent('আকৌ কওক', 'as');
      expect(res.type, VoiceIntentType.repeatInstruction);
    });

    test('6. openCaregiverHelp', () async {
      final res =
          await router.resolveIntent('কেয়াৰগিভাৰক মাটক সহায় লাগে', 'as');
      expect(res.type, VoiceIntentType.openCaregiverHelp);
      expect(res.requiresConfirmation, isTrue);
    });

    test('7. openSettings', () async {
      final res = await router.resolveIntent('ছেটিংছ খোলক', 'as');
      expect(res.type, VoiceIntentType.openSettings);
      expect(res.actionRoute, '/settings');
    });

    test('8. goHome', () async {
      final res = await router.resolveIntent('ঘৰলৈ যাওক', 'as');
      expect(res.type, VoiceIntentType.goHome);
      expect(res.requiresConfirmation, isTrue);
    });

    test('9. cancel', () async {
      final res = await router.resolveIntent('বাতিল কৰক', 'as');
      expect(res.type, VoiceIntentType.cancel);
      expect(res.requiresConfirmation, isTrue);
    });

    test('10. unknown', () async {
      final res = await router.resolveIntent('বজাৰলৈ যাব লাগে', 'as');
      expect(res.type, VoiceIntentType.unknown);
      expect(res.safeFallbackMessage, contains('কথাষাৰ বুজিব পৰা নহ’ল'));
    });
  });

  group('Dementia Safety Guardrails & Prohibited Actions', () {
    test('Blocks medicine dosage modification attempts in English', () async {
      final res = await router.resolveIntent('Change my dose to 20mg', 'en');
      expect(res.isSafetyViolation, isTrue);
      expect(res.type, VoiceIntentType.unknown);
      expect(res.safetyViolationReason, contains('medication dosages'));
    });

    test('Blocks medicine dosage modification attempts in Hindi', () async {
      final res = await router.resolveIntent('दवाई की खुराक बदलो', 'hi');
      expect(res.isSafetyViolation, isTrue);
      expect(res.type, VoiceIntentType.unknown);
      expect(res.safetyViolationReason, contains('medication dosages'));
    });

    test('Blocks medicine dosage modification attempts in Assamese', () async {
      final res = await router.resolveIntent('ঔষধৰ মাত্ৰা সলনি কৰক', 'as');
      expect(res.isSafetyViolation, isTrue);
      expect(res.type, VoiceIntentType.unknown);
      expect(res.safetyViolationReason, contains('medication dosages'));
    });

    test('Blocks caregiver PIN modification in English, Hindi, and Assamese',
        () async {
      final resEn =
          await router.resolveIntent('Change the caregiver pin to 4321', 'en');
      expect(resEn.isSafetyViolation, isTrue);
      expect(resEn.safetyViolationReason, contains('Caregiver PIN'));

      final resHi = await router.resolveIntent('पिन बदलो', 'hi');
      expect(resHi.isSafetyViolation, isTrue);
      expect(resHi.safetyViolationReason, contains('Caregiver PIN'));

      final resAs = await router.resolveIntent('পিন সলনি কৰক', 'as');
      expect(resAs.isSafetyViolation, isTrue);
      expect(resAs.safetyViolationReason, contains('Caregiver PIN'));
    });

    test('Blocks clinical medical diagnosis queries', () async {
      final res =
          await router.resolveIntent('Do I have Alzheimer disease?', 'en');
      expect(res.isSafetyViolation, isTrue);
      expect(res.safetyViolationReason, contains('clinical diagnoses'));
      expect(res.safeFallbackMessage, contains('Dr. Ananya Bora'));
    });

    test('Medicine taken requires explicit confirmation before marking',
        () async {
      final res = await router.resolveIntent('I took my medicine', 'en');
      expect(res.type, VoiceIntentType.showTodayReminders);
      expect(res.requiresConfirmation, isTrue);
      expect(res.parameters['subAction'], 'markMedicineTaken');
      expect(res.confirmationPrompt,
          contains('Did you take your scheduled medication?'));
    });

    test('Rejects execution when ASR confidence is below threshold (<0.60)',
        () async {
      final res =
          await router.resolveIntent('Open games', 'en', asrConfidence: 0.45);
      expect(res.type, VoiceIntentType.unknown);
      expect(res.confidence, 0.45);
      expect(res.safeFallbackMessage, contains('not clear enough'));
    });
  });
}
