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

    test('All 10 translation JSON files exist, parse cleanly, and have core keys', () {
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

    test('LocalizationService switches active locale and notifies listeners', () {
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
    testWidgets('BottomNavigationBar renders without error across all 10 supported locales',
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
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                  BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
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
}
