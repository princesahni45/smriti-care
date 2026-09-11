// test/caregiver_patient_linking_and_games_test.dart
//
// Comprehensive unit tests for:
// 1. Caregiver-Patient code connection (Link, verify, invalid code, disconnect)
// 2. Multi-patient cognitive game telemetry isolation (Patient A vs Patient B)
// 3. Offline storage persistence & stats calculation
//
// Run: flutter test test/caregiver_patient_linking_and_games_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_care/core/models/game_result.dart';
import 'package:smriti_care/core/services/caregiver_service.dart';
import 'package:smriti_care/core/services/game_storage_service.dart';
import 'package:smriti_care/core/services/patient_code_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await CaregiverService.instance.init();
    await GameStorageService.instance.init();
    await PatientCodeService.instance.init();
  });

  group('Caregiver-Patient Linking & Profile Connection', () {
    test('Patient connects to caregiver with valid caregiver code CG-4827-MS', () async {
      final caregiverService = CaregiverService.instance;
      const testPatientId = 'test_patient_linking_01';

      // Attempt to link using canonical caregiver code
      final success = await caregiverService.linkPatientToCaregiver(
        patientId: testPatientId,
        caregiverCodeOrEmail: 'CG-4827-MS',
      );

      expect(success, isTrue);

      final patient = caregiverService.getLinkedPatients().firstWhere(
            (p) => p.id == testPatientId,
          );
      expect(patient.isConnected, isTrue);
      expect(patient.caregiverName, isNotEmpty);
    });

    test('Invalid caregiver code fails connection gracefully without error', () async {
      final caregiverService = CaregiverService.instance;

      final success = await caregiverService.linkPatientToCaregiver(
        patientId: 'test_patient_fail',
        caregiverCodeOrEmail: 'INVALID-999-XYZ',
      );

      expect(success, isFalse);
    });

    test('Disconnecting caregiver removes relationship and marks isConnected false', () async {
      final caregiverService = CaregiverService.instance;
      const testPatientId = 'test_patient_disconnect_01';

      // First link
      await caregiverService.linkPatientToCaregiver(
        patientId: testPatientId,
        caregiverCodeOrEmail: 'CG-4827-MS',
      );

      // Verify connected
      var patient = caregiverService.getLinkedPatients().firstWhere((p) => p.id == testPatientId);
      expect(patient.isConnected, isTrue);

      // Now disconnect
      final disconnectSuccess = await caregiverService.disconnectCaregiver(patientId: testPatientId);
      expect(disconnectSuccess, isTrue);

      patient = caregiverService.getLinkedPatients().firstWhere((p) => p.id == testPatientId);
      expect(patient.isConnected, isFalse);
      expect(patient.caregiverId, isEmpty);
    });
  });

  group('Multi-Patient Game Data Isolation & Statistics', () {
    test('Game results for Patient A do not leak into Patient B statistics', () async {
      final storage = GameStorageService.instance;
      const patientA = 'patient_A_test';
      const patientB = 'patient_B_test';

      final resultA1 = GameResult(
        id: 'test_ga_1',
        patientId: patientA,
        gameId: 'memory-match',
        gameName: 'Memory Match',
        score: 95,
        accuracy: 95,
        attempts: 10,
        correctAnswers: 10,
        wrongAnswers: 0,
        difficulty: 'Level 1',
        completionTimeSeconds: 25,
        timestamp: DateTime.now(),
        recommendation: 'Excellent',
      );

      final resultA2 = GameResult(
        id: 'test_ga_2',
        patientId: patientA,
        gameId: 'word-recall',
        gameName: 'Word Recall',
        score: 85,
        accuracy: 85,
        attempts: 10,
        correctAnswers: 8,
        wrongAnswers: 2,
        difficulty: 'Level 2',
        completionTimeSeconds: 40,
        timestamp: DateTime.now(),
        recommendation: 'Good',
      );

      final resultB1 = GameResult(
        id: 'test_gb_1',
        patientId: patientB,
        gameId: 'memory-match',
        gameName: 'Memory Match',
        score: 40,
        accuracy: 40,
        attempts: 10,
        correctAnswers: 4,
        wrongAnswers: 6,
        difficulty: 'Level 1',
        completionTimeSeconds: 65,
        timestamp: DateTime.now(),
        recommendation: 'Needs practice',
      );

      await storage.saveResult(resultA1);
      await storage.saveResult(resultA2);
      await storage.saveResult(resultB1);

      // Patient A queries
      final resultsA = storage.getRecentResults(patientId: patientA);
      expect(resultsA.any((r) => r.patientId == patientB), isFalse);
      expect(storage.getTotalGamesCompleted(patientId: patientA), 2);
      expect(storage.getAverageAccuracy(patientId: patientA), 90); // (95 + 85) / 2 = 90

      // Patient B queries
      final resultsB = storage.getRecentResults(patientId: patientB);
      expect(resultsB.any((r) => r.patientId == patientA), isFalse);
      expect(storage.getTotalGamesCompleted(patientId: patientB), 1);
      expect(storage.getAverageAccuracy(patientId: patientB), 40);
    });

    test('Caregiver overview metrics update dynamically per active selected patient', () async {
      final caregiver = CaregiverService.instance;
      final storage = GameStorageService.instance;

      const patient1 = 'patient_metrics_1';
      const patient2 = 'patient_metrics_2';

      await storage.saveResult(GameResult(
        id: 'metric_p1',
        patientId: patient1,
        gameId: 'memory-match',
        gameName: 'Memory Match',
        score: 88,
        accuracy: 88,
        attempts: 8,
        correctAnswers: 8,
        wrongAnswers: 0,
        difficulty: 'Level 1',
        completionTimeSeconds: 30,
        timestamp: DateTime.now(),
        recommendation: 'Great job',
      ));

      final metricsP1 = caregiver.getOverviewMetrics(patientId: patient1);
      expect(metricsP1['cognitiveScore'], '88 / 100');
      expect(metricsP1['gamesCompleted'], '1 completed');

      final metricsP2 = caregiver.getOverviewMetrics(patientId: patient2);
      expect(metricsP2['cognitiveScore'], 'No activity');
      expect(metricsP2['gamesCompleted'], '0 completed');
    });
  });
}
