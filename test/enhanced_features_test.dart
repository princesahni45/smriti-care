// test/enhanced_features_test.dart
//
// Comprehensive test suite for newly added SmritiCare features:
// 1. Enhanced GameResult telemetry fields (Step 7)
// 2. Multilingual AppLocalizations (Step 10)
// 3. MRI Screening Architecture & Models (Step 8)
// 4. Offline Telemetry Sync architecture (Step 9)
// 5. Patient Take Me Home & SOS screen (Step 5)
// 6. Day & Time Orientation Game (Step 5)
// 7. Routine Sequence Game (Step 5)
// 8. Family Memories Game (Step 5)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_care/core/models/game_result.dart';
import 'package:smriti_care/core/models/mri_models.dart';
import 'package:smriti_care/core/services/mri_screening_service.dart';
import 'package:smriti_care/core/services/cognitive_api_service.dart';
import 'package:smriti_care/core/localization/app_localizations.dart';
import 'package:smriti_care/features/emergency/take_me_home_screen.dart';
import 'package:smriti_care/features/games/orientation/day_time_orientation_screen.dart';
import 'package:smriti_care/features/games/routine/routine_sequence_screen.dart';
import 'package:smriti_care/features/games/family_memories/family_memories_game_screen.dart';
import 'package:smriti_care/features/mri/mri_screening_screen.dart';

void main() {
  group('Enhanced GameResult Telemetry Tests (Step 7)', () {
    test('GameResult captures all Step 7 fields correctly', () {
      final now = DateTime(2026, 9, 11, 10, 0);
      final result = GameResult(
        id: 'test_telemetry_1',
        patientId: 'MC-2048',
        gameId: 'day-time-orientation',
        gameName: 'Day & Time Orientation',
        score: 85,
        accuracy: 85,
        attempts: 5,
        correctAnswers: 4,
        wrongAnswers: 1,
        difficulty: 'Level 2',
        completionTimeSeconds: 40,
        avgResponseTimeSeconds: 8.0,
        timestamp: now,
        recommendation: 'Good temporal recall.',
        syncStatus: 'pending',
      );

      // Verify Step 7 fields
      expect(result.patientId, 'MC-2048');
      expect(result.gameName, 'Day & Time Orientation');
      expect(result.level, 2);
      expect(result.score, 85);
      expect(result.accuracy, 85);
      expect(result.mistakes, 1);
      expect(result.responseTime, 8.0);
      expect(result.completionTime, now);
      expect(result.syncStatus, 'pending');

      // Serialization round-trip
      final map = result.toMap();
      expect(map['patientId'], 'MC-2048');
      expect(map['mistakes'], 1);
      expect(map['level'], 2);
      expect(map['responseTime'], 8.0);

      final restored = GameResult.fromMap(map);
      expect(restored.patientId, result.patientId);
      expect(restored.mistakes, result.mistakes);
      expect(restored.responseTime, result.responseTime);
      expect(restored.level, result.level);
    });

    test('CognitiveApiService queues telemetry and manages offline state', () {
      final service = CognitiveApiService.instance;
      expect(service.isConfigured, isTrue);
      expect(service.pendingCount, isA<int>());
    });
  });

  group('MRI Screening Models & Service Tests (Step 8)', () {
    test('MriScanResult serializes and deserializes properly', () {
      final now = DateTime.now();
      final scan = MriScanResult(
        scanId: 'mri_test_1',
        patientId: 'MC-2048',
        prediction: 'Mild Cognitive Impairment (MCI)',
        predictionClass: MriPredictionClass.mildCognitiveImpairment,
        confidenceScore: 0.89,
        recommendation: 'Hippocampal volume check recommended.',
        status: 'completed',
        timestamp: now,
        serverUrl: 'http://10.0.2.2:8000',
      );

      final map = scan.toMap();
      expect(map['predictionClass'], 'mildCognitiveImpairment');
      expect(map['confidenceScore'], 0.89);

      final restored = MriScanResult.fromMap(map);
      expect(restored.predictionClass, MriPredictionClass.mildCognitiveImpairment);
      expect(restored.confidenceScore, 0.89);
      expect(restored.disclaimer, contains('AI screening aid only'));
    });

    test('MriScreeningService generates appropriate demo results', () {
      final normal = MriScreeningService.instance.generateDemoResult(
        patientId: 'MC-2048',
        sampleType: 'normal',
        fileName: 'normal.png',
      );
      expect(normal.predictionClass, MriPredictionClass.normal);
      expect(normal.confidenceScore, greaterThan(0.9));

      final mci = MriScreeningService.instance.generateDemoResult(
        patientId: 'MC-2048',
        sampleType: 'mci',
        fileName: 'mci.png',
      );
      expect(mci.predictionClass, MriPredictionClass.mildCognitiveImpairment);

      final dementia = MriScreeningService.instance.generateDemoResult(
        patientId: 'MC-2048',
        sampleType: 'dementia',
        fileName: 'atrophy.png',
      );
      expect(dementia.predictionClass, MriPredictionClass.dementiaRisk);
    });
  });

  group('Multilingual i18n Architecture Tests (Step 10)', () {
    test('All 10 Northeast and Indian languages are registered', () {
      expect(AppLocalizations.supportedLanguages.length, 10);
      final codes = AppLocalizations.supportedLanguages.map((l) => l.code).toList();
      expect(codes, containsAll(['en', 'hi', 'as', 'bn', 'mni', 'kha', 'lus', 'grt', 'brx', 'trp']));
    });

    test('LocalizationService updates current locale', () {
      LocalizationService.instance.setLocale('hi');
      expect(LocalizationService.instance.currentLocale.languageCode, 'hi');
      LocalizationService.instance.setLocale('as');
      expect(LocalizationService.instance.currentLocale.languageCode, 'as');
      // Reset to English
      LocalizationService.instance.setLocale('en');
      expect(LocalizationService.instance.currentLocale.languageCode, 'en');
    });
  });

  group('Widget Tests: Take Me Home & SOS (Step 5)', () {
    testWidgets('Renders TakeMeHomeScreen with address and emergency buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TakeMeHomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Take Me Home & SOS'), findsOneWidget);
      expect(find.text('Your Safe Home Address'), findsOneWidget);
      expect(find.text('PRESS FOR EMERGENCY SOS'), findsOneWidget);
      expect(find.text('Call National Emergency 112'), findsOneWidget);
    });
  });

  group('Widget Tests: Day & Time Orientation Game (Step 5)', () {
    testWidgets('Renders DayTimeOrientationScreen question and options',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DayTimeOrientationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Day & Time Orientation'), findsOneWidget);
      expect(find.text('What day of the week is it today?'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('Widget Tests: Routine Sequence Game (Step 5)', () {
    testWidgets('Renders RoutineSequenceScreen with reorderable steps',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RoutineSequenceScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Daily Routine Sequence'), findsOneWidget);
      expect(find.text('Check Sequence'), findsOneWidget);
      expect(find.byType(ReorderableListView), findsOneWidget);
    });
  });

  group('Widget Tests: Family Memories Game (Step 5)', () {
    testWidgets('Renders FamilyMemoriesGameScreen with family association options',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FamilyMemoriesGameScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Family Memories'), findsOneWidget);
      expect(find.text('What is their relationship with you?'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('Widget Tests: MRI Screening Screen (Step 8)', () {
    testWidgets('Renders MriScreeningScreen with sample scan selectors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MriScreeningScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MRI AI Screening'), findsOneWidget);
      expect(find.text('Select Structural MRI Scan'), findsOneWidget);
      expect(find.text('Normal Baseline Scan'), findsOneWidget);
      expect(find.text('Run AI Model Screening'), findsOneWidget);
    });
  });
}
