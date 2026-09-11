// lib/core/localization/app_localizations.dart
//
// SmritiCare Multilingual Localization Engine.
// Supports 10 Indian & Northeast languages:
// 1. English (en)
// 2. Hindi (hi)
// 3. Assamese (as)
// 4. Bengali (bn)
// 5. Manipuri / Meitei (mni)
// 6. Khasi (kha)
// 7. Mizo (lus)
// 8. Garo (grt)
// 9. Bodo (brx)
// 10. Kokborok (trp)

import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class SupportedLanguage {
  final String code;
  final String englishName;
  final String nativeName;
  final String region;

  const SupportedLanguage({
    required this.code,
    required this.englishName,
    required this.nativeName,
    required this.region,
  });
}

class AppLocalizations {
  final Locale locale;
  Map<String, dynamic> _localizedStrings = {};
  Map<String, dynamic> _fallbackStrings = {};

  AppLocalizations(this.locale);

  /// Test and offline constructor allowing manual map injection.
  AppLocalizations.fromMap(
    this.locale,
    this._localizedStrings, [
    this._fallbackStrings = const {},
  ]) {
    LocalizationService.instance.updateCurrentLocalizations(this);
  }

  /// Global synchronous reference to current active localizations
  static AppLocalizations? get current =>
      LocalizationService.instance.currentLocalizations;

  static const List<SupportedLanguage> supportedLanguages = [
    SupportedLanguage(
      code: 'en',
      englishName: 'English',
      nativeName: 'English',
      region: 'Universal',
    ),
    SupportedLanguage(
      code: 'hi',
      englishName: 'Hindi',
      nativeName: 'हिन्दी',
      region: 'Pan-India',
    ),
    SupportedLanguage(
      code: 'as',
      englishName: 'Assamese',
      nativeName: 'অসমীয়া',
      region: 'Assam',
    ),
    SupportedLanguage(
      code: 'bn',
      englishName: 'Bengali',
      nativeName: 'বাংলা',
      region: 'Assam & West Bengal',
    ),
    SupportedLanguage(
      code: 'mni',
      englishName: 'Manipuri (Meitei)',
      nativeName: 'মৈতৈলোন্',
      region: 'Manipur',
    ),
    SupportedLanguage(
      code: 'kha',
      englishName: 'Khasi',
      nativeName: 'Ka Ktien Khasi',
      region: 'Meghalaya',
    ),
    SupportedLanguage(
      code: 'lus',
      englishName: 'Mizo',
      nativeName: 'Mizo ṭawng',
      region: 'Mizoram',
    ),
    SupportedLanguage(
      code: 'grt',
      englishName: 'Garo',
      nativeName: 'A·chik',
      region: 'Meghalaya & Assam',
    ),
    SupportedLanguage(
      code: 'brx',
      englishName: 'Bodo',
      nativeName: 'बर’',
      region: 'Bodoland, Assam',
    ),
    SupportedLanguage(
      code: 'trp',
      englishName: 'Kokborok',
      nativeName: 'Kokborok',
      region: 'Tripura',
    ),
  ];

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('hi'),
    Locale('as'),
    Locale('bn'),
    Locale('mni'),
    Locale('kha'),
    Locale('lus'),
    Locale('grt'),
    Locale('brx'),
    Locale('trp'),
  ];

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // FIX: MaterialLocalizations / localization configuration fix
  // Provides MaterialLocalizations fallback for regional languages not in Flutter SDK
  static const LocalizationsDelegate<MaterialLocalizations>
      fallbackMaterialDelegate = FallbackMaterialLocalizationsDelegate();

  // FIX: MaterialLocalizations / localization configuration fix
  // Provides CupertinoLocalizations fallback for regional languages not in Flutter SDK
  static const LocalizationsDelegate<CupertinoLocalizations>
      fallbackCupertinoDelegate = FallbackCupertinoLocalizationsDelegate();

  /// Load translations from assets/i18n/{code}.json
  Future<bool> load() async {
    // 1. Load active locale
    try {
      final jsonString = await rootBundle
          .loadString('assets/i18n/${locale.languageCode}.json', cache: false);
      _localizedStrings = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      _localizedStrings = {};
    }

    // 2. Load English as fallback if current locale is not English
    if (locale.languageCode != 'en') {
      try {
        final fallbackString =
            await rootBundle.loadString('assets/i18n/en.json', cache: false);
        _fallbackStrings = jsonDecode(fallbackString) as Map<String, dynamic>;
      } catch (_) {
        _fallbackStrings = {};
      }
    }

    LocalizationService.instance.updateCurrentLocalizations(this);
    return true;
  }

  /// Translate a key using dot notation (e.g. "languageSelector.title" or "common.save")
  String translate(String key, {String? defaultText}) {
    final value = _findNestedValue(_localizedStrings, key);
    if (value != null && value is String && value.trim().isNotEmpty) {
      return value;
    }

    // Fallback to English
    final fallback = _findNestedValue(_fallbackStrings, key);
    if (fallback != null && fallback is String && fallback.trim().isNotEmpty) {
      return fallback;
    }

    return defaultText ?? key;
  }

  dynamic _findNestedValue(Map<String, dynamic> map, String keyPath) {
    final parts = keyPath.split('.');
    dynamic current = map;

    for (final part in parts) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }
}

// FIX: MaterialLocalizations / localization configuration fix
// Custom MaterialLocalizations delegate that falls back to DefaultMaterialLocalizations
// for regional languages (mni, kha, lus, grt, brx, trp) not built into the Flutter framework SDK.
class FallbackMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((l) => l.languageCode == locale.languageCode);
  }

  @override
  Future<MaterialLocalizations> load(Locale locale) {
    return DefaultMaterialLocalizations.load(locale);
  }

  @override
  bool shouldReload(FallbackMaterialLocalizationsDelegate old) => false;
}

// FIX: MaterialLocalizations / localization configuration fix
// Custom CupertinoLocalizations delegate that falls back to DefaultCupertinoLocalizations
// for regional languages not built into the Flutter framework SDK.
class FallbackCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const FallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((l) => l.languageCode == locale.languageCode);
  }

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    return DefaultCupertinoLocalizations.load(locale);
  }

  @override
  bool shouldReload(FallbackCupertinoLocalizationsDelegate old) => false;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((l) => l.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Global Service managing runtime language switches
class LocalizationService {
  LocalizationService._();
  static final LocalizationService instance = LocalizationService._();

  static const String _storageFileName = 'selected_language_code.txt';

  final ValueNotifier<Locale> currentLocaleNotifier =
      ValueNotifier<Locale>(const Locale('en'));

  Locale get currentLocale => currentLocaleNotifier.value;
  String get currentLanguageCode => currentLocale.languageCode;

  AppLocalizations? _currentLocalizations;
  AppLocalizations? get currentLocalizations => _currentLocalizations;

  void updateCurrentLocalizations(AppLocalizations loc) {
    _currentLocalizations = loc;
  }

  /// Synchronously translate a key with fallback to English and defaultText
  String translate(String key, {String? defaultText}) {
    if (_currentLocalizations != null) {
      return _currentLocalizations!.translate(key, defaultText: defaultText);
    }
    return defaultText ?? key;
  }

  /// Convenience alias for translate
  String tr(String key, {String? defaultText}) =>
      translate(key, defaultText: defaultText);

  /// Load persisted language choice on app launch
  Future<void> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_storageFileName');
      if (await file.exists()) {
        final code = (await file.readAsString()).trim();
        if (AppLocalizations.supportedLocales
            .any((l) => l.languageCode == code)) {
          currentLocaleNotifier.value = Locale(code);
        }
      }
    } catch (e) {
      debugPrint('[LocalizationService] Storage notice: $e');
    }
  }

  /// Switch active language.
  ///
  /// The locale notifier is updated synchronously.
  /// File persistence is skipped in test environments to prevent platform
  /// channel calls from blocking [pumpAndSettle].
  void setLocale(String languageCode) {
    if (AppLocalizations.supportedLocales
        .any((l) => l.languageCode == languageCode)) {
      currentLocaleNotifier.value = Locale(languageCode);
      _persistLocale(languageCode);
    }
  }

  Future<void> _persistLocale(String languageCode) async {
    // Skip persistence during tests — platform channels are unavailable
    // in headless runners and any pending Future blocks pumpAndSettle.
    if (_isTestEnvironment) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_storageFileName');
      await file.writeAsString(languageCode);
    } catch (e) {
      debugPrint('[LocalizationService] Failed to save locale: $e');
    }
  }

  /// True when running inside a Flutter test binding.
  static bool get _isTestEnvironment {
    // WidgetsBinding may not be initialised in pure-Dart unit tests;
    // treat that as a safe non-test environment (persistence runs normally).
    try {
      // In widget tests, WidgetsBinding.instance is TestWidgetsFlutterBinding.
      // In production, it is WidgetsFlutterBinding.
      // We detect this by checking the runtimeType name to avoid a hard
      // dependency on flutter_test in production code.
      final binding = WidgetsBinding.instance;
      return binding.runtimeType.toString().contains('Test');
    } catch (_) {
      return false;
    }
  }
}

/// Extension helper on BuildContext
extension LocalizationX on BuildContext {
  String tr(String key, {String? defaultText}) {
    final loc = AppLocalizations.of(this) ??
        LocalizationService.instance.currentLocalizations;
    if (loc == null) return defaultText ?? key;
    return loc.translate(key, defaultText: defaultText);
  }
}
