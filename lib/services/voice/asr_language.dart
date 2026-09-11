// lib/services/voice/asr_language.dart
//
// Supported Speech Recognition Languages for AI4Bharat Indic ASR.

enum ASRLanguage {
  english('en', 'English', 'English'),
  hindi('hi', 'Hindi', 'हिन्दी'),
  assamese('as', 'Assamese', 'অসমীয়া');

  final String code;
  final String englishName;
  final String nativeName;

  const ASRLanguage(this.code, this.englishName, this.nativeName);

  static ASRLanguage fromCode(String code) {
    switch (code) {
      case 'hi':
        return ASRLanguage.hindi;
      case 'as':
        return ASRLanguage.assamese;
      case 'en':
      default:
        return ASRLanguage.english;
    }
  }

  static bool isSupported(String code) {
    return code == 'en' || code == 'hi' || code == 'as';
  }
}
