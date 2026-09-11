// test/tts_service_test.dart
//
// Comprehensive unit and widget test suite for TextToSpeechService:
// 1. Language support detection (English, Hindi, Assamese).
// 2. Honesty principle: Assamese voice not installed reports notAvailable without silent translation.
// 3. Playback lifecycle: speak, stop, pause, resume, and rate configuration.
// 4. Dementia safety: Slower default speech rate (0.75x).
// 5. Dementia safety: Medication dosage instructions are strictly blocked.
// 6. Dementia safety: Sensitive patient health info blocked on unsecured screen.
// 7. DementiaVoiceNarrationBar widget rendering, large replay button, and text fallback.
// 8. CaregiverTtsDiagnosticsScreen widget tests across English, Hindi, and Assamese.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_care/services/tts/local_text_to_speech_service.dart';
import 'package:smriti_care/services/tts/tts_models.dart';
import 'package:smriti_care/services/tts/native_tts_bridge.dart';
import 'package:smriti_care/shared/widgets/dementia_voice_narration_bar.dart';
import 'package:smriti_care/features/caregiver/screens/caregiver_tts_diagnostics_screen.dart';

void main() {
  group('TextToSpeechService Core & Offline Language Support Tests', () {
    test('Initializes with slower elderly cadence rate (0.75x)', () async {
      final mockBridge = MockNativeTTSBridge();
      final tts = LocalTextToSpeechService(bridge: mockBridge);

      await tts.initialize();
      expect(tts.isReady, isTrue);
      expect(tts.currentRate, equals(0.75));
    });

    test('English and Hindi are detected as working offline voices', () async {
      final mockBridge = MockNativeTTSBridge(
        supported: {'en': true, 'hi': true, 'as': false},
      );
      final tts = LocalTextToSpeechService(bridge: mockBridge);

      final enSupport = await tts.checkLanguageSupport('en');
      expect(enSupport.isWorking, isTrue);
      expect(enSupport.offlineCapable, isTrue);
      expect(enSupport.selectedVoice, isNotNull);

      final hiSupport = await tts.checkLanguageSupport('hi');
      expect(hiSupport.isWorking, isTrue);
      expect(hiSupport.offlineCapable, isTrue);
    });

    test(
        'Honesty Principle: Assamese missing voice reports notAvailable without translation',
        () async {
      // Mock bridge where Assamese voice is missing on device
      final mockBridge = MockNativeTTSBridge(
        supported: {'en': true, 'hi': true, 'as': false},
      );
      final tts = LocalTextToSpeechService(bridge: mockBridge);

      final asSupport = await tts.checkLanguageSupport('as');
      expect(asSupport.status, equals(TTSLanguageSupportStatus.notAvailable));
      expect(asSupport.availableVoicesCount, equals(0));
      expect(asSupport.details,
          contains('Assamese voice engine is not installed'));

      // Attempting to speak Assamese without voice returns false (not silently translating)
      final speakSuccess = await tts.speak(
        text: 'নমস্কাৰ, আপুনি কেনে আছে?',
        languageCode: 'as',
      );
      expect(speakSuccess, isFalse);
    });

    test('Speak, pause, resume, and stop controls update playback state',
        () async {
      final mockBridge = MockNativeTTSBridge();
      final tts = LocalTextToSpeechService(bridge: mockBridge);

      final ok = await tts.speak(
        text: 'Take a gentle breath.',
        languageCode: 'en',
      );
      expect(ok, isTrue);
      expect(tts.isSpeaking, isTrue);
      expect(tts.lastSpokenText, equals('Take a gentle breath.'));

      await tts.pause();
      expect(tts.isSpeaking, isFalse);
      expect(tts.isPaused, isTrue);

      await tts.resume();
      expect(tts.isSpeaking, isTrue);
      expect(tts.isPaused, isFalse);

      await tts.stop();
      expect(tts.isSpeaking, isFalse);
      expect(tts.isPaused, isFalse);
    });

    test('Replay function repeats last spoken utterance', () async {
      final mockBridge = MockNativeTTSBridge();
      final tts = LocalTextToSpeechService(bridge: mockBridge);

      await tts.speak(
        text: 'It is time for breakfast.',
        languageCode: 'en',
      );

      await tts.stop();
      expect(tts.isSpeaking, isFalse);

      final replayed = await tts.replay();
      expect(replayed, isTrue);
      expect(tts.isSpeaking, isTrue);
      expect(
          mockBridge.lastSpokenUtterance, equals('It is time for breakfast.'));
    });

    test('Speech rate is clamped safely between 0.5 and 1.0', () async {
      final mockBridge = MockNativeTTSBridge();
      final tts = LocalTextToSpeechService(bridge: mockBridge);

      await tts.setSpeechRate(0.3); // Below min
      expect(tts.currentRate, equals(0.5));

      await tts.setSpeechRate(1.5); // Above max
      expect(tts.currentRate, equals(1.0));

      await tts.setSpeechRate(0.8);
      expect(tts.currentRate, equals(0.8));
    });
  });

  group('Dementia Safety Guardrails Tests', () {
    test(
        'Throws TTSSafetyViolationException when text contains medication dosage',
        () async {
      final mockBridge = MockNativeTTSBridge();
      final tts = LocalTextToSpeechService(bridge: mockBridge);

      // Attempt dosage modification speech
      expect(
        () => tts.speak(
          text: 'You should take 50mg of Atenolol now.',
          languageCode: 'en',
        ),
        throwsA(isA<TTSSafetyViolationException>()),
      );

      expect(
        () => tts.speak(
          text: 'Please skip your pills today.',
          languageCode: 'en',
        ),
        throwsA(isA<TTSSafetyViolationException>()),
      );
    });

    test(
        'Throws TTSSafetyViolationException when sensitive patient info spoken on unsecured screen',
        () async {
      final mockBridge = MockNativeTTSBridge();
      final tts = LocalTextToSpeechService(bridge: mockBridge);

      expect(
        () => tts.speak(
          text: 'Patient was diagnosed with clinical conditions.',
          languageCode: 'en',
          isSecuredContext: false, // Unsecured context
        ),
        throwsA(isA<TTSSafetyViolationException>()),
      );
    });
  });

  group('DementiaVoiceNarrationBar & Caregiver Diagnostics Widget Tests', () {
    testWidgets(
        'DementiaVoiceNarrationBar renders replay button and text fallback',
        (WidgetTester tester) async {
      final mockBridge = MockNativeTTSBridge();
      final tts = LocalTextToSpeechService(bridge: mockBridge);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DementiaVoiceNarrationBar(
              textToNarrate: 'Welcome to your daily memory exercises.',
              languageCode: 'en',
              ttsService: tts,
            ),
          ),
        ),
      );

      expect(find.text('Spoken Assistant'), findsOneWidget);
      expect(find.text('Calm Pace: 0.75x'), findsOneWidget);
      expect(
          find.text('Welcome to your daily memory exercises.'), findsOneWidget);
      expect(find.text('Listen Again'), findsOneWidget);
      expect(find.text('Pause'), findsOneWidget);

      // Tap Listen Again
      await tester.tap(find.text('Listen Again'));
      await tester.pump();

      expect(tts.isSpeaking, isTrue);
    });

    testWidgets(
        'CaregiverTtsDiagnosticsScreen tests English, Hindi, and Assamese',
        (WidgetTester tester) async {
      final mockBridge = MockNativeTTSBridge(
        supported: {'en': true, 'hi': true, 'as': false},
      );
      final tts = LocalTextToSpeechService(bridge: mockBridge);

      await tester.pumpWidget(
        MaterialApp(
          home: CaregiverTtsDiagnosticsScreen(ttsService: tts),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('On-Device TTS Diagnostics'), findsOneWidget);
      expect(find.textContaining('Zero Cloud Transmission'), findsOneWidget);

      // Verify language options
      expect(find.text('English'), findsWidgets);
      expect(find.text('Hindi'), findsWidgets);
      expect(find.text('Assamese'), findsWidgets);

      // Tap Assamese
      await tester.tap(find.text('অসমীয়া'));
      await tester.pumpAndSettle();

      // Assamese should show Not Available
      expect(find.textContaining('Not Available'), findsOneWidget);

      // Scroll to and test Safety Guardrail button
      final guardrailBtn = find.text('Test Medication Dosage Interception');
      await tester.ensureVisible(guardrailBtn);
      await tester.tap(guardrailBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('SAFETY GUARDRAIL ACTIVE'), findsOneWidget);
    });
  });
}
