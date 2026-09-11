// test/voice_foundation_test.dart
//
// Comprehensive unit and widget tests for SmritiCare Voice Subsystem Foundation.
// Verifies:
// 1. VoiceState transitions (idle -> listening -> processing -> idle).
// 2. Microphone permission handling (granted, denied, permanently denied).
// 3. Concurrency prevention: multiple simultaneous recordings are blocked.
// 4. Start, stop, cancel, and retry operations.
// 5. TextToSpeechService speak, rate control, and stop controls.
// 6. VoiceAssistantSheet interactive UI, visible listening indicator, and text fallback.
// 7. Deterministic safety routing for emergency, navigation, and reminders.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_care/services/voice/models/voice_models.dart';
import 'package:smriti_care/services/voice/placeholder_speech_recognition_service.dart';
import 'package:smriti_care/services/tts/placeholder_tts_service.dart';
import 'package:smriti_care/services/voice/deterministic_voice_intent_router.dart';
import 'package:smriti_care/services/voice/voice_intent_router.dart';
import 'package:smriti_care/features/voice_assistant/widgets/voice_assistant_sheet.dart';

void main() {
  group('Voice Foundation Unit Tests', () {
    late PlaceholderSpeechRecognitionService speechService;
    late PlaceholderTextToSpeechService ttsService;
    late DeterministicVoiceIntentRouter router;

    setUp(() {
      speechService = PlaceholderSpeechRecognitionService();
      ttsService = PlaceholderTextToSpeechService();
      router = const DeterministicVoiceIntentRouter();
    });

    test('Initial state is idle and available', () {
      expect(speechService.state, VoiceState.idle);
      expect(speechService.isAvailable, isTrue);
      expect(speechService.isListening, isFalse);
    });

    test('Start listening transitions state to listening', () async {
      await speechService.startListening(
        languageCode: 'en',
        onResult: (_) {},
        onError: (_) {},
      );

      expect(speechService.state, VoiceState.listening);
      expect(speechService.isListening, isTrue);

      await speechService.stopListening();
      expect(speechService.state, VoiceState.idle);
    });

    test('Prevents multiple simultaneous recordings (concurrency lock)',
        () async {
      VoiceError? caughtError;

      // Start first session
      await speechService.startListening(
        languageCode: 'en',
        onResult: (_) {},
        onError: (_) {},
      );

      // Attempt second session while first is active
      await speechService.startListening(
        languageCode: 'en',
        onResult: (_) {},
        onError: (err) => caughtError = err,
      );

      expect(caughtError, isNotNull);
      expect(caughtError!.kind, VoiceErrorKind.microphoneBusy);
    });

    test('Handles permission denied gracefully with elderly-friendly message',
        () async {
      VoiceError? caughtError;
      speechService.setMockPermission(false);

      await speechService.startListening(
        languageCode: 'en',
        onResult: (_) {},
        onError: (err) => caughtError = err,
      );

      expect(caughtError, isNotNull);
      expect(caughtError!.kind, VoiceErrorKind.permissionDenied);
      expect(caughtError!.userFacingMessage,
          contains('Microphone permission is required'));
    });

    test('Handles permission permanently denied with caregiver prompt',
        () async {
      VoiceError? caughtError;
      speechService.setMockPermission(false, permanent: true);

      await speechService.startListening(
        languageCode: 'en',
        onResult: (_) {},
        onError: (err) => caughtError = err,
      );

      expect(caughtError, isNotNull);
      expect(caughtError!.kind, VoiceErrorKind.permissionPermanentlyDenied);
      expect(
          caughtError!.userFacingMessage, contains('caregiver to enable it'));
    });

    test('Cancel operation resets state immediately to idle', () async {
      await speechService.startListening(
        languageCode: 'en',
        onResult: (_) {},
        onError: (_) {},
      );
      expect(speechService.isListening, isTrue);

      await speechService.cancelListening();
      expect(speechService.state, VoiceState.idle);
      expect(speechService.isListening, isFalse);
    });

    test('Retry operation restarts active session', () async {
      await speechService.startListening(
        languageCode: 'en',
        onResult: (_) {},
        onError: (_) {},
      );

      await speechService.retryListening(
        languageCode: 'en',
        onResult: (_) {},
        onError: (_) {},
      );

      expect(speechService.isListening, isTrue);
      await speechService.stopListening();
    });

    test(
        'Assamese speech recognition gracefully informs user without false claims',
        () async {
      VoiceError? caughtError;

      await speechService.startListening(
        languageCode: 'as',
        onResult: (_) {},
        onError: (err) => caughtError = err,
      );

      await Future.delayed(const Duration(milliseconds: 150));
      expect(caughtError, isNotNull);
      expect(caughtError!.kind, VoiceErrorKind.serviceUnavailable);
      expect(caughtError!.userFacingMessage,
          contains('Assamese voice recognition is planned'));
    });

    test('TextToSpeechService speak and stop controls work correctly',
        () async {
      expect(ttsService.isSpeaking, isFalse);

      final speakFuture = ttsService.speak(
        text: 'Take your morning medicine',
        languageCode: 'en',
        rate: 0.85,
      );

      expect(ttsService.isSpeaking, isTrue);
      await ttsService.stop();
      expect(ttsService.isSpeaking, isFalse);

      await speakFuture;
    });

    test(
        'DeterministicVoiceIntentRouter prioritizes safety and routine keywords',
        () async {
      // Emergency / Caregiver Help keywords (English, Hindi, Assamese)
      final res1 = await router.resolveIntent('Help me please', 'en');
      expect(res1.type, VoiceIntentType.openCaregiverHelp);

      final res2 = await router.resolveIntent('Meri madad karo', 'hi');
      expect(res2.type, VoiceIntentType.openCaregiverHelp);

      final res3 = await router.resolveIntent('Mok sahay korok', 'as');
      expect(res3.type, VoiceIntentType.openCaregiverHelp);

      // Home navigation
      final res4 = await router.resolveIntent('Take me home', 'en');
      expect(res4.type, VoiceIntentType.goHome);

      final res5 = await router.resolveIntent('Ghar jao', 'hi');
      expect(res5.type, VoiceIntentType.goHome);

      // Reminders
      final res6 =
          await router.resolveIntent('Show my medicine reminder', 'en');
      expect(res6.type, VoiceIntentType.showTodayReminders);
    });
  });

  group('VoiceAssistantSheet Widget Tests', () {
    testWidgets('Renders listening orb, instructions, and text fallback button',
        (WidgetTester tester) async {
      final speechService = PlaceholderSpeechRecognitionService();
      final ttsService = PlaceholderTextToSpeechService();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceAssistantSheet(
              speechService: speechService,
              ttsService: ttsService,
            ),
          ),
        ),
      );

      // Verify header and listening prompt
      expect(find.text('Voice Companion'), findsOneWidget);
      expect(find.text('Listening... please speak calmly.'), findsOneWidget);
      expect(find.text('Done Speaking'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Type Instead'), findsOneWidget);

      // Switch to text fallback
      await tester.tap(find.text('Type Instead'));
      await tester.pumpAndSettle();

      expect(find.text('Type your question or request:'), findsOneWidget);
      expect(find.text('Ask'), findsOneWidget);
      expect(find.text('Use Voice'), findsOneWidget);
    });
  });
}
