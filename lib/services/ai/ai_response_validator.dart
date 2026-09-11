// lib/services/ai/ai_response_validator.dart
//
// Dementia-Safe Guardrail and Validation Filter for MindCare NER.
//
// SAFETY REQUIREMENTS:
// 1. No clinical diagnosis (e.g., stage, Alzheimer, disease progression).
// 2. No medication dosage advice (e.g., mg, dosage, skip medication).
// 3. No emergency decisions (e.g., advising against emergency services).
// 4. No invented patient personal history or false memories.
// 5. No unsafe physical instructions.
// 6. Responses must be short, calming, and easy to comprehend.

class ValidationResult {
  final bool isValid;
  final String? violationReason;
  final String sanitizedText;

  const ValidationResult({
    required this.isValid,
    this.violationReason,
    required this.sanitizedText,
  });
}

class AIResponseValidator {
  const AIResponseValidator();

  /// Regular expression patterns that trigger immediate rejection.
  static final List<RegExp> _unsafePatterns = [
    // Medication dosage / modifications
    RegExp(r'\b(\d+\s*(mg|ml|mcg|tablets?|pills?|capsules?))\b',
        caseSensitive: false),
    RegExp(
        r'\b(take|increase|decrease|double|skip|stop taking)\s+(your\s+)?(medicine|medication|dose|dosage|pills?)\b',
        caseSensitive: false),

    // Clinical diagnosis / prognosis
    RegExp(
        r'\b(you have|diagnosed with|suffering from)\s+(dementia|alzheimer|cancer|heart attack|stroke)\b',
        caseSensitive: false),
    RegExp(r'\b(stage\s+[1-4]|terminal|incurable|brain damage)\b',
        caseSensitive: false),

    // Emergency interference
    RegExp(
        r'\b(do not|don\x27t|never)\s+(call|contact)\s+(the\s+)?(doctor|hospital|ambulance|emergency|caregiver|police)\b',
        caseSensitive: false),
    RegExp(r'\b(no need for|avoid)\s+(hospital|doctor|help)\b',
        caseSensitive: false),

    // Potentially dangerous instructions
    RegExp(
        r'\b(leave\s+the\s+house|go\s+outside\s+alone|turn\s+off\s+the\s+stove|climb|jump|cut)\b',
        caseSensitive: false),
  ];

  /// Validates generated AI output against safety criteria.
  ValidationResult validate({
    required String rawText,
    required String languageCode,
  }) {
    final trimmed = rawText.trim();

    if (trimmed.isEmpty) {
      return ValidationResult(
        isValid: false,
        violationReason: 'Empty response generated',
        sanitizedText: _getSafetyFallback(languageCode),
      );
    }

    // Check unsafe content patterns
    for (final pattern in _unsafePatterns) {
      if (pattern.hasMatch(trimmed)) {
        return ValidationResult(
          isValid: false,
          violationReason: 'Violated safety policy pattern: ',
          sanitizedText: _getSafetyFallback(languageCode),
        );
      }
    }

    // Length check: Dementia-safe responses should be concise (<= 220 chars or max 2 sentences)
    if (trimmed.length > 200 ||
        trimmed.split(RegExp(r'[.!?।]\s*')).length > 3) {
      // Shorten cleanly to the first 2 sentences
      final sentences = trimmed
          .split(RegExp(r'(?<=[.!?।])\s+'))
          .where((s) => s.trim().isNotEmpty)
          .toList();
      if (sentences.length > 2) {
        final shortened = sentences.take(2).join(' ');
        return ValidationResult(
          isValid: true,
          violationReason: 'Response trimmed for cognitive clarity',
          sanitizedText: shortened,
        );
      }
    }

    return ValidationResult(
      isValid: true,
      sanitizedText: trimmed,
    );
  }

  static String _getSafetyFallback(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'कृपया किसी भी स्वास्थ्य प्रश्न या दवा के लिए अपने देखभालकर्ता से बात करें। सब कुछ सुरक्षित है।';
      case 'as':
        return 'অনুগ্ৰহ কৰি যিকোনো স্বাস্থ্যৰ প্ৰশ্নৰ বাবে আপোনাৰ সেৱাদাতাক সোধক। সকলো সুৰক্ষিত।';
      case 'en':
      default:
        return 'Please speak with your caregiver for any medical questions or help. You are safe here.';
    }
  }
}
