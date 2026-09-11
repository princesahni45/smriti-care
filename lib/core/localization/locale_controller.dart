// lib/core/localization/locale_controller.dart
//
// Reactive controller for app locale switching and persistent local storage.

import 'package:flutter/material.dart';
import '../storage/local_storage_service.dart';
import '../storage/file_local_storage_service.dart';
import 'app_locale_config.dart';

class LocaleController extends ChangeNotifier {
  static const String storageKey = 'smriti_selected_language';

  LocalStorageService _storage;
  Locale _currentLocale = AppLocaleConfig.english;
  bool _isInitialized = false;

  LocaleController._({LocalStorageService? storage})
      : _storage = storage ?? FileLocalStorageService();

  static final LocaleController instance = LocaleController._();

  /// Create an isolated controller for unit tests with a mock/in-memory storage.
  factory LocaleController.forTesting(LocalStorageService storage) {
    return LocaleController._(storage: storage);
  }

  @visibleForTesting
  void setStorageForTesting(LocalStorageService storage) {
    _storage = storage;
  }

  Locale get currentLocale => _currentLocale;
  bool get isInitialized => _isInitialized;

  /// Loads the persisted language on app startup.
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _storage.init();
      final savedCode = await _storage.getString(storageKey);
      if (savedCode != null && savedCode.isNotEmpty) {
        _currentLocale = _resolveLocale(savedCode);
      }
    } catch (e) {
      debugPrint('LocaleController init note: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Sets and persists the selected locale.
  Future<void> setLocale(Locale locale) async {
    if (_currentLocale != locale) {
      _currentLocale = locale;
      notifyListeners();
      try {
        await _storage.setString(storageKey, locale.languageCode);
      } catch (e) {
        debugPrint('LocaleController persist note: $e');
      }
    }
  }

  /// Sets and persists the selected language by language code ('en', 'hi', 'as').
  Future<void> setLocaleByCode(String languageCode) async {
    final locale = _resolveLocale(languageCode);
    await setLocale(locale);
  }

  Locale _resolveLocale(String code) {
    switch (code) {
      case 'hi':
        return AppLocaleConfig.hindi;
      case 'as':
        return AppLocaleConfig.assamese;
      case 'en':
      default:
        return AppLocaleConfig.english;
    }
  }
}
