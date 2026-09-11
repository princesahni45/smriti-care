// lib/services/voice/voice_safety_guard.dart
//
// Dementia-specific medical and operational safety rules.
// Enforces non-negotiable boundaries:
// 1. Voice must never change medicine dosage.
// 2. Voice must never mark medicine as taken without confirmation.
// 3. Voice must never change caregiver PIN.
// 4. Voice must never trigger emergency actions without explicit confirmation.
// 5. Voice must never make a medical diagnosis.
// 6. Commands must never execute on uncertain ASR confidence.

class VoiceSafetyViolation {
  final String code;
  final String userFacingReason;
  final String safeAlternativeGuidance;

  const VoiceSafetyViolation({
    required this.code,
    required this.userFacingReason,
    required this.safeAlternativeGuidance,
  });
}

class VoiceSafetyGuard {
  VoiceSafetyGuard._();

  /// Minimum acceptable ASR confidence for direct intent execution.
  static const double minimumConfidenceThreshold = 0.60;

  // ── 1. Prohibited Dosage Change Patterns
  static final RegExp _dosageChangeRegex = RegExp(
    r'((change|increase|decrease|modify|adjust|double|triple|halve|set)\s+(the\s+|my\s+|our\s+|a\s+|caregiver\s+)?.*?(dose|dosage|mg|ml|mcg|milligram|tablets?|pills?|medicine|medication))|'
    r'((take|give)\s+\d+\s*(mg|ml|mcg|milligrams?|tablets?|pills?))|'
    r'((खुराक|डोज़|दवा|दवाई).*(बदलो|बदलना|बढ़ाओ|घटाओ))|'
    r'(\d+\s*(एमजी|मिलीग्राम|गोली)\s*(कर\s*दो|लेना))|'
    r'((ঔষধৰ\s*মাত্ৰা|ডোজ|ঔষধ).*(সলনি|বৃদ্ধি|হ্ৰাস))',
    caseSensitive: false,
  );

  // ── 2. Prohibited Caregiver PIN Change Patterns
  static final RegExp _pinChangeRegex = RegExp(
    r'((change|reset|update|modify|set|forgot)\s+(the\s+|my\s+|our\s+)?.*?(pin|passcode|password|code))|'
    r'((caregiver\s+pin))|'
    r'((पिन|पासकोड|पासवर्ड).*(बदलो|बदलना|सेट\s*करो))|'
    r'((পিন|পাছকোড).*(সলনি|চেট))',
    caseSensitive: false,
  );

  // ── 3. Prohibited Medical Diagnosis Patterns
  static final RegExp _medicalDiagnosisRegex = RegExp(
    r'((do\s+i\s+have|diagnose|what\s+disease|what\s+illness|am\s+i\s+sick|is\s+it\s+alzheimer|is\s+it\s+dementia|cure\s+for|medical\s+advice))|'
    r'((क्या\s+मुझे|बीमारी\s+है|रोग\s+है|इलाज\s+बताओ|जांच\s+करो))|'
    r'((মোক\s+কি\s+বেমাৰ|ৰোগ\s+আছে\s+নেকি|চিকিৎসা|উপশম))',
    caseSensitive: false,
  );

  // ── 4. Medicine Taken Patterns (Requires Strict Confirmation)
  static final RegExp _medicineTakenRegex = RegExp(
    r'((i\s+took|have\s+taken|took\s+my|drank\s+my|completed\s+my)\s+(medicine|medication|pills?|dose|tablet))|'
    r'((mark\s+as\s+taken|medicine\s+done))|'
    r'((दवा\s+ले\s+ली|दवाई\s+खा\s+ली|दवा\s+हो\s+गई))|'
    r'((ঔষধ\s+খালো|দৰব\s+খালো|ঔষধ\s+লোৱা\s+হ’ল))',
    caseSensitive: false,
  );

  /// Evaluates whether an utterance violates safety boundaries.
  static VoiceSafetyViolation? checkSafetyViolation(
      String normalizedUtterance) {
    if (_dosageChangeRegex.hasMatch(normalizedUtterance)) {
      return const VoiceSafetyViolation(
        code: 'PROHIBITED_DOSAGE_CHANGE',
        userFacingReason:
            'Voice commands cannot modify medication dosages or schedules.',
        safeAlternativeGuidance:
            'Please refer to your physical prescription or speak with your caregiver or Dr. Ananya Bora.',
      );
    }

    if (_pinChangeRegex.hasMatch(normalizedUtterance)) {
      return const VoiceSafetyViolation(
        code: 'PROHIBITED_PIN_CHANGE',
        userFacingReason:
            'Caregiver PIN cannot be viewed or changed using voice.',
        safeAlternativeGuidance:
            'Please ask your caregiver to update their PIN directly inside the locked Caregiver Settings panel.',
      );
    }

    if (_medicalDiagnosisRegex.hasMatch(normalizedUtterance)) {
      return const VoiceSafetyViolation(
        code: 'PROHIBITED_MEDICAL_DIAGNOSIS',
        userFacingReason:
            'Smriti Care cannot provide medical or clinical diagnoses.',
        safeAlternativeGuidance:
            'Please contact your physician, Dr. Ananya Bora, or speak with your caregiver for medical guidance.',
      );
    }

    return null;
  }

  /// Checks if an utterance attempts to mark medicine as taken, which
  /// requires explicit elderly confirmation.
  static bool requiresMedicineTakenConfirmation(String normalizedUtterance) {
    return _medicineTakenRegex.hasMatch(normalizedUtterance);
  }

  /// Evaluates whether ASR confidence meets safety thresholds.
  static bool isAsrConfident(double asrConfidence) {
    return asrConfidence >= minimumConfidenceThreshold;
  }
}
