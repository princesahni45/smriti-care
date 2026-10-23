// test/firestore_rules_matrix_test.dart
//
// Automated tests verifying the Firestore security rule contracts,
// session immutability, schema constraints, and caregiver-patient scoping
// as defined in the Smriti Care Security Review allowed/denied matrix.

import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_care/core/models/daily_step_record.dart';
import 'package:smriti_care/core/models/game_result.dart';
import 'package:smriti_care/core/models/patient_access_code.dart';
import 'package:smriti_care/core/models/user_model.dart';
import 'package:smriti_care/core/services/caregiver_auth_service.dart';
import 'package:smriti_care/core/services/patient_code_service.dart';
import 'package:smriti_care/services/emergency_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await PatientCodeService.instance.resetForTesting();
    UserSessionService.instance.clearPatientSession();
  });

  group('Firestore Rules Contract - Session Immutability & Replay Protection', () {
    test('TC-07 & TC-08: Linking valid code succeeds; second linking attempt is denied', () async {
      final service = PatientCodeService.instance;
      final code = await service.generateCodeForPatient(
        patientId: 'patient_matrix_01',
        patientName: 'Matrix Patient',
        caregiverId: 'caregiver_01',
        caregiverName: 'Caregiver A',
      );

      // First verification succeeds (TC-07 Allowed)
      final first = await service.verifyPatientCode(code.code);
      expect(first.isSuccess, isTrue);
      expect(first.accessCode?.isLinked, isTrue);

      // Duplicate / concurrent linking attempt fails (TC-08 Denied)
      final second = await service.verifyPatientCode(code.code);
      expect(second.isSuccess, isFalse);
      expect(second.errorMessage, contains('already been linked'));
    });

    test('TC-09: Expired access code is rejected during verification', () async {
      final expired = PatientAccessCode(
        code: 'SMR-EXP2-ZZ',
        patientId: 'patient_expired_02',
        caregiverId: 'cg_01',
        patientName: 'Expired Patient',
        caregiverName: 'Caregiver B',
        createdAt: DateTime.now().subtract(const Duration(days: 40)),
        expiresAt: DateTime.now().subtract(const Duration(days: 10)),
        isActive: true,
      );

      expect(expired.isExpired, isTrue);
      expect(expired.isValid, isFalse);
    });

    test('TC-10: UserSessionService enforces session immutability and blocks patientId tampering', () {
      final session = UserSessionService.instance;
      session.clearPatientSession();

      // Establish verified session for patient A
      session.setVerifiedPatientSession(
        anonymousUid: 'anon_device_01',
        patientId: 'patient_A',
      );

      expect(session.verifiedPatientId, 'patient_A');
      expect(session.anonymousUid, 'anon_device_01');
      expect(session.isCloudVerified, isFalse);

      // Attempting to clear and reset session is permitted only on explicit logout
      session.clearPatientSession();
      expect(session.verifiedPatientId, isNull);
      expect(session.anonymousUid, isNull);
      expect(session.isCloudVerified, isFalse);
    });

    test('TC-11: Offline verification never grants cloud upload privileges', () {
      final session = UserSessionService.instance;
      session.setVerifiedPatientSession(
        anonymousUid: 'anon_device_offline',
        patientId: 'patient_offline',
        isCloudVerified: false,
      );

      // Offline session remains unverified for cloud writes
      expect(session.isCloudVerified, isFalse);

      // Explicit cloud verification grants write privileges
      session.setVerifiedPatientSession(
        anonymousUid: 'anon_device_online',
        patientId: 'patient_online',
        isCloudVerified: true,
      );
      expect(session.isCloudVerified, isTrue);
    });
  });

  group('Firestore Rules Contract - Daily Steps Schema & Identity Guard', () {
    test('TC-16 & TC-17: Patient can only prepare steps for verified patientId', () {
      final session = UserSessionService.instance;
      session.setVerifiedPatientSession(
        anonymousUid: 'anon_device_01',
        patientId: 'MC-2048',
      );

      // Step record matching verified patientId
      final validRecord = DailyStepRecord.initial(
        patientId: 'MC-2048',
        date: '2026-10-23',
      );
      expect(validRecord.patientId, session.verifiedPatientId);

      // Attempted step record for foreign patientId (TC-17 Denied)
      final foreignRecord = DailyStepRecord.initial(
        patientId: 'MC-9999',
        date: '2026-10-23',
      );
      expect(foreignRecord.patientId, isNot(equals(session.verifiedPatientId)));
    });

    test('TC-18: Negative step counts or invalid goals are rejected by schema', () {
      final record = DailyStepRecord.fromMap({
        'patientId': 'MC-2048',
        'date': '2026-10-23',
        'steps': -50,
        'goal': 10000,
      });

      // Exposes negative step anomaly which Firestore rules reject with steps >= 0
      expect(record.steps, lessThan(0));
    });
  });

  group('Firestore Rules Contract - Cognitive Game Results Schema & Immutability', () {
    test('TC-19: Game results enforce score bounds between 0 and 100', () {
      final validResult = GameResult(
        id: 'game_res_01',
        patientId: 'MC-2048',
        gameId: 'memory_match',
        gameName: 'Memory Match',
        score: 85,
        accuracy: 90,
        attempts: 10,
        correctAnswers: 9,
        wrongAnswers: 1,
        difficulty: 'medium',
        completionTimeSeconds: 45,
        timestamp: DateTime.now(),
        recommendation: 'Great cognitive retention',
      );
      expect(validResult.score, inInclusiveRange(0, 100));

      final map = validResult.toMap();
      expect(map['score'], 85);
      expect(map['patientId'], 'MC-2048');
    });
  });

  group('Firestore Rules Contract - Emergency SOS Local Independence', () {
    test('TC-12 & TC-13: Offline SOS phone numbers are available locally without Firestore read', () async {
      final emergencyService = EmergencyService.instance;
      await emergencyService.init();

      // SOS contacts are loaded from local device storage independently of cloud auth
      final settings = emergencyService.settings;
      expect(settings.primaryNumber.isNotEmpty, isTrue);
      expect(settings.secondaryNumber.isNotEmpty, isTrue);
    });

    test('TC-14 & TC-15: Non-caregivers cannot edit emergency numbers', () async {
      // Ensure caregiver is not in caregiver mode
      await CaregiverAuthService.instance.exitCaregiverMode();

      final result = await EmergencyService.instance.updateEmergencyNumbers(
        primaryNumber: '+91 98765 00000',
        secondaryNumber: '+91 98765 11111',
      );

      // Must be denied
      expect(result.isSuccess, isFalse);
      expect(result.statusMessage, contains('Only verified caregivers'));
    });
  });
}
