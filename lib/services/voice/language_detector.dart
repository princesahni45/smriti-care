// lib/services/voice/language_detector.dart
//
// Fast on-device language detector based on unicode character ranges
// and language hints. Does not require external libraries or cloud APIs.

class LanguageDetector {
  LanguageDetector._();

  /// Unicode range for Devanagari script (Hindi, Marathi, etc.).
  static final RegExp _devanagariRegex = RegExp(r'[\u0900-\u097F]');

  /// Unicode range for Bengali and Assamese script.
  static final RegExp _assameseBengaliRegex = RegExp(r'[\u0980-\u09FF]');

  /// Detects the target language ('en', 'hi', or 'as') of an utterance.
  ///
  /// Priority:
  /// 1. Assamese/Bengali script characters -> 'as'
  /// 2. Devanagari script characters -> 'hi'
  /// 3. Fallback to provided [hintLanguageCode] if valid ('en', 'hi', 'as')
  /// 4. Default -> 'en'
  static String detectLanguage(String text, {String? hintLanguageCode}) {
    if (_assameseBengaliRegex.hasMatch(text)) {
      return 'as';
    }

    if (_devanagariRegex.hasMatch(text)) {
      return 'hi';
    }

    if (hintLanguageCode != null) {
      final code = hintLanguageCode.toLowerCase().trim();
      if (code.startsWith('as')) return 'as';
      if (code.startsWith('hi')) return 'hi';
      if (code.startsWith('en')) return 'en';
    }

    return 'en';
  }
}
