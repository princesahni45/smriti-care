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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  /// Load translations from assets/i18n/{code}.json
  Future<bool> load() async {
    // 1. Load active locale
    try {
      final jsonString =
          await rootBundle.loadString('assets/i18n/${locale.languageCode}.json', cache: false);
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

  final ValueNotifier<Locale> currentLocaleNotifier =
      ValueNotifier<Locale>(const Locale('en'));

  Locale get currentLocale => currentLocaleNotifier.value;

  void setLocale(String languageCode) {
    if (AppLocalizations.supportedLocales
        .any((l) => l.languageCode == languageCode)) {
      currentLocaleNotifier.value = Locale(languageCode);
    }
  }
}

/// Extension helper on BuildContext
extension LocalizationX on BuildContext {
  String tr(String key, {String? defaultText}) {
    final loc = AppLocalizations.of(this);
    if (loc == null) return defaultText ?? key;
    return loc.translate(key, defaultText: defaultText);
  }
}
