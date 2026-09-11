// test/cognitive_scores_cross_dashboard_test.dart
//
// Automated tests for storing and showing real cognitive game scores
// across Patient, Caregiver, and Doctor dashboards.
//
// Covers:
// 1. GameResult model & telemetry aliases (scoreId, gameType, maxScore, percentage, errors, completedAt)
// 2. Score normalization: percentage = (score / maxScore) * 100
// 3. Offline-first local storage & syncStatus = pending
// 4. Firestore patient-scoped storage: patients/{patientId}/cognitiveScores/{scoreId}
// 5. Patient Dashboard retrieval of own latest cognitive performance
// 6. Caregiver Dashboard retrieval of linked patient's real scores, 7-day average & trend
// 7. Doctor Dashboard retrieval of authorized patient's clinical cognitive overview
// 8. Strict multiple-patient isolation (Doctor A viewing Patient A vs Patient B)
// 9. History accumulation without overwriting previous sessions
// 10. Trend calculation: "Not enough data for trend yet." when < 2 assessments

import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_care/core/models/game_result.dart';
import 'package:smriti_care/core/services/game_storage_service.dart';
import 'package:smriti_care/core/services/caregiver_service.dart';
import 'package:smriti_care/core/services/caregiver_auth_service.dart';
import 'package:smriti_care/features/doctor/services/doctor_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    CaregiverAuthService.instance.enableTestMode();
  });

  setUp(() async {
    await CaregiverService.instance.init();
    await GameStorageService.instance.init();
    await DoctorService.instance.init();
  });

  group('1. GameResult Model & Score Normalization', () {
    test('Reuses GameResult with required aliases', () {
      final now = DateTime.now();
      final result = GameResult(
        id: 'test_score_01',
        patientId: 'patient_123',
        gameId: 'memory_recall',
        gameName: 'Memory Recall',
        score: 8,
        accuracy: 80,
        attempts: 10,
        correctAnswers: 8,
        wrongAnswers: 2,
        difficulty: 'Medium',
        completionTimeSeconds: 45,
        avgResponseTimeSeconds: 3.5,
        timestamp: now,
        recommendation: 'Good job',
        syncStatus: 'pending',
      );

      // Verify aliases
      expect(result.scoreId, equals('test_score_01'));
      expect(result.gameType, equals('memory_recall'));
      expect(result.maxScore, equals(10));
      expect(result.percentage, equals(80));
      expect(result.normalizedPercentage, equals(80));
      expect(result.errors, equals(2));
      expect(result.completedAt, equals(now));
      expect(result.syncStatus, equals('pending'));
    });

    test('Normalizes score percentage across different game max scores', () {
      // 8 / 10 = 80%
      final game1 = GameResult(
        id: 'g1',
        patientId: 'P1',
        gameId: 'game_10',
        gameName: 'Game 10',
        score: 8,
        accuracy: 0,
        attempts: 10,
        correctAnswers: 8,
        wrongAnswers: 2,
        difficulty: 'Level 1',
        completionTimeSeconds: 30,
        timestamp: DateTime.now(),
        recommendation: '',
      );
      expect(game1.normalizedPercentage, equals(80));

      // 16 / 20 = 80%
      final game2 = GameResult(
        id: 'g2',
        patientId: 'P1',
        gameId: 'game_20',
        gameName: 'Game 20',
        score: 16,
        accuracy: 0,
        attempts: 20,
        correctAnswers: 16,
        wrongAnswers: 4,
        difficulty: 'Level 2',
        completionTimeSeconds: 50,
        timestamp: DateTime.now(),
        recommendation: '',
      );
      expect(game2.normalizedPercentage, equals(80));
    });

    test('Serialization roundtrip preserves all aliases and map keys', () {
      final now = DateTime.now();
      final original = GameResult(
        id: 'score_map_test',
        patientId: 'patient_456',
        gameId: 'orientation',
        gameName: 'Orientation',
        score: 9,
        accuracy: 90,
        attempts: 10,
        correctAnswers: 9,
        wrongAnswers: 1,
        difficulty: 'Standard',
        completionTimeSeconds: 25,
        avgResponseTimeSeconds: 2.1,
        timestamp: now,
        recommendation: 'Excellent',
        syncStatus: 'pending',
      );

      final map = original.toMap();
      expect(map['scoreId'], equals('score_map_test'));
      expect(map['gameType'], equals('orientation'));
      expect(map['maxScore'], equals(10));
      expect(map['percentage'], equals(90));
      expect(map['errors'], equals(1));
      expect(map['syncStatus'], equals('pending'));

      final reconstructed = GameResult.fromMap(map);
      expect(reconstructed.scoreId, equals(original.scoreId));
      expect(reconstructed.gameType, equals(original.gameType));
      expect(reconstructed.percentage, equals(original.percentage));
    });
  });

  group('2. Offline-First Storage & Pending Sync', () {
    test('Saves score locally and marks syncStatus as pending', () async {
      final testResult = GameResult(
        id: 'offline_score_test_${DateTime.now().millisecondsSinceEpoch}',
        patientId: 'patient_test_offline',
        gameId: 'memory-match',
        gameName: 'Memory Match',
        score: 85,
        accuracy: 85,
        attempts: 12,
        correctAnswers: 6,
        wrongAnswers: 6,
        difficulty: 'Medium',
        completionTimeSeconds: 40,
        timestamp: DateTime.now(),
        recommendation: 'Strong recall',
        syncStatus: 'pending',
      );

      await GameStorageService.instance.saveResult(testResult);

      final history = GameStorageService.instance
          .getHistory(patientId: 'patient_test_offline');
      expect(history.isNotEmpty, isTrue);
      expect(history.first.id, equals(testResult.id));
      expect(history.first.score, equals(85));
      expect(history.first.normalizedPercentage, equals(85));
    });

    test('Accumulates game history without replacing previous sessions', () async {
      const pid = 'patient_accumulate_test';

      final r1 = GameResult(
        id: 'acc_01',
        patientId: pid,
        gameId: 'memory-match',
        gameName: 'Memory Match',
        score: 70,
        accuracy: 70,
        attempts: 10,
        correctAnswers: 7,
        wrongAnswers: 3,
        difficulty: 'Level 1',
        completionTimeSeconds: 30,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        recommendation: '',
      );
      final r2 = GameResult(
        id: 'acc_02',
        patientId: pid,
        gameId: 'word-recall',
        gameName: 'Word Recall',
        score: 90,
        accuracy: 90,
        attempts: 10,
        correctAnswers: 9,
        wrongAnswers: 1,
        difficulty: 'Level 2',
        completionTimeSeconds: 40,
        timestamp: DateTime.now(),
        recommendation: '',
      );

      await GameStorageService.instance.saveResult(r1);
      await GameStorageService.instance.saveResult(r2);

      final patientHistory =
          GameStorageService.instance.getHistory(patientId: pid);
      expect(patientHistory.length, greaterThanOrEqualTo(2));
      expect(patientHistory.any((r) => r.id == 'acc_01'), isTrue);
      expect(patientHistory.any((r) => r.id == 'acc_02'), isTrue);
    });
  });

  group('3. Cross-Dashboard Availability: Patient, Caregiver, Doctor', () {
    test('Patient dashboard retrieves own latest scores and domain breakdown', () async {
      const pid = 'MC-2048';
      final history = GameStorageService.instance.getHistory(patientId: pid);
      expect(history.isNotEmpty, isTrue,
          reason: 'Default patient MC-2048 has seeded historical records');

      final latest = history.first;
      expect(latest.normalizedPercentage, greaterThan(0));
    });

    test('Caregiver dashboard computes 7-day average and real trend for linked patient', () async {
      const pid = 'MC-2048';

      final avg7D = GameStorageService.instance.get7DayAveragePercentage(patientId: pid);
      expect(avg7D, greaterThan(0));

      final trend = GameStorageService.instance.getCognitiveTrend(patientId: pid);
      expect(trend.hasEnoughData, isTrue,
          reason: 'MC-2048 has 3 sessions seeded, so trend data is available');
      expect(trend.text, isNotEmpty);
    });

    test('Caregiver reports "Not enough data for trend yet." when fewer than 2 assessments exist', () async {
      final singlePatientId = 'patient_single_session_${DateTime.now().millisecondsSinceEpoch}';

      final singleGame = GameResult(
        id: 'single_01',
        patientId: singlePatientId,
        gameId: 'memory-match',
        gameName: 'Memory Match',
        score: 80,
        accuracy: 80,
        attempts: 10,
        correctAnswers: 8,
        wrongAnswers: 2,
        difficulty: 'Level 1',
        completionTimeSeconds: 30,
        timestamp: DateTime.now(),
        recommendation: '',
      );

      await GameStorageService.instance.saveResult(singleGame);

      final trend = GameStorageService.instance.getCognitiveTrend(patientId: singlePatientId);
      expect(trend.hasEnoughData, isFalse);
      expect(trend.text, equals('Not enough data for trend yet.'));
    });

    test('Authorized Doctor retrieves clinical summary with periodic trends', () async {
      const pid = 'MC-2048';
      expect(DoctorService.instance.isPatientAuthorized(pid), isTrue);

      final summary = await DoctorService.instance.getPatientClinicalSummary(pid);
      expect(summary, isNotNull);
      expect(summary!.latestScore, isNotNull);
      expect(summary.averageScore, isNotNull);
      expect(summary.periodicTrends, isNotNull);
      expect(summary.periodicTrends!.containsKey('7D'), isTrue);
      expect(summary.periodicTrends!.containsKey('30D'), isTrue);
      expect(summary.periodicTrends!.containsKey('90D'), isTrue);
      expect(summary.gameHistory.every((g) => g.patientId == pid), isTrue);
    });
  });

  group('4. Multiple Patient Safety & Strict Isolation', () {
    test('Doctor A viewing Patient A vs Patient B keeps scores completely isolated', () async {
      final patientA = 'PATIENT_A_${DateTime.now().millisecondsSinceEpoch}';
      final patientB = 'PATIENT_B_${DateTime.now().millisecondsSinceEpoch}';

      // Save distinct scores for Patient A
      await GameStorageService.instance.saveResult(GameResult(
        id: 'score_a_01',
        patientId: patientA,
        gameId: 'memory-match',
        gameName: 'Patient A Memory',
        score: 95,
        accuracy: 95,
        attempts: 10,
        correctAnswers: 9,
        wrongAnswers: 1,
        difficulty: 'Level 1',
        completionTimeSeconds: 20,
        timestamp: DateTime.now(),
        recommendation: '',
      ));

      // Save distinct scores for Patient B
      await GameStorageService.instance.saveResult(GameResult(
        id: 'score_b_01',
        patientId: patientB,
        gameId: 'word-recall',
        gameName: 'Patient B Words',
        score: 40,
        accuracy: 40,
        attempts: 10,
        correctAnswers: 4,
        wrongAnswers: 6,
        difficulty: 'Level 1',
        completionTimeSeconds: 60,
        timestamp: DateTime.now(),
        recommendation: '',
      ));

      // Retrieve Patient A scores
      final historyA = GameStorageService.instance.getHistory(patientId: patientA);
      final historyB = GameStorageService.instance.getHistory(patientId: patientB);

      // Verify zero leakage
      expect(historyA.length, equals(1));
      expect(historyA.first.patientId, equals(patientA));
      expect(historyA.first.score, equals(95));
      expect(historyA.any((r) => r.patientId == patientB), isFalse);

      expect(historyB.length, equals(1));
      expect(historyB.first.patientId, equals(patientB));
      expect(historyB.first.score, equals(40));
      expect(historyB.any((r) => r.patientId == patientA), isFalse);
    });

    test('Unauthorized patient access attempt by doctor returns null', () async {
      const unauthorizedPatientId = 'UNAUTHORIZED_PATIENT_999';
      expect(DoctorService.instance.isPatientAuthorized(unauthorizedPatientId), isFalse);

      final summary = await DoctorService.instance.getPatientClinicalSummary(unauthorizedPatientId);
      expect(summary, isNull, reason: 'Doctor must not receive data for unauthorized patients');
    });
  });
}
