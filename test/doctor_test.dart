// test/doctor_test.dart
//
// Automated unit and workflow tests for SmritiCare Doctor Dashboard.
// Covers:
//   1. Doctor Authentication & Credentials
//   2. Role rejection (Caregiver / Patient cannot access Doctor portal)
//   3. Session management & Exit Doctor Mode
//   4. Secure Patient Linking Flow (Code generation, request submission, caregiver approval, revocation)
//   5. Multi-Patient Isolation & Privacy (No cross-patient data leaks)
//   6. Doctor Notes CRUD & Author Isolation
//   7. Attention Status & Smart Alerts Engine
//
// Run: flutter test test/doctor_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_care/core/models/game_result.dart';
import 'package:smriti_care/core/models/mri_models.dart';
import 'package:smriti_care/core/services/caregiver_auth_service.dart';
import 'package:smriti_care/features/doctor/models/doctor_models.dart';
import 'package:smriti_care/features/doctor/services/doctor_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    CaregiverAuthService.instance.enableTestMode();
  });

  setUp(() async {
    await CaregiverAuthService.instance.exitDoctorMode();
    await DoctorService.instance.init();
  });

  tearDown(() async {
    await CaregiverAuthService.instance.exitDoctorMode();
  });

  group('1. Doctor Authentication & Role Isolation', () {
    test('TEST 1.1: Valid doctor credentials authenticate successfully',
        () async {
      final result = await CaregiverAuthService.instance.loginDoctor(
        email: 'doctor@smriti.care',
        password: 'password123',
      );

      expect(result.isSuccess, isTrue,
          reason:
              'doctor@smriti.care / password123 must authenticate in test mode.');
      expect(CaregiverAuthService.instance.isDoctorAuthenticated, isTrue);
      expect(CaregiverAuthService.instance.currentMode, DashboardMode.doctor);
      expect(CaregiverAuthService.instance.doctorUid, 'test_doctor_uid_01');
      expect(CaregiverAuthService.instance.doctorName, 'Dr. Ananya Bora');
    });

    test('TEST 1.2: Caregiver account is strictly rejected from Doctor Login',
        () async {
      final result = await CaregiverAuthService.instance.loginDoctor(
        email: 'caregiver@smriti.care',
        password: 'password123',
      );

      expect(result.isSuccess, isFalse,
          reason:
              'Caregiver account must not be able to log in to Doctor Portal.');
      expect(result.errorMessage, contains('does not have doctor access'));
      expect(CaregiverAuthService.instance.isDoctorAuthenticated, isFalse);
    });

    test('TEST 1.3: Patient account is strictly rejected from Doctor Login',
        () async {
      final result = await CaregiverAuthService.instance.loginDoctor(
        email: 'patient@smriti.care',
        password: 'password123',
      );

      expect(result.isSuccess, isFalse,
          reason:
              'Patient account must not be able to log in to Doctor Portal.');
      expect(result.errorMessage, contains('does not have doctor access'));
      expect(CaregiverAuthService.instance.isDoctorAuthenticated, isFalse);
    });

    test('TEST 1.4: Invalid password fails authentication', () async {
      final result = await CaregiverAuthService.instance.loginDoctor(
        email: 'doctor@smriti.care',
        password: 'wrongpassword',
      );

      expect(result.isSuccess, isFalse);
      expect(CaregiverAuthService.instance.isDoctorAuthenticated, isFalse);
    });

    test('TEST 1.5: Exit doctor mode cleans up session', () async {
      await CaregiverAuthService.instance.loginDoctor(
        email: 'doctor@smriti.care',
        password: 'password123',
      );
      expect(CaregiverAuthService.instance.isDoctorAuthenticated, isTrue);

      await CaregiverAuthService.instance.exitDoctorMode();

      expect(CaregiverAuthService.instance.isDoctorAuthenticated, isFalse);
      expect(CaregiverAuthService.instance.currentMode, DashboardMode.patient);
      expect(CaregiverAuthService.instance.doctorUid, isNull);
    });
  });

  group('2. Secure Patient Linking & Permission Flow', () {
    test('TEST 2.1: Caregiver generates link code and Doctor requests link',
        () async {
      await CaregiverAuthService.instance.loginDoctor(
        email: 'doctor@smriti.care',
        password: 'password123',
      );

      final uniquePatientId =
          'MC-TEMP-${DateTime.now().microsecondsSinceEpoch}';
      final code =
          DoctorService.instance.generateOrGetLinkCode(uniquePatientId);
      expect(code, isNotEmpty);

      // Submit link request
      final result = await DoctorService.instance.requestPatientLink(code);
      expect(result.success, isTrue, reason: result.message);

      // Verify pending request exists for patient
      final pendingLinks =
          DoctorService.instance.getPendingRequestsForPatient(uniquePatientId);
      expect(
          pendingLinks
              .any((l) => l.doctorId == DoctorService.instance.currentDoctorId),
          isTrue);
    });

    test('TEST 2.2: Caregiver approves link -> Doctor gets patient access',
        () async {
      await CaregiverAuthService.instance.loginDoctor(
        email: 'doctor@smriti.care',
        password: 'password123',
      );

      final pendingLinks =
          DoctorService.instance.getPendingRequestsForPatient('MC-2048');
      if (pendingLinks.isNotEmpty) {
        final link = pendingLinks.first;
        await DoctorService.instance.approvePatientLink(link.linkId);
      }

      // Doctor queries authorized patients
      final patients = await DoctorService.instance.getAuthorizedPatients();
      expect(patients.any((p) => p.id == 'MC-2048'), isTrue);
      expect(DoctorService.instance.isPatientAuthorized('MC-2048'), isTrue);
    });

    test('TEST 2.3: Revoking link immediately denies doctor access', () async {
      await CaregiverAuthService.instance.loginDoctor(
        email: 'doctor@smriti.care',
        password: 'password123',
      );

      final approvedLinks =
          DoctorService.instance.getApprovedLinksForPatient('MC-3109');
      if (approvedLinks.isNotEmpty) {
        final link = approvedLinks.first;
        expect(DoctorService.instance.isPatientAuthorized('MC-3109'), isTrue);

        // Caregiver revokes access
        await DoctorService.instance.revokePatientLink(link.linkId);
        expect(DoctorService.instance.isPatientAuthorized('MC-3109'), isFalse);
      }
    });

    test('TEST 2.4: Invalid link code returns failure and does not link',
        () async {
      await CaregiverAuthService.instance.loginDoctor(
        email: 'doctor@smriti.care',
        password: 'password123',
      );

      final result =
          await DoctorService.instance.requestPatientLink('INVALID_CODE_123');
      expect(result.success, isFalse);
    });
  });

  group('3. Multi-Patient Isolation & Privacy', () {
    test('TEST 3.1: Doctor only sees patients with approved links', () async {
      await CaregiverAuthService.instance.loginDoctor(
        email: 'doctor@smriti.care',
        password: 'password123',
      );

      final patients = await DoctorService.instance.getAuthorizedPatients();
      for (final p in patients) {
        expect(DoctorService.instance.isPatientAuthorized(p.id), isTrue);
      }
    });

    test('TEST 3.2: Clinical notes are strictly isolated per patient',
        () async {
      await CaregiverAuthService.instance.loginDoctor(
        email: 'doctor@smriti.care',
        password: 'password123',
      );

      await DoctorService.instance.addDoctorNote(
        patientId: 'MC-2048',
        text: 'Patient 2048 specific neurological note.',
      );

      final p1Notes = DoctorService.instance.getDoctorNotes('MC-2048');
      final p2Notes = DoctorService.instance.getDoctorNotes('MC-3109');

      expect(
          p1Notes
              .any((n) => n.text == 'Patient 2048 specific neurological note.'),
          isTrue);
      expect(
          p2Notes
              .any((n) => n.text == 'Patient 2048 specific neurological note.'),
          isFalse);
    });
  });

  group('4. Doctor Notes CRUD & Author Permissions', () {
    test('TEST 4.1: Doctor can add, edit, and delete their own notes',
        () async {
      await CaregiverAuthService.instance.loginDoctor(
        email: 'doctor@smriti.care',
        password: 'password123',
      );

      await DoctorService.instance.addDoctorNote(
        patientId: 'MC-2048',
        text: 'Initial Consultation Note',
      );

      final notes = DoctorService.instance.getDoctorNotes('MC-2048');
      final note =
          notes.firstWhere((n) => n.text == 'Initial Consultation Note');
      expect(note.noteId, isNotEmpty);

      // Edit note
      final updated = await DoctorService.instance.updateDoctorNote(
        noteId: note.noteId,
        newText: 'Updated Consultation Note with Recommendations',
      );
      expect(updated, isTrue);

      final retrieved = DoctorService.instance
          .getDoctorNotes('MC-2048')
          .firstWhere((n) => n.noteId == note.noteId);
      expect(retrieved.text, 'Updated Consultation Note with Recommendations');

      // Delete note
      final deleted = await DoctorService.instance.deleteDoctorNote(
        noteId: note.noteId,
      );
      expect(deleted, isTrue);

      final remaining = DoctorService.instance
          .getDoctorNotes('MC-2048')
          .where((n) => n.noteId == note.noteId);
      expect(remaining.isEmpty, isTrue);
    });
  });

  group('5. Attention Status & Smart Alerts Engine', () {
    test('TEST 5.1: Attention status evaluation logic is deterministic', () {
      final now = DateTime.now();

      // Stable: improving score (+10)
      final stableStatus = DoctorService.instance.calculateAttentionStatus(
        'MC-2048',
        [
          GameResult(
            id: 'res-1',
            patientId: 'MC-2048',
            gameId: 'pattern_recall',
            gameName: 'Pattern Recall',
            score: 85,
            accuracy: 85,
            attempts: 10,
            correctAnswers: 9,
            wrongAnswers: 1,
            difficulty: 'normal',
            completionTimeSeconds: 60,
            timestamp: now,
            recommendation: 'Good',
          ),
          GameResult(
            id: 'res-2',
            patientId: 'MC-2048',
            gameId: 'pattern_recall',
            gameName: 'Pattern Recall',
            score: 75,
            accuracy: 75,
            attempts: 10,
            correctAnswers: 8,
            wrongAnswers: 2,
            difficulty: 'normal',
            completionTimeSeconds: 60,
            timestamp: now.subtract(const Duration(days: 3)),
            recommendation: 'Normal',
          ),
        ],
        [],
      );
      expect(stableStatus.level, PatientAttentionLevel.stable);

      // Review Suggested: score drop of 10 points (<= -5 threshold)
      final dropStatus = DoctorService.instance.calculateAttentionStatus(
        'MC-2048',
        [
          GameResult(
            id: 'res-3',
            patientId: 'MC-2048',
            gameId: 'pattern_recall',
            gameName: 'Pattern Recall',
            score: 65,
            accuracy: 65,
            attempts: 10,
            correctAnswers: 6,
            wrongAnswers: 4,
            difficulty: 'normal',
            completionTimeSeconds: 60,
            timestamp: now,
            recommendation: 'Review',
          ),
          GameResult(
            id: 'res-4',
            patientId: 'MC-2048',
            gameId: 'pattern_recall',
            gameName: 'Pattern Recall',
            score: 75,
            accuracy: 75,
            attempts: 10,
            correctAnswers: 8,
            wrongAnswers: 2,
            difficulty: 'normal',
            completionTimeSeconds: 60,
            timestamp: now.subtract(const Duration(days: 3)),
            recommendation: 'Normal',
          ),
        ],
        [],
      );
      expect(dropStatus.level, PatientAttentionLevel.reviewSuggested);

      // Review Suggested: unreviewed completed MRI scan
      final mriStatus = DoctorService.instance.calculateAttentionStatus(
        'MC-2048',
        [],
        [
          MriScanResult(
            scanId: 'mri-999',
            patientId: 'MC-2048',
            prediction: 'Mild Cognitive Impairment',
            predictionClass: MriPredictionClass.veryMild,
            confidenceScore: 0.88,
            recommendation: 'Consult doctor',
            status: 'completed',
            timestamp: now,
            serverUrl: 'http://localhost:5000',
            reviewedByDoctorId: null,
          ),
        ],
      );
      expect(mriStatus.level, PatientAttentionLevel.reviewSuggested);

      // Insufficient Data: 0 or 1 session
      final insufficientStatus =
          DoctorService.instance.calculateAttentionStatus(
        'MC-2048',
        [],
        [],
      );
      expect(insufficientStatus.level, PatientAttentionLevel.insufficientData);
    });

    test('TEST 5.2: Smart alerts generate actionable notifications', () async {
      await CaregiverAuthService.instance.loginDoctor(
        email: 'doctor@smriti.care',
        password: 'password123',
      );

      final alerts = await DoctorService.instance.generateSmartAlerts();
      expect(alerts, isA<List<DoctorSmartAlert>>());
      for (final alert in alerts) {
        expect(alert.patientId, isNotEmpty);
        expect(alert.patientName, isNotEmpty);
        expect(alert.title, isNotEmpty);
        expect(alert.message, isNotEmpty);
      }
    });
  });
}
