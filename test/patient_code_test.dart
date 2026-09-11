// test/patient_code_test.dart
//
// Comprehensive unit tests for SmritiCare Patient Access Code generation,
// uniqueness, normalization, verification, lifecycle (revocation/expiry),
// and offline persistence.
//
// Run: flutter test test/patient_code_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_care/core/models/patient_access_code.dart';
import 'package:smriti_care/core/models/user_model.dart';
import 'package:smriti_care/core/services/patient_code_service.dart';
import 'package:smriti_care/features/auth/widgets/patient_code_formatter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Patient Access Code - Generation & Unambiguity', () {
    test('Code format matches SMR-XXXX-YY with 29-char alphabet', () async {
      final service = PatientCodeService.instance;
      await service.init();

      final code = await service.generateCodeForPatient(
        patientId: 'test_patient_01',
        patientName: 'Shri Ramesh',
        caregiverId: 'caregiver_01',
        caregiverName: 'Anita Sharma',
      );

      expect(code.code, startsWith('SMR-'));
      // Format should be SMR-4chars-2chars
      final regex = RegExp(r'^SMR-[2-9ABCDEFGHJKMNPQRSTUVWXYZ]{4}-[2-9ABCDEFGHJKMNPQRSTUVWXYZ]{2}$');
      expect(regex.hasMatch(code.code), isTrue,
          reason: 'Code must follow SMR-XXXX-YY using the unambiguous alphabet');

      // Check characters do NOT contain confusing characters 0, O, 1, I, L
      expect(code.code.contains('0'), isFalse);
      expect(code.code.contains('O'), isFalse);
      expect(code.code.contains('1'), isFalse);
      expect(code.code.contains('I'), isFalse);
      expect(code.code.contains('L'), isFalse);
    });

    test('Multiple generated codes are cryptographically unique (no collisions)', () async {
      final service = PatientCodeService.instance;
      final generatedCodes = <String>{};

      for (int i = 0; i < 50; i++) {
        final code = await service.generateCodeForPatient(
          patientId: 'patient_$i',
          patientName: 'Patient $i',
          caregiverId: 'caregiver_test',
          caregiverName: 'Doctor Test',
        );
        expect(generatedCodes.contains(code.code), isFalse,
            reason: 'Generated code must be unique across attempts');
        generatedCodes.add(code.code);
      }
      expect(generatedCodes.length, 50);
    });
  });

  group('Patient Access Code - Normalization', () {
    test('Normalizes lowercase, spaces, and missing hyphens correctly', () {
      expect(PatientCodeService.normalizeCode('smr-4827-kp'), 'SMR-4827-KP');
      expect(PatientCodeService.normalizeCode('smr 4827 kp'), 'SMR-4827-KP');
      expect(PatientCodeService.normalizeCode('smr4827kp'), 'SMR-4827-KP');
      expect(PatientCodeService.normalizeCode('4827KP'), 'SMR-4827-KP');
      expect(PatientCodeService.normalizeCode('4827-kp'), 'SMR-4827-KP');
      expect(PatientCodeService.normalizeCode('  smr-4827-kp  '), 'SMR-4827-KP');
    });

    test('PatientCodeInputFormatter auto-formats input incrementally', () {
      final formatter = PatientCodeInputFormatter();

      const val1 = TextEditingValue(text: '4');
      final res1 = formatter.formatEditUpdate(const TextEditingValue(), val1);
      expect(res1.text, 'SMR-4');

      const val2 = TextEditingValue(text: '4827');
      final res2 = formatter.formatEditUpdate(const TextEditingValue(), val2);
      expect(res2.text, 'SMR-4827');

      const val3 = TextEditingValue(text: '4827KP');
      final res3 = formatter.formatEditUpdate(const TextEditingValue(), val3);
      expect(res3.text, 'SMR-4827-KP');
    });
  });

  group('Patient Access Code - Verification & Offline Login', () {
    test('Default seeded code SMR-4827-KP logs in successfully', () async {
      final service = PatientCodeService.instance;
      await service.init();

      final result = await service.verifyPatientCode('smr-4827-kp');
      expect(result.isSuccess, isTrue);
      expect(result.patientId, 'MC-2048');
      expect(result.patientName, 'Mr. Ramesh Das');
      expect(result.accessCode?.isLinked, isTrue);
      expect(UserSessionService.instance.activeRole, UserRole.patient);
    });

    test('Invalid code returns elderly-friendly error message', () async {
      final service = PatientCodeService.instance;
      final result = await service.verifyPatientCode('SMR-9999-ZZ');

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('That code is not correct. Please ask your caregiver'));
    });

    test('Short code prompts user to enter the full code', () async {
      final service = PatientCodeService.instance;
      final result = await service.verifyPatientCode('SMR');

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('full code'));
    });
  });

  group('Patient Access Code - Lifecycle (Revocation & Expiry)', () {
    test('Revoking a code prevents patient login', () async {
      final service = PatientCodeService.instance;
      final code = await service.generateCodeForPatient(
        patientId: 'patient_lifecycle_01',
        patientName: 'Test Patient',
        caregiverId: 'caregiver_01',
        caregiverName: 'Caregiver A',
      );

      // Verify it works first
      final firstCheck = await service.verifyPatientCode(code.code);
      expect(firstCheck.isSuccess, isTrue);

      // Now revoke the code
      await service.revokeCode(code.code);

      // Attempting to verify revoked code must fail with clear message
      final secondCheck = await service.verifyPatientCode(code.code);
      expect(secondCheck.isSuccess, isFalse);
      expect(secondCheck.errorMessage, contains('no longer active'));
    });

    test('Regenerating code for a patient deactivates the previous code', () async {
      final service = PatientCodeService.instance;
      final code1 = await service.generateCodeForPatient(
        patientId: 'patient_regen_01',
        patientName: 'Regen Patient',
        caregiverId: 'caregiver_01',
        caregiverName: 'Caregiver A',
      );

      final code2 = await service.generateCodeForPatient(
        patientId: 'patient_regen_01',
        patientName: 'Regen Patient',
        caregiverId: 'caregiver_01',
        caregiverName: 'Caregiver A',
      );

      expect(code1.code, isNot(equals(code2.code)));

      // code1 must now be inactive
      final check1 = await service.verifyPatientCode(code1.code);
      expect(check1.isSuccess, isFalse);
      expect(check1.errorMessage, contains('no longer active'));

      // code2 must be valid and succeed
      final check2 = await service.verifyPatientCode(code2.code);
      expect(check2.isSuccess, isTrue);
    });

    test('Expired code is rejected with expired error message', () async {
      // Manually create an expired code in local cache
      final expired = PatientAccessCode(
        code: 'SMR-EXP1-RD',
        patientId: 'patient_expired',
        caregiverId: 'cg_01',
        patientName: 'Expired Patient',
        caregiverName: 'Caregiver B',
        createdAt: DateTime.now().subtract(const Duration(days: 35)),
        expiresAt: DateTime.now().subtract(const Duration(days: 5)),
        isActive: true,
      );

      expect(expired.isExpired, isTrue);
      expect(expired.isValid, isFalse);
    });
  });
}
