// test/games_migration_test.dart
//
// Comprehensive unit and widget tests for SmritiCare Cognitive Games.
// Tests:
// 1. GameResult model serialization & deserialization
// 2. GameStorageService adaptive difficulty calculations (Step 13)
// 3. Adaptive non-clinical recommendations
// 4. GamesHubScreen rendering & catalog verification
// 5. GameResultScreen metric presentation & action buttons

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_care/core/models/game_result.dart';
import 'package:smriti_care/core/services/game_storage_service.dart';
import 'package:smriti_care/features/games/games_hub_screen.dart';
import 'package:smriti_care/features/games/game_result_screen.dart';

void main() {
  group('GameResult Model Tests', () {
    test('GameResult serializes to Map and deserializes correctly', () {
      final now = DateTime(2026, 9, 10, 14, 30);
      final result = GameResult(
        id: 'result-1',
        gameId: 'memory-match',
        gameName: 'Memory Match',
        score: 85,
        accuracy: 90,
        attempts: 10,
        correctAnswers: 9,
        wrongAnswers: 1,
        difficulty: 'Level 2',
        completionTimeSeconds: 45,
        timestamp: now,
        recommendation: 'Wonderful job! You have unlocked Level 3.',
      );

      final map = result.toMap();
      expect(map['gameId'], 'memory-match');
      expect(map['score'], 85);
      expect(map['accuracy'], 90);
      expect(map['attempts'], 10);
      expect(map['correctAnswers'], 9);
      expect(map['wrongAnswers'], 1);
      expect(map['difficulty'], 'Level 2');
      expect(map['completionTimeSeconds'], 45);
      expect(map['recommendation'], contains('unlocked Level 3'));

      final restored = GameResult.fromMap(map);
      expect(restored.gameId, result.gameId);
      expect(restored.score, result.score);
      expect(restored.accuracy, result.accuracy);
      expect(restored.attempts, result.attempts);
      expect(restored.correctAnswers, result.correctAnswers);
      expect(restored.wrongAnswers, result.wrongAnswers);
      expect(restored.difficulty, result.difficulty);
      expect(restored.completionTimeSeconds, result.completionTimeSeconds);
      expect(restored.recommendation, result.recommendation);
    });

    test('GameResult handles missing or null fields gracefully', () {
      final emptyMap = <String, dynamic>{};
      final result = GameResult.fromMap(emptyMap);
      expect(result.gameId, 'unknown');
      expect(result.gameName, 'Activity');
      expect(result.score, 0);
      expect(result.accuracy, 0);
      expect(result.difficulty, 'Level 1');
      expect(result.completionTimeSeconds, 0);
    });
  });

  group('Adaptive Difficulty Engine Tests (Step 13)', () {
    test('Accuracy >= 80% promotes player up to level 3', () {
      expect(GameStorageService.calculateNextLevel(80, 1), 2);
      expect(GameStorageService.calculateNextLevel(95, 2), 3);
      // Caps at level 3
      expect(GameStorageService.calculateNextLevel(100, 3), 3);
    });

    test('Accuracy between 50% and 79% maintains current difficulty', () {
      expect(GameStorageService.calculateNextLevel(50, 1), 1);
      expect(GameStorageService.calculateNextLevel(65, 2), 2);
      expect(GameStorageService.calculateNextLevel(79, 3), 3);
    });

    test('Accuracy < 50% gently demotes player down to level 1', () {
      expect(GameStorageService.calculateNextLevel(40, 3), 2);
      expect(GameStorageService.calculateNextLevel(30, 2), 1);
      // Floors at level 1
      expect(GameStorageService.calculateNextLevel(10, 1), 1);
      expect(GameStorageService.calculateNextLevel(0, 1), 1);
    });

    test('Adaptive recommendations are encouraging and non-clinical', () {
      final service = GameStorageService.instance;

      final highLevelRec = service.getAdaptiveRecommendation('memory-match', 85, 1);
      expect(highLevelRec, contains('unlocked Level 2'));
      expect(highLevelRec, isNot(contains('dementia')));
      expect(highLevelRec, isNot(contains('impairment')));

      final mediumRec = service.getAdaptiveRecommendation('word-recall', 65, 2);
      expect(mediumRec, contains('Practicing Level 2 again'));

      final lowRec = service.getAdaptiveRecommendation('different-object', 30, 2);
      expect(lowRec, contains('Level 1 is recommended'));
    });
  });

  group('GamesHubScreen Widget Tests', () {
    testWidgets('Renders all 3 migrated cognitive activities and headers',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GamesHubScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Cognitive Activities'), findsOneWidget);
      expect(find.text('Gentle Brain Fitness'), findsOneWidget);
      expect(find.text('Available Activities'), findsOneWidget);

      // Verify the 3 ported games
      expect(find.text('Memory Match'), findsOneWidget);
      expect(find.text('Word Recall & Delayed Memory'), findsOneWidget);
      expect(find.text('Find the Different Object'), findsOneWidget);

      // Verify play buttons
      expect(find.text('Play Memory Match'), findsOneWidget);
      expect(find.text('Play Word Recall & Delayed Memory'), findsOneWidget);
      expect(find.text('Play Find the Different Object'), findsOneWidget);

      // Verify Upcoming Roadmap
      expect(find.text('Coming in Future Updates'), findsOneWidget);
    });
  });

  group('GameResultScreen Widget Tests', () {
    testWidgets('Renders celebratory metrics and navigation options',
        (WidgetTester tester) async {
      var playAgainTapped = false;
      var backToGamesTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: GameResultScreen(
            result: GameResult(
              id: 'res-test-1',
              gameId: 'memory-match',
              gameName: 'Memory Match',
              score: 90,
              accuracy: 90,
              attempts: 8,
              correctAnswers: 8,
              wrongAnswers: 0,
              difficulty: 'Level 2',
              completionTimeSeconds: 42,
              timestamp: DateTime.now(),
              recommendation: 'Wonderful job! You have unlocked Level 3.',
            ),
            onPlayAgain: () {
              playAgainTapped = true;
            },
            onBackToGames: () {
              backToGamesTapped = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check celebrations & score
      expect(find.text('Activity Complete!'), findsOneWidget);
      expect(find.text('90%'), findsOneWidget);
      expect(find.text('Level 2'), findsOneWidget);
      expect(find.text('Wonderful job! You have unlocked Level 3.'), findsOneWidget);

      // Tap Play Again
      await tester.ensureVisible(find.text('Play Again'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Play Again'));
      expect(playAgainTapped, isTrue);

      // Tap Back to Games
      await tester.ensureVisible(find.text('Back to Games'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back to Games'));
      expect(backToGamesTapped, isTrue);
    });
  });
}
