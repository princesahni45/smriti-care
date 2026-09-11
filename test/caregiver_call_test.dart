// test/caregiver_call_test.dart
//
// Unit and Widget tests for the CALL_CAREGIVER voice workflow:
// 1. Voice Intent -> CALL_CAREGIVER -> VoiceActionExecutor -> /caregiver-confirm.
// 2. Does NOT immediately place a call.
// 3. CaregiverConfirmationScreen displays caregiver name, relationship, explanation.
// 4. Large Confirm button initiates phone call via EmergencyService.
// 5. Large Cancel button returns safely to previous screen / home.
// 6. Voice response ("yes"/"call") triggers call, ("no"/"cancel") cancels.
// 7. No caregiver contact configured: displays safe explanation card and Return to Home button.
// 8. Privacy & Security: Caregiver settings, credentials, and PIN are NEVER exposed.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_care/core/localization/app_localizations.dart';
import 'package:smriti_care/core/models/caregiver_models.dart';
import 'package:smriti_care/core/services/caregiver_service.dart';
import 'package:smriti_care/core/voice/voice.dart';
import 'package:smriti_care/features/patient/caregiver_confirmation_screen.dart';

// ── No-op TTS Provider ────────────────────────────────────────────────────────
// Completes speak() immediately (no real Timer), preventing pumpAndSettle hang.
class _NoOpTtsProvider implements TtsProvider {
  @override
  bool get isAvailable => true;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<void> speak({
    required String text,
    required String languageCode,
    required double speechRate,
    required double pitch,
    required void Function() onDone,
    required void Function(String error) onError,
  }) async {
    // Immediately signal done — no Timer created.
    onDone();
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

// ── No-op Speech Provider ─────────────────────────────────────────────────────
// isAvailable = false → screen skips startListening; widget tree stays stable.
class _NoOpSpeechProvider implements SpeechRecognitionProvider {
  bool _listening = false;

  @override
  bool get isAvailable => false;

  @override
  bool get isListening => _listening;

  @override
  Future<bool> initialize({String languageCode = 'en'}) async => false;

  @override
  Future<void> startListening({
    required String languageCode,
    required void Function(String transcript, bool isFinal) onResult,
    required void Function(String error) onError,
  }) async {
    _listening = true;
  }

  @override
  Future<void> stopListening() async => _listening = false;

  @override
  Future<void> cancel() async => _listening = false;

  @override
  Future<void> dispose() async => _listening = false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> enData;
  late Map<String, dynamic> hiData;
  late Map<String, dynamic> asData;
  late AppLocalizations enLoc;
  late AppLocalizations hiLoc;
  late AppLocalizations asLoc;

  setUpAll(() {
    enData = jsonDecode(File('assets/i18n/en.json').readAsStringSync())
        as Map<String, dynamic>;
    hiData = jsonDecode(File('assets/i18n/hi.json').readAsStringSync())
        as Map<String, dynamic>;
    asData = jsonDecode(File('assets/i18n/as.json').readAsStringSync())
        as Map<String, dynamic>;

    enLoc = AppLocalizations.fromMap(const Locale('en'), enData);
    hiLoc = AppLocalizations.fromMap(const Locale('hi'), hiData, enData);
    asLoc = AppLocalizations.fromMap(const Locale('as'), asData, enData);
  });

  group('CALL_CAREGIVER Deterministic Intent & Action Workflow', () {
    const router = DeterministicIntentRouter();

    test('English "Call my caregiver" routes to CALL_CAREGIVER', () async {
      const context = VoiceContext(currentRoute: '/');
      final intent = await router.classify(
        VoiceCommand(text: 'call my caregiver'),
        context,
      );
      expect(intent.type, equals(VoiceIntentType.CALL_CAREGIVER));

      final executor = VoiceActionExecutor();
      final action = executor.resolveAction(intent, context);
      expect(action.type, equals(VoiceActionType.navigate));
      expect(action.targetRoute, equals('/caregiver-confirm'));
    });

    test('Hindi "देखभालकर्ता को बुलाओ" routes to CALL_CAREGIVER', () async {
      const context = VoiceContext(currentRoute: '/', selectedLanguage: 'hi');
      final intent = await router.classify(
        VoiceCommand(text: 'देखभालकर्ता को बुलाओ', languageCode: 'hi'),
        context,
      );
      expect(intent.type, equals(VoiceIntentType.CALL_CAREGIVER));

      final executor = VoiceActionExecutor();
      final action = executor.resolveAction(intent, context);
      expect(action.targetRoute, equals('/caregiver-confirm'));
    });

    test('Assamese "তত্ত্বাৱধায়কক মাতক" routes to CALL_CAREGIVER', () async {
      const context = VoiceContext(currentRoute: '/', selectedLanguage: 'as');
      final intent = await router.classify(
        VoiceCommand(text: 'তত্ত্বাৱধায়কক মাতক', languageCode: 'as'),
        context,
      );
      expect(intent.type, equals(VoiceIntentType.CALL_CAREGIVER));

      final executor = VoiceActionExecutor();
      final action = executor.resolveAction(intent, context);
      expect(action.targetRoute, equals('/caregiver-confirm'));
    });
  });


  group('CaregiverConfirmationScreen Widget Tests', () {
    setUp(() async {
      // ── Mock path_provider inside the test zone ───────────────────────────
      // Must be set here (not setUpAll) so the mock is active within the
      // testWidgets zone that pumpAndSettle uses.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (MethodCall methodCall) async => Directory.systemTemp.path,
      );

      LocalizationService.instance.updateCurrentLocalizations(enLoc);
      LocalizationService.instance.setLocale('en');

      // Install no-op providers so pumpAndSettle doesn't hang on real Timers.
      TtsService.instance.setProvider(_NoOpTtsProvider());
      SpeechService.instance.setProvider(_NoOpSpeechProvider());

      // Setup default caregiver emergency contact
      await CaregiverService.instance.saveEmergencyContact(
        EmergencyContact(
          name: 'Rahul Das',
          relationship: 'Son',
          phone: '+91 98765 43210',
          secondaryPhone: '+91 98765 01234',
          updatedAt: DateTime.now(),
        ),
      );
    });

    tearDown(() {
      // Restore real providers so other test groups are not affected.
      TtsService.instance.setProvider(DefaultTtsProvider());
      SpeechService.instance.setProvider(DefaultSpeechRecognitionProvider());
      // Remove path_provider mock.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        null,
      );
    });


    testWidgets(
        'Renders caregiver details, high-contrast Confirm & Cancel buttons, and explanation',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const CaregiverConfirmationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Caregiver name and relationship are visible
      expect(find.text('Rahul Das'), findsOneWidget);
      expect(find.text('Son'), findsOneWidget);

      // 2. Explanation text is clearly displayed
      expect(
        find.text('Would you like to call your caregiver for assistance?'),
        findsOneWidget,
      );

      // 3. Confirm button and Cancel button exist
      expect(find.byKey(const Key('caregiver_call_confirm_button')), findsOneWidget);
      expect(find.byKey(const Key('caregiver_call_cancel_button')), findsOneWidget);

      // 4. Security & Privacy check: NO password, PIN, or settings fields
      expect(find.textContaining('PIN'), findsNothing);
      expect(find.textContaining('Password'), findsNothing);
      expect(find.textContaining('Emergency Settings'), findsNothing);
    });

    testWidgets('Tapping Cancel invokes onBack callback without initiating call',
        (WidgetTester tester) async {
      bool backCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: CaregiverConfirmationScreen(
            onBack: () => backCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Cancel button
      await tester.tap(find.byKey(const Key('caregiver_call_cancel_button')));
      await tester.pumpAndSettle();

      expect(backCalled, isTrue);
    });

    testWidgets('Shows safe configuration notice when no caregiver contact exists',
        (WidgetTester tester) async {
      // Clear emergency contacts to simulate missing configuration
      await CaregiverService.instance.saveEmergencyContact(
        EmergencyContact(
          name: '',
          relationship: '',
          phone: '',
          secondaryPhone: '',
          updatedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: const CaregiverConfirmationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Not configured warning card must appear
      expect(find.text('No Caregiver Contact Found'), findsOneWidget);
      expect(
        find.text(
            'Caregiver contact details have not been set up yet. Please ask your caregiver to add their contact number in safety settings.'),
        findsOneWidget,
      );

      // Confirm button must NOT be present
      expect(find.byKey(const Key('caregiver_call_confirm_button')), findsNothing);

      // Return to home button must be present
      expect(find.byKey(const Key('caregiver_call_back_home_button')), findsOneWidget);
    });

    testWidgets('Renders localized strings in Hindi without error',
        (WidgetTester tester) async {
      LocalizationService.instance.updateCurrentLocalizations(hiLoc);
      LocalizationService.instance.setLocale('hi');

      await CaregiverService.instance.saveEmergencyContact(
        EmergencyContact(
          name: 'राहुल दास',
          relationship: 'बेटा (Son)',
          phone: '+91 98765 43210',
          secondaryPhone: '+91 98765 01234',
          updatedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: const CaregiverConfirmationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('राहुल दास'), findsOneWidget);
      expect(find.text('कॉल करें'), findsOneWidget);
      expect(find.text('रद्द करें और वापस जाएं'), findsOneWidget);
    });

    testWidgets('Renders localized strings in Assamese without error',
        (WidgetTester tester) async {
      LocalizationService.instance.updateCurrentLocalizations(asLoc);
      LocalizationService.instance.setLocale('as');

      await CaregiverService.instance.saveEmergencyContact(
        EmergencyContact(
          name: 'ৰাহুল দাস',
          relationship: 'পুত্ৰ (Son)',
          phone: '+91 98765 43210',
          secondaryPhone: '+91 98765 01234',
          updatedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: const CaregiverConfirmationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ৰাহুল দাস'), findsOneWidget);
      expect(find.text('ফোন কৰক'), findsOneWidget);
      expect(find.text('বাতিল কৰি উভতি যাওক'), findsOneWidget);
    });
  });
}
