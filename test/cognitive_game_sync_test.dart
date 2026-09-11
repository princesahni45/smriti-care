// test/cognitive_game_sync_test.dart
//
// FIX: Save cognitive game result for caregiver dashboard
//
// Tests for cognitive game scoring, multi-patient isolation,
// and real-time synchronization with Caregiver Dashboard.

import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_care/core/models/game_result.dart';
import 'package:smriti_care/core/services/game_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cognitive Game Sync & Isolation Tests', () {
    test('GameResult calculates percentage and aliases correctly', () {
      final now = DateTime.now();
      final result = GameResult(
        id: 'result-123',
        gameId: 'memory_match',
        gameName: 'Memory Match',
        score: 85,
        maxScore: 100,
        accuracy: 85,
        attempts: 10,
        correctAnswers: 8,
        wrongAnswers: 2,
        difficulty: 'Easy',
        completionTimeSeconds: 45,
        patientId: 'PATIENT-001',
        timestamp: now,
        recommendation: 'Good job',
        syncStatus: 'pending',
      );

      // FIX: Save cognitive game result for caregiver dashboard
      expect(result.percentage, equals(85.0));
      expect(result.scoreId, equals('result-123'));
      expect(result.completedAt, equals(now));
      expect(result.gameType, equals('memory_match'));
      expect(result.syncStatus, equals('pending'));
    });

    test('GameResult toMap and fromMap serialization preserves all fields', () {
      final now = DateTime(2026, 9, 11, 10, 30);
      final result = GameResult(
        id: 'res-456',
        gameId: 'word_recall',
        gameName: 'Word Recall',
        score: 90,
        maxScore: 100,
        accuracy: 90,
        attempts: 10,
        correctAnswers: 9,
        wrongAnswers: 1,
        difficulty: 'Medium',
        completionTimeSeconds: 60,
        patientId: 'PATIENT-002',
        timestamp: now,
        recommendation: 'Excellent recall',
        syncStatus: 'synced',
      );

      final map = result.toMap();
      final fromMap = GameResult.fromMap(map);

      expect(fromMap.id, equals('res-456'));
      expect(fromMap.gameId, equals('word_recall'));
      expect(fromMap.score, equals(90));
      expect(fromMap.maxScore, equals(100));
      expect(fromMap.patientId, equals('PATIENT-002'));
      expect(fromMap.percentage, equals(90.0));
      expect(fromMap.syncStatus, equals('synced'));
    });

    test('Multiple patients results are strictly isolated', () async {
      final storage = GameStorageService.instance;

      final p1Result = GameResult(
        id: 'p1-score-1',
        gameId: 'orientation',
        gameName: 'Day & Time Orientation',
        score: 100,
        maxScore: 100,
        accuracy: 100,
        attempts: 5,
        correctAnswers: 5,
        wrongAnswers: 0,
        difficulty: 'Easy',
        completionTimeSeconds: 30,
        patientId: 'PATIENT-A',
        timestamp: DateTime.now(),
        recommendation: 'Perfect',
      );

      final p2Result = GameResult(
        id: 'p2-score-1',
        gameId: 'routine',
        gameName: 'Daily Routine Steps',
        score: 75,
        maxScore: 100,
        accuracy: 75,
        attempts: 8,
        correctAnswers: 6,
        wrongAnswers: 2,
        difficulty: 'Medium',
        completionTimeSeconds: 50,
        patientId: 'PATIENT-B',
        timestamp: DateTime.now(),
        recommendation: 'Practice needed',
      );

      await storage.saveResult(p1Result);
      await storage.saveResult(p2Result);

      final p1Scores = storage.getHistory(patientId: 'PATIENT-A');
      final p2Scores = storage.getHistory(patientId: 'PATIENT-B');

      expect(p1Scores.any((s) => s.patientId == 'PATIENT-A'), isTrue);
      expect(p1Scores.any((s) => s.patientId == 'PATIENT-B'), isFalse);

      expect(p2Scores.any((s) => s.patientId == 'PATIENT-B'), isTrue);
      expect(p2Scores.any((s) => s.patientId == 'PATIENT-A'), isFalse);
    });

    test('Caregiver can read latest result and 7-day average score', () async {
      final storage = GameStorageService.instance;
      const testPatient = 'PATIENT-STATS-TEST';

      await storage.saveResult(GameResult(
        id: 'stat-1',
        gameId: 'memory_match',
        gameName: 'Memory Match',
        score: 80,
        maxScore: 100,
        accuracy: 80,
        attempts: 10,
        correctAnswers: 8,
        wrongAnswers: 2,
        difficulty: 'Easy',
        completionTimeSeconds: 40,
        patientId: testPatient,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        recommendation: 'Good',
      ));

      await storage.saveResult(GameResult(
        id: 'stat-2',
        gameId: 'word_recall',
        gameName: 'Word Recall',
        score: 90,
        maxScore: 100,
        accuracy: 90,
        attempts: 10,
        correctAnswers: 9,
        wrongAnswers: 1,
        difficulty: 'Medium',
        completionTimeSeconds: 45,
        patientId: testPatient,
        timestamp: DateTime.now(),
        recommendation: 'Excellent',
      ));

      final avg = storage.get7DayAverageScore(patientId: testPatient);
      final latest = storage.getLatestGameResult(patientId: testPatient);

      expect(avg, equals(85.0));
      expect(latest, isNotNull);
      expect(latest?.gameId, equals('word_recall'));
      expect(latest?.score, equals(90));
    });
  });
}
