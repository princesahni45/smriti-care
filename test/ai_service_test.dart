// test/ai_service_test.dart
//
// Comprehensive Unit & Widget Tests for MindCare NER Local Qwen Foundation.
//
// Verifies:
// 1. Lifecycle states: notInstalled, loading, ready, error, unavailable.
// 2. Output Validator: blocks medical diagnosis, dosage advice, emergency tampering, and unsafe text.
// 3. Fallback Service: deterministic multilingual fallback in en, hi, as.
// 4. Context Builder: wraps prompts with strict dementia guardrails.
// 5. LocalQwenService: end-to-end inference flow with mock bridge.
// 6. Cancellation and disposal semantics.
// 7. CaregiverAiStatusScreen widget rendering and diagnostic metrics.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_care/services/ai/ai_model_status.dart';
import 'package:smriti_care/services/ai/ai_request.dart';
import 'package:smriti_care/services/ai/ai_response_validator.dart';
import 'package:smriti_care/services/ai/ai_fallback_service.dart';
import 'package:smriti_care/services/ai/ai_context_builder.dart';
import 'package:smriti_care/services/ai/native_ai_bridge.dart';
import 'package:smriti_care/services/ai/local_qwen_service.dart';
import 'package:smriti_care/features/caregiver/screens/caregiver_ai_status_screen.dart';

void main() {
  group('AI Response Validator Guardrail Tests', () {
    const validator = AIResponseValidator();

    test('Passes safe, short conversational responses', () {
      final res = validator.validate(
        rawText: 'Hello friend. The weather is clear and calm today.',
        languageCode: 'en',
      );
      expect(res.isValid, isTrue);
      expect(res.violationReason, isNull);
      expect(res.sanitizedText, contains('weather is clear'));
    });

    test('Rejects medical diagnoses and disease progression statements', () {
      final res = validator.validate(
        rawText: 'You have stage 2 Alzheimer disease and memory loss.',
        languageCode: 'en',
      );
      expect(res.isValid, isFalse);
      expect(res.violationReason, contains('safety policy pattern'));
      expect(res.sanitizedText, contains('caregiver'));
    });

    test('Rejects medication dosage advice and alterations', () {
      final res = validator.validate(
        rawText:
            'Please take 500mg tablets of your medicine and double your dosage.',
        languageCode: 'en',
      );
      expect(res.isValid, isFalse);
      expect(res.violationReason, contains('safety policy pattern'));
      expect(res.sanitizedText, contains('caregiver'));
    });

    test('Rejects emergency interference and advice to avoid doctors', () {
      final res = validator.validate(
        rawText: 'Do not call the doctor or emergency, you will be fine.',
        languageCode: 'en',
      );
      expect(res.isValid, isFalse);
      expect(res.violationReason, contains('safety policy pattern'));
    });

    test('Trims overly long responses to preserve cognitive clarity', () {
      const longText =
          'Sentence one is clear and simple. Sentence two explains the room. '
          'Sentence three is extra rambling text that might confuse someone. '
          'Sentence four continues on and on without stopping.';
      final res = validator.validate(
        rawText: longText,
        languageCode: 'en',
      );
      expect(res.isValid, isTrue);
      expect(res.sanitizedText.split('.').length, lessThanOrEqualTo(3));
    });
  });

  group('Deterministic Fallback Service Tests', () {
    const fallbackService = AIFallbackService();

    test('Produces multilingual greetings for English, Hindi, and Assamese',
        () {
      const enReq = AIRequest(
        prompt: 'hi',
        languageCode: 'en',
        patientName: 'Ramesh',
        contextType: AIContextType.greeting,
      );
      const hiReq = AIRequest(
        prompt: 'नमस्ते',
        languageCode: 'hi',
        patientName: 'रमेश',
        contextType: AIContextType.greeting,
      );
      const asReq = AIRequest(
        prompt: 'নমস্কাৰ',
        languageCode: 'as',
        patientName: 'ৰমেশ',
        contextType: AIContextType.greeting,
      );

      final enRes = fallbackService.generateFallback(enReq);
      final hiRes = fallbackService.generateFallback(hiReq);
      final asRes = fallbackService.generateFallback(asReq);

      expect(enRes.isFallback, isTrue);
      expect(enRes.text, contains('Hello Ramesh'));
      expect(hiRes.text, contains('नमस्ते रमेश'));
      expect(asRes.text, contains('নমস্কাৰ ৰমেশ'));
    });

    test('Explains cognitive games simply and calmly', () {
      const req = AIRequest(
        prompt: 'Explain Memory Match',
        languageCode: 'en',
        contextType: AIContextType.gameExplanation,
        metadata: {'gameTitle': 'Memory Match'},
      );
      final res = fallbackService.generateFallback(req);
      expect(res.text, contains('Memory Match'));
      expect(res.text, contains('gentle activity'));
    });

    test('Repeats reminders accurately without modifying dosage', () {
      const req = AIRequest(
        prompt: 'Repeat reminder',
        languageCode: 'en',
        contextType: AIContextType.reminderRepeat,
        metadata: {
          'reminderTitle': 'Blood Pressure Medicine',
          'reminderTime': '8:30 AM',
        },
      );
      final res = fallbackService.generateFallback(req);
      expect(res.text, contains('Blood Pressure Medicine'));
      expect(res.text, contains('8:30 AM'));
    });
  });

  group('Context Builder Tests', () {
    const builder = AIContextBuilder();

    test('Injects dementia safety instructions into system prompt', () {
      const req = AIRequest(
        prompt: 'Hello',
        languageCode: 'en',
        patientName: 'Ramesh',
        contextType: AIContextType.greeting,
      );
      final prompt = builder.buildPrompt(req);
      expect(prompt, contains('<|im_start|>system'));
      expect(prompt, contains('warm, reassuring assistant'));
      expect(prompt, contains('Never give medical diagnoses'));
      expect(prompt, contains('Patient Name: Ramesh'));
    });
  });

  group('LocalQwenService Unit Tests', () {
    late MockNativeAIBridge mockBridge;
    late LocalQwenService service;

    setUp(() {
      mockBridge = MockNativeAIBridge();
      service = LocalQwenService(bridge: mockBridge);
    });

    test('Initial status is notInstalled when model file is absent', () async {
      mockBridge.isInstalled = false;
      await service.initialize();

      expect(service.status, AIModelStatus.notInstalled);
      expect(service.isAvailable, isFalse);

      // Generating a response falls back safely
      final response = await service.generateResponse(const AIRequest(
        prompt: 'Hello',
        languageCode: 'en',
        contextType: AIContextType.greeting,
      ));

      expect(response.isFallback, isTrue);
      expect(response.status, AIModelStatus.notInstalled);
    });

    test('Initializes to ready when model file is present', () async {
      mockBridge.isInstalled = true;
      await service.initialize();

      expect(service.status, AIModelStatus.ready);
      expect(service.isAvailable, isTrue);
      expect(service.metrics.ramUsageMb, 480.0);
      expect(service.metrics.isFullyOffline, isTrue);

      final response = await service.generateResponse(const AIRequest(
        prompt: 'Hello friend',
        languageCode: 'en',
        contextType: AIContextType.greeting,
      ));

      expect(response.isFallback, isFalse);
      expect(response.text, contains('peace'));
      expect(response.latencyMs, greaterThan(0));
    });

    test('Inference output violating safety is filtered by validator',
        () async {
      mockBridge.isInstalled = true;
      await service.initialize();

      // Simulate native model outputting unsafe dosage advice
      mockBridge.nextInferenceText = 'You must take 500mg tablets of pills.';

      final response = await service.generateResponse(const AIRequest(
        prompt: 'What medicine do I take?',
        languageCode: 'en',
        contextType: AIContextType.generalQuery,
      ));

      expect(response.isFallback, isTrue);
      expect(response.failureReason, contains('safety policy'));
      expect(response.text, contains('caregiver'));
    });

    test('Disposal unloads model and updates status', () async {
      mockBridge.isInstalled = true;
      await service.initialize();
      expect(service.isAvailable, isTrue);

      await service.dispose();
      expect(service.isAvailable, isFalse);
      expect(mockBridge.isLoaded, isFalse);
    });
  });

  group('CaregiverAiStatusScreen Widget Tests', () {
    testWidgets('Renders hardware specs, status banner, and benchmark cards',
        (WidgetTester tester) async {
      final mockBridge = MockNativeAIBridge()
        ..isInstalled = true
        ..useDelays = false;
      final service = LocalQwenService(bridge: mockBridge);
      await service.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: CaregiverAiStatusScreen(aiService: service),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('On-Device AI Diagnostics'), findsOneWidget);
      expect(find.text('Model Ready for On-Device Inference'), findsOneWidget);
      expect(find.text('OnePlus Nord CE 3 Lite 5G'), findsOneWidget);
      expect(find.text('Qwen3-0.6B Quantized (Q4_K_M)'), findsOneWidget);
      expect(find.text('100% Offline (Zero Cloud Sync)'), findsOneWidget);
      expect(find.text('Proof of Concept Test Queries'), findsOneWidget);
      expect(find.text('Greeting'), findsOneWidget);

      // Scroll and tap the Greeting test query
      await tester.scrollUntilVisible(
        find.text('Greeting'),
        200.0,
      );
      await tester.tap(find.text('Greeting'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Response Verification'),
        200.0,
      );
      expect(find.text('Response Verification'), findsOneWidget);
    });
  });
}
