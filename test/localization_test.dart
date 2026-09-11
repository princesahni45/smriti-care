// test/localization_test.dart
//
// Unit tests for SmritiCare Multilingual Localization Engine.
// Verifies:
// 1. All 10 language JSON files are valid and contain core sections
// 2. All 10 SupportedLanguage definitions match supportedLocales
// 3. Fallback to English when keys are missing
// 4. LocalizationService updates currentLocaleNotifier reactive state

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_care/core/localization/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const expectedLanguageCodes = [
    'en', // English
    'hi', // Hindi
    'as', // Assamese
    'bn', // Bengali
    'mni', // Manipuri (Meitei)
    'kha', // Khasi
    'lus', // Mizo
    'grt', // Garo
    'brx', // Bodo
    'trp', // Kokborok
  ];

  group('Localization Files & Completeness Tests', () {
    test('All 10 language codes are registered in supportedLocales', () {
      final supportedCodes =
          AppLocalizations.supportedLocales.map((l) => l.languageCode).toList();
      for (final code in expectedLanguageCodes) {
        expect(supportedCodes.contains(code), isTrue,
            reason: 'Locale $code should be in supportedLocales');
      }
      expect(AppLocalizations.supportedLocales.length, 10);
      expect(AppLocalizations.supportedLanguages.length, 10);
    });

    test(
        'All 10 translation JSON files exist, parse cleanly, and have core keys',
        () {
      for (final code in expectedLanguageCodes) {
        final file = File('assets/i18n/$code.json');
        expect(file.existsSync(), isTrue,
            reason: 'File assets/i18n/$code.json must exist');

        final content = file.readAsStringSync();
        expect(content.isNotEmpty, isTrue);

        final Map<String, dynamic> data = jsonDecode(content);
        expect(data, isNotEmpty, reason: '$code.json must not be empty');

        // Check essential top-level sections
        expect(data.containsKey('common'), isTrue,
            reason: '$code.json must have "common" section');
        expect(data.containsKey('auth'), isTrue,
            reason: '$code.json must have "auth" section');
        expect(data.containsKey('patient'), isTrue,
            reason: '$code.json must have "patient" section');
        expect(data.containsKey('caregiver'), isTrue,
            reason: '$code.json must have "caregiver" section');
        expect(data.containsKey('sos'), isTrue,
            reason: '$code.json must have "sos" section');

        // Check common words
        final common = data['common'] as Map<String, dynamic>;
        expect(common.containsKey('home'), isTrue,
            reason: '$code.json common must have "home"');
        expect(common.containsKey('save'), isTrue,
            reason: '$code.json common must have "save"');
        expect(common.containsKey('cancel'), isTrue,
            reason: '$code.json common must have "cancel"');
      }
    });

    test('LocalizationService switches active locale and notifies listeners',
        () {
      final service = LocalizationService.instance;
      service.setLocale('hi');
      expect(service.currentLocale.languageCode, 'hi');

      service.setLocale('as');
      expect(service.currentLocale.languageCode, 'as');

      service.setLocale('bn');
      expect(service.currentLocale.languageCode, 'bn');

      service.setLocale('mni');
      expect(service.currentLocale.languageCode, 'mni');

      service.setLocale('kha');
      expect(service.currentLocale.languageCode, 'kha');

      service.setLocale('lus');
      expect(service.currentLocale.languageCode, 'lus');

      service.setLocale('grt');
      expect(service.currentLocale.languageCode, 'grt');

      service.setLocale('brx');
      expect(service.currentLocale.languageCode, 'brx');

      service.setLocale('trp');
      expect(service.currentLocale.languageCode, 'trp');

      // Reset back to English
      service.setLocale('en');
      expect(service.currentLocale.languageCode, 'en');
    });

    test('Unsupported language code is safely ignored', () {
      final service = LocalizationService.instance;
      service.setLocale('en');
      service.setLocale('xyz_unsupported');
      expect(service.currentLocale.languageCode, 'en');
    });

    // FIX: MaterialLocalizations / localization configuration fix
    // Verify BottomNavigationBar and Material widgets find MaterialLocalizations across all 10 locales
    testWidgets(
        'BottomNavigationBar renders without error across all 10 supported locales',
        (WidgetTester tester) async {
      for (final code in expectedLanguageCodes) {
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(code),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              AppLocalizations.fallbackMaterialDelegate,
              AppLocalizations.fallbackCupertinoDelegate,
            ],
            home: Scaffold(
              body: const Text('SmritiCare Test'),
              bottomNavigationBar: BottomNavigationBar(
                items: const [
                  BottomNavigationBarItem(
                      icon: Icon(Icons.home), label: 'Home'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.person), label: 'Profile'),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(BottomNavigationBar), findsOneWidget,
            reason: 'BottomNavigationBar must render under locale $code');
      }
    });
  });

  group('Voice Assistant Localization Integration Tests', () {
    test('en.json, hi.json, and as.json contain all required voice assistant keys',
        () {
      const voiceTargetCodes = ['en', 'hi', 'as'];
      for (final code in voiceTargetCodes) {
        final file = File('assets/i18n/$code.json');
        expect(file.existsSync(), isTrue);

        final Map<String, dynamic> data = jsonDecode(file.readAsStringSync());
        expect(data.containsKey('voice'), isTrue,
            reason: '$code.json must contain "voice" section');

        final voice = data['voice'] as Map<String, dynamic>;

        // Specific requirements
        expect(voice.containsKey('listening'), isTrue);
        expect(voice.containsKey('processing'), isTrue);
        expect(voice.containsKey('speaking'), isTrue);
        expect(voice.containsKey('tryAgain'), isTrue);
        expect(voice.containsKey('cancel'), isTrue);
        expect(voice.containsKey('commandNotUnderstood'), isTrue);
        expect(voice.containsKey('confirmYes'), isTrue);
        expect(voice.containsKey('confirmNo'), isTrue);
        expect(voice.containsKey('caregiverCallConfirmation'), isTrue);

        // Status group
        expect(voice.containsKey('status'), isTrue);
        final status = voice['status'] as Map<String, dynamic>;
        expect(status.containsKey('listening'), isTrue);
        expect(status.containsKey('processing'), isTrue);
        expect(status.containsKey('speaking'), isTrue);
        expect(status.containsKey('executing'), isTrue);
        expect(status.containsKey('error'), isTrue);
        expect(status.containsKey('cancelled'), isTrue);

        // Actions group
        expect(voice.containsKey('actions'), isTrue);
        final actions = voice['actions'] as Map<String, dynamic>;
        expect(actions.containsKey('openHome'), isTrue);
        expect(actions.containsKey('openGames'), isTrue);
        expect(actions.containsKey('openReminders'), isTrue);
        expect(actions.containsKey('callCaregiver'), isTrue);

        // Errors group
        expect(voice.containsKey('errors'), isTrue);
        final errors = voice['errors'] as Map<String, dynamic>;
        expect(errors.containsKey('notUnderstood'), isTrue);
        expect(errors.containsKey('general'), isTrue);
        expect(errors.containsKey('micUnavailable'), isTrue);
      }
    });

    test('AppLocalizations.fromMap translates voice keys correctly in en, hi, as',
        () {
      final enData =
          jsonDecode(File('assets/i18n/en.json').readAsStringSync())
              as Map<String, dynamic>;
      final hiData =
          jsonDecode(File('assets/i18n/hi.json').readAsStringSync())
              as Map<String, dynamic>;
      final asData =
          jsonDecode(File('assets/i18n/as.json').readAsStringSync())
              as Map<String, dynamic>;

      final enLoc = AppLocalizations.fromMap(const Locale('en'), enData);
      final hiLoc =
          AppLocalizations.fromMap(const Locale('hi'), hiData, enData);
      final asLoc =
          AppLocalizations.fromMap(const Locale('as'), asData, enData);

      // Verify English translations
      expect(enLoc.translate('voice.listening'), 'Listening');
      expect(enLoc.translate('voice.processing'), 'Processing');
      expect(enLoc.translate('voice.speaking'), 'Speaking');
      expect(enLoc.translate('voice.cancel'), 'Cancel');
      expect(
        enLoc.translate('voice.caregiverCallConfirmation'),
        'Do you want to call emergency help and alert your caregiver?',
      );

      // Verify Hindi translations
      expect(hiLoc.translate('voice.listening'), 'सुन रहा हूँ');
      expect(hiLoc.translate('voice.processing'), 'समझ रहा हूँ');
      expect(hiLoc.translate('voice.cancel'), 'रद्द करें');
      expect(
        hiLoc.translate('voice.caregiverCallConfirmation'),
        'क्या आप आपातकालीन सहायता को कॉल करना और अपने देखभालकर्ता को सचेत करना चाहते हैं?',
      );

      // Verify Assamese translations
      expect(asLoc.translate('voice.listening'), 'শুনি আছোঁ');
      expect(asLoc.translate('voice.processing'), 'প্ৰক্ৰিয়া কৰি আছোঁ');
      expect(asLoc.translate('voice.cancel'), 'বাতিল কৰক');
      expect(
        asLoc.translate('voice.caregiverCallConfirmation'),
        'আপুনি জৰুৰীকালীন সাহায্যক ফোন কৰিব আৰু আপোনাৰ তত্ত্বাৱধায়কক সতৰ্ক কৰিব বিচাৰেনে?',
      );
    });

    test('Missing translation key safely falls back to English', () {
      final enData = {
        'voice': {
          'listening': 'Listening',
          'uniqueEnglishKey': 'English Exclusive Fallback Text',
        },
      };

      // Incomplete translation map for a simulated language
      final incompleteData = {
        'voice': {
          'listening': 'सुन रहा हूँ',
        },
      };

      final partialLoc = AppLocalizations.fromMap(
        const Locale('hi'),
        incompleteData,
        enData,
      );

      // Available key returns translation
      expect(partialLoc.translate('voice.listening'), 'सुन रहा हूँ');

      // Missing key falls back to English fallback map
      expect(
        partialLoc.translate('voice.uniqueEnglishKey'),
        'English Exclusive Fallback Text',
      );

      // Non-existent key in both maps falls back to defaultText
      expect(
        partialLoc.translate('voice.nonExistentKey', defaultText: 'Default String'),
        'Default String',
      );

      // Non-existent key without defaultText returns the key path
      expect(
        partialLoc.translate('voice.nonExistentKey'),
        'voice.nonExistentKey',
      );
    });

    testWidgets(
        'Language switching updates Voice Assistant UI strings without restart',
        (WidgetTester tester) async {
      final enData =
          jsonDecode(File('assets/i18n/en.json').readAsStringSync())
              as Map<String, dynamic>;
      final hiData =
          jsonDecode(File('assets/i18n/hi.json').readAsStringSync())
              as Map<String, dynamic>;
      final asData =
          jsonDecode(File('assets/i18n/as.json').readAsStringSync())
              as Map<String, dynamic>;

      final service = LocalizationService.instance;
      service.setLocale('en');

      // Create AppLocalizations for each locale
      final enLoc = AppLocalizations.fromMap(const Locale('en'), enData);
      final hiLoc =
          AppLocalizations.fromMap(const Locale('hi'), hiData, enData);
      final asLoc =
          AppLocalizations.fromMap(const Locale('as'), asData, enData);

      service.updateCurrentLocalizations(enLoc);

      await tester.pumpWidget(
        ValueListenableBuilder<Locale>(
          valueListenable: service.currentLocaleNotifier,
          builder: (context, locale, _) {
            final loc = locale.languageCode == 'hi'
                ? hiLoc
                : (locale.languageCode == 'as' ? asLoc : enLoc);

            return MaterialApp(
              locale: locale,
              home: Scaffold(
                body: Column(
                  children: [
                    Text(
                      loc.translate('voice.listening'),
                      key: const Key('voice_listening_text'),
                    ),
                    Text(
                      loc.translate('voice.cancel'),
                      key: const Key('voice_cancel_text'),
                    ),
                    Text(
                      loc.translate('voice.caregiverCallConfirmation'),
                      key: const Key('voice_caregiver_call_text'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      // 1. Initially English
      expect(find.text('Listening'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(
        find.text('Do you want to call emergency help and alert your caregiver?'),
        findsOneWidget,
      );

      // 2. Switch to Hindi dynamically without restart
      service.updateCurrentLocalizations(hiLoc);
      service.setLocale('hi');
      await tester.pumpAndSettle();

      expect(find.text('सुन रहा हूँ'), findsOneWidget);
      expect(find.text('रद्द करें'), findsOneWidget);
      expect(
        find.text(
            'क्या आप आपातकालीन सहायता को कॉल करना और अपने देखभालकर्ता को सचेत करना चाहते हैं?'),
        findsOneWidget,
      );

      // 3. Switch to Assamese dynamically without restart
      service.updateCurrentLocalizations(asLoc);
      service.setLocale('as');
      await tester.pumpAndSettle();

      expect(find.text('শুনি আছোঁ'), findsOneWidget);
      expect(find.text('বাতিল কৰক'), findsOneWidget);
      expect(
        find.text(
            'আপুনি জৰুৰীকালীন সাহায্যক ফোন কৰিব আৰু আপোনাৰ তত্ত্বাৱধায়কক সতৰ্ক কৰিব বিচাৰেনে?'),
        findsOneWidget,
      );

      // 4. Return to English
      service.updateCurrentLocalizations(enLoc);
      service.setLocale('en');
      await tester.pumpAndSettle();

      expect(find.text('Listening'), findsOneWidget);
    });
  });
}
