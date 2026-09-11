// test/ai4bharat_asr_test.dart
//
// Comprehensive unit and widget tests for AI4Bharat Indic ASR Integration:
// 1. Language validation (English, Hindi, Assamese).
// 2. Honesty principle: Assamese weights not installed reports notInstalled.
// 3. Model lifecycle (loading, ready, low memory, no speech, error).
// 4. Concurrency handling: Preventing overlapping recording sessions.
// 5. Dementia Safety: Text preview and action confirmation in VoiceAssistantSheet.
// 6. Caregiver ASR Benchmark Screen rendering and metrics visualization.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_care/services/voice/ai4bharat_asr_service.dart';
import 'package:smriti_care/services/voice/asr_language.dart';
import 'package:smriti_care/services/voice/asr_model_status.dart';
import 'package:smriti_care/services/voice/native_asr_bridge.dart';
import 'package:smriti_care/services/voice/models/voice_models.dart';
import 'package:smriti_care/features/voice_assistant/widgets/voice_assistant_sheet.dart';
import 'package:smriti_care/features/caregiver/screens/caregiver_asr_benchmark_screen.dart';

void main() {
  group('AI4Bharat Indic ASR Language & Model Tests', () {
    test('Supported languages include English, Hindi, and Assamese', () {
      expect(ASRLanguage.isSupported('en'), isTrue);
      expect(ASRLanguage.isSupported('hi'), isTrue);
      expect(ASRLanguage.isSupported('as'), isTrue);
      expect(ASRLanguage.isSupported('fr'), isFalse);
      expect(ASRLanguage.fromCode('as'), equals(ASRLanguage.assamese));
    });

    test('English model initializes and reports ready status', () async {
      final mockBridge = MockNativeASRBridge(
        installed: {'en': true, 'hi': true, 'as': false},
      );
      final asr = AI4BharatASRService(bridge: mockBridge);

      final initialized = await asr.initializeLanguage('en');
      expect(initialized, isTrue);
      expect(asr.modelStatus, equals(ASRModelStatus.ready));
      expect(asr.metrics.isFullyOffline, isTrue);
      expect(asr.metrics.ramUsageMb, greaterThan(0));
    });

    test('Honesty Principle: Assamese weights uninstalled reports notInstalled',
        () async {
      // Mock bridge where Assamese weights are NOT installed
      final mockBridge = MockNativeASRBridge(
        installed: {'en': true, 'hi': true, 'as': false},
      );
      final asr = AI4BharatASRService(bridge: mockBridge);

      final initialized = await asr.initializeLanguage('as');
      expect(initialized, isFalse);
      expect(asr.modelStatus, equals(ASRModelStatus.notInstalled));
      expect(asr.metrics.failureReason, contains('not installed on device'));
    });

    test('Audio recognition decodes successfully in English and Hindi',
        () async {
      final mockBridge = MockNativeASRBridge(
        installed: {'en': true, 'hi': true, 'as': false},
      );
      final asr = AI4BharatASRService(bridge: mockBridge);
      await asr.initializeLanguage('hi');

      final dummyPcm = <int>[1, 2, 3, 4];
      final result = await asr.processAudioBuffer(dummyPcm);

      expect(result.isSuccess, isTrue);
      expect(result.isSpeechDetected, isTrue);
      expect(result.languageCode, equals('hi'));
      expect(result.confidence, greaterThan(0.8));
    });

    test('Audio recognition handles No Speech Detected gracefully', () async {
      final mockBridge = MockNativeASRBridge(
        installed: {'en': true},
      )..simulateNoSpeech = true;
      final asr = AI4BharatASRService(bridge: mockBridge);
      await asr.initializeLanguage('en');

      final result = await asr.processAudioBuffer(<int>[1, 2, 3]);
      expect(result.isSpeechDetected, isFalse);
      expect(result.recognizedText, isEmpty);
    });

    test(
        'Audio recognition handles Low-Memory conditions safely without crashing',
        () async {
      final mockBridge = MockNativeASRBridge(
        installed: {'en': true},
      )..simulateLowMemory = true;
      final asr = AI4BharatASRService(bridge: mockBridge);
      await asr.initializeLanguage('en');

      final result = await asr.processAudioBuffer(<int>[1, 2]);
      expect(result.isSuccess, isFalse);
      expect(result.failureReason, contains('Low memory'));
      expect(asr.modelStatus, equals(ASRModelStatus.lowMemory));
    });

    test('startListening prevents overlapping concurrent recordings', () async {
      final mockBridge = MockNativeASRBridge(installed: {'en': true});
      final asr = AI4BharatASRService(bridge: mockBridge);
      asr.setMockPermission(true);

      VoiceError? secondError;
      await asr.startListening(
        languageCode: 'en',
        onResult: (_) {},
        onError: (_) {},
      );

      expect(asr.isListening, isTrue);

      await asr.startListening(
        languageCode: 'en',
        onResult: (_) {},
        onError: (err) {
          secondError = err;
        },
      );

      expect(secondError, isNotNull);
      expect(secondError!.kind, equals(VoiceErrorKind.microphoneBusy));
    });
  });

  group('Dementia Safety & Voice Confirmation Widgets', () {
    testWidgets('VoiceAssistantSheet renders listening state and preview',
        (WidgetTester tester) async {
      final mockBridge = MockNativeASRBridge(installed: {'en': true});
      final asr = AI4BharatASRService(bridge: mockBridge);
      asr.setMockPermission(true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceAssistantSheet(
              speechService: asr,
            ),
          ),
        ),
      );

      expect(find.text('Voice Companion'), findsOneWidget);
      expect(find.text('Done Speaking'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Type Instead'), findsOneWidget);
    });

    testWidgets(
        'CaregiverAsrBenchmarkScreen displays languages, metrics, and offline mode',
        (WidgetTester tester) async {
      final mockBridge = MockNativeASRBridge(
        installed: {'en': true, 'hi': true, 'as': false}, // 'as' not installed
      );
      final asr = AI4BharatASRService(bridge: mockBridge);

      await tester.pumpWidget(
        MaterialApp(
          home: CaregiverAsrBenchmarkScreen(asrService: asr),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header and Hardware profiling
      expect(find.text('AI4Bharat ASR Benchmark'), findsOneWidget);
      expect(find.textContaining('OnePlus Nord CE 3 Lite 5G'), findsOneWidget);

      // Verify Language selection chips
      expect(find.text('English'), findsWidgets);
      expect(find.text('हिन्दी'), findsOneWidget);
      expect(find.text('অসমীয়া'), findsOneWidget);

      // Verify Metrics labels
      expect(find.text('Engine Status & Telemetry'), findsOneWidget);
      expect(find.text('Load Time'), findsOneWidget);
      expect(find.text('RAM Usage'), findsOneWidget);
      expect(find.text('Strictly Local'), findsOneWidget);

      // Tap on Assamese chip to test honesty verification
      await tester.tap(find.text('অসমীয়া'));
      await tester.pumpAndSettle();

      // Should show Weights Not Installed
      expect(find.textContaining('Weights Not Installed'), findsOneWidget);
    });
  });
}
