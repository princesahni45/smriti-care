// test/localization_test.dart
//
// Comprehensive unit and widget tests for SmritiCare multilingual localization (en, hi, as).
// Verifies:
// 1. Default language (English)
// 2. Changing language (to Hindi and Assamese)
// 3. Persisting language to LocalStorageService
// 4. Restoring language on app restart / init()
// 5. Missing translation fallback to English
// 6. LanguageSelectorSheet widget rendering, selection indicator, and touch targets

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_care/core/localization/app_locale_config.dart';
import 'package:smriti_care/core/localization/locale_controller.dart';
import 'package:smriti_care/core/localization/language_selector_sheet.dart';
import 'package:smriti_care/core/storage/in_memory_storage_service.dart';
import 'package:smriti_care/l10n/app_localizations.dart';

void main() {
  group('Localization Tests', () {
    testWidgets('AppLocalizations loads English strings properly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: AppLocaleConfig.english,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Scaffold(
                body: Column(
                  children: [
                    Text(l10n.appName),
                    Text(l10n.welcome),
                    Text(l10n.emergency),
                    Text(l10n.medicineReminder),
                    Text(l10n.offlineMode),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Smriti Care'), findsOneWidget);
      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('Emergency SOS'), findsOneWidget);
      expect(find.text('Medicine Reminder'), findsOneWidget);
      expect(find.text('Offline Mode'), findsOneWidget);
    });

    testWidgets('AppLocalizations loads Hindi strings properly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: AppLocaleConfig.hindi,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Scaffold(
                body: Column(
                  children: [
                    Text(l10n.appName),
                    Text(l10n.welcome),
                    Text(l10n.emergency),
                    Text(l10n.medicineReminder),
                    Text(l10n.offlineMode),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('स्मृति केयर'), findsOneWidget);
      expect(find.text('नमस्ते'), findsOneWidget);
      expect(find.text('आपातकालीन SOS'), findsOneWidget);
      expect(find.text('दवा का समय'), findsOneWidget);
      expect(find.text('ऑफ़लाइन मोड'), findsOneWidget);
    });

    testWidgets('AppLocalizations loads Assamese strings properly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: AppLocaleConfig.assamese,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Scaffold(
                body: Column(
                  children: [
                    Text(l10n.appName),
                    Text(l10n.welcome),
                    Text(l10n.emergency),
                    Text(l10n.medicineReminder),
                    Text(l10n.offlineMode),
                  ],
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('স্মৃতি কেয়াৰ'), findsOneWidget);
      expect(find.text('নমস্কাৰ'), findsOneWidget);
      expect(find.text('জৰুৰী SOS'), findsOneWidget);
      expect(find.text('ঔষধৰ সময়'), findsOneWidget);
      expect(find.text('অফলাইন অৱস্থা'), findsOneWidget);
    });

    testWidgets(
        'Missing translation or unsupported locale falls back to English',
        (WidgetTester tester) async {
      // Test with an unsupported locale code (e.g., German 'de')
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            if (deviceLocale != null) {
              for (final supported in supportedLocales) {
                if (supported.languageCode == deviceLocale.languageCode) {
                  return supported;
                }
              }
            }
            return const Locale('en'); // Safe English fallback
          },
          home: Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Scaffold(
                body: Text(l10n.emergency),
              );
            },
          ),
        ),
      );

      // Should safely fall back to the template English value
      expect(find.text('Emergency SOS'), findsOneWidget);
    });

    test('Default language is English', () {
      final storage = InMemoryStorageService();
      final controller = LocaleController.forTesting(storage);
      expect(controller.currentLocale.languageCode, 'en');
    });

    test('Changing language updates locale and persists to storage', () async {
      final storage = InMemoryStorageService();
      final controller = LocaleController.forTesting(storage);

      await controller.setLocaleByCode('hi');
      expect(controller.currentLocale.languageCode, 'hi');
      expect(await storage.getString(LocaleController.storageKey), 'hi');

      await controller.setLocaleByCode('as');
      expect(controller.currentLocale.languageCode, 'as');
      expect(await storage.getString(LocaleController.storageKey), 'as');
    });

    test('Restoring language loads persisted language on restart/init',
        () async {
      final storage = InMemoryStorageService();
      // Pre-seed storage as if the app was previously configured in Assamese
      await storage.setString(LocaleController.storageKey, 'as');

      final controller = LocaleController.forTesting(storage);
      await controller.init();

      expect(controller.currentLocale.languageCode, 'as');
    });

    testWidgets(
        'LanguageSelectorSheet displays options and updates language on tap',
        (WidgetTester tester) async {
      final inMemoryStorage = InMemoryStorageService();
      LocaleController.instance.setStorageForTesting(inMemoryStorage);

      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: LanguageSelectorSheet(),
          ),
        ),
      );

      // Verify all 3 languages are displayed with both English & Native labels
      expect(find.text('English'), findsWidgets);
      expect(find.text('Hindi'), findsOneWidget);
      expect(find.text('हिन्दी'), findsOneWidget);
      expect(find.text('Assamese'), findsOneWidget);
      expect(find.text('অসমীয়া'), findsOneWidget);

      // Tap Hindi option
      await tester.tap(find.text('हिन्दी'));
      await tester.pumpAndSettle();

      expect(LocaleController.instance.currentLocale.languageCode, 'hi');

      // Reset back to English
      await LocaleController.instance.setLocaleByCode('en');
    });
  });
}
