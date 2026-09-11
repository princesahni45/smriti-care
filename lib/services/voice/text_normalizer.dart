// lib/services/voice/text_normalizer.dart
//
// Normalization utility for deterministic speech recognition matching.
// Converts utterances into consistent format without stripping Indic characters.

class TextNormalizer {
  TextNormalizer._();

  /// Punctuation and symbols to remove from spoken commands.
  static final RegExp _punctuationRegex =
      RegExp(r'[.,\/#!$%\^&\*;:{}=\-_`~()?"\x27<>।॥\u0964\u0965]');

  /// Multiple whitespace compressor.
  static final RegExp _whitespaceRegex = RegExp(r'\s+');

  /// Normalizes an input utterance for deterministic intent matching.
  static String normalize(String text) {
    if (text.isEmpty) return '';

    // 1. Lowercase
    String normalized = text.toLowerCase();

    // 2. Remove punctuation and symbols while preserving unicode Indic characters
    normalized = normalized.replaceAll(_punctuationRegex, ' ');

    // 3. Collapse multiple whitespace characters into a single space
    normalized = normalized.replaceAll(_whitespaceRegex, ' ');

    // 4. Trim leading and trailing whitespace
    return normalized.trim();
  }
}
