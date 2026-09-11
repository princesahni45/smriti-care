// lib/core/localization/app_locale_config.dart
//
// Locale definitions and configuration for MindCare NER.

import 'package:flutter/material.dart';

class AppLocaleConfig {
  AppLocaleConfig._();

  static const Locale english = Locale('en');
  static const Locale hindi = Locale('hi');
  static const Locale assamese = Locale('as');

  static const List<Locale> supportedLocales = [
    english,
    hindi,
    assamese,
  ];

  static const Map<String, String> languageNames = {
    'en': 'English',
    'hi': 'Hindi',
    'as': 'Assamese',
  };
}
