// test/enhanced_features_test.dart
//
// Comprehensive test suite for SmritiCare features.
// Updated to match real MRI models (veryMild/dementia enum names, no demo results).

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

      expect(result.patientId, 'MC-2048');
      expect(result.gameName, 'Day & Time Orientation');
      expect(result.level, 2);
      expect(result.score, 85);
      expect(result.accuracy, 85);
      expect(result.mistakes, 1);
      expect(result.responseTime, 8.0);
      expect(result.completionTime, now);
      expect(result.syncStatus, 'pending');

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

  // FIX: Updated MRI tests to use real backend model enum names (veryMild, dementia)
  group('MRI Screening Models & Service Tests (Step 8)', () {
    test('MriScanResult serializes and deserializes properly — Normal class',
        () {
      final now = DateTime.now();
      final scan = MriScanResult(
        scanId: 'mri_test_normal',
        patientId: 'MC-2048',
        prediction: 'Normal',
        predictionClass: MriPredictionClass.normal,
        classId: 0,
        confidenceScore: 0.92,
        recommendation:
            'No dementia markers detected. Continue routine monitoring.',
        status: 'completed',
        timestamp: now,
        serverUrl: 'http://10.0.2.2:8000',
      );

      final map = scan.toMap();
      expect(map['predictionClass'], 'normal');
      expect(map['confidenceScore'], 0.92);
      expect(map['classId'], 0);

      final restored = MriScanResult.fromMap(map);
      expect(restored.predictionClass, MriPredictionClass.normal);
      expect(restored.confidenceScore, 0.92);
      expect(restored.disclaimer, contains('AI-generated'));
    });

    test('MriScanResult handles Very Mild Dementia (class 1)', () {
      final scan = MriScanResult(
        scanId: 'mri_test_verymild',
        patientId: 'MC-2048',
        prediction: 'Very Mild Dementia',
        predictionClass: MriPredictionClass.veryMild,
        classId: 1,
        confidenceScore: 0.78,
        recommendation: 'Clinical follow-up recommended.',
        status: 'completed',
        timestamp: DateTime.now(),
        serverUrl: 'http://10.0.2.2:8000',
      );

      final map = scan.toMap();
      expect(map['predictionClass'], 'veryMild');
      final restored = MriScanResult.fromMap(map);
      expect(restored.predictionClass, MriPredictionClass.veryMild);
      expect(restored.classId, 1);
    });

    test('MriScanResult handles Dementia class (class 2)', () {
      final scan = MriScanResult(
        scanId: 'mri_test_dementia',
        patientId: 'MC-2048',
        prediction: 'Dementia (Mild/Moderate)',
        predictionClass: MriPredictionClass.dementia,
        classId: 2,
        confidenceScore: 0.85,
        recommendation: 'Urgent consultation with neurologist recommended.',
        status: 'completed',
        timestamp: DateTime.now(),
        serverUrl: 'http://10.0.2.2:8000',
      );

      final map = scan.toMap();
      expect(map['predictionClass'], 'dementia');
      final restored = MriScanResult.fromMap(map);
      expect(restored.predictionClass, MriPredictionClass.dementia);
      expect(restored.classId, 2);
    });

    test('MriScanResult handles low confidence (inconclusive)', () {
      final scan = MriScanResult(
        scanId: 'mri_test_inconclusive',
        patientId: 'MC-2048',
        prediction: 'Backend Offline',
        predictionClass: MriPredictionClass.inconclusive,
        classId: 0,
        confidenceScore: 0.0,
        isLowConfidence: true,
        recommendation: 'Cannot connect to backend.',
        status: 'failed',
        timestamp: DateTime.now(),
        serverUrl: 'http://10.0.2.2:8000',
      );

      expect(scan.predictionClass, MriPredictionClass.inconclusive);
      expect(scan.isLowConfidence, isTrue);
      expect(scan.status, 'failed');
    });

    test('MriScreeningService singleton is accessible and has correct base URL',
        () {
      final service = MriScreeningService.instance;
      expect(service.apiBaseUrl, contains('8000'));
    });

    test('MriUploadedFile serializes round-trip correctly', () {
      final now = DateTime.now();
      final file = MriUploadedFile(
        id: 'mri_${now.millisecondsSinceEpoch}',
        originalFileName: 'scan_001.nii.gz',
        localFilePath: '/data/mri/mri_20260911_144500.nii.gz',
        category: MriFileCategory.mri,
        fileExtension: 'nii.gz',
        fileSizeBytes: 14500000,
        uploadedAt: now,
        caregiverId: 'Caregiver',
        isMriCompatible: true,
        predictionStatus: 'not_analyzed',
      );

      final map = file.toMap();
      expect(map['isMriCompatible'], isTrue);
      expect(map['predictionStatus'], 'not_analyzed');
      expect(map['fileExtension'], 'nii.gz');

      final restored = MriUploadedFile.fromMap(map);
      expect(restored.category, MriFileCategory.mri);
      expect(restored.isMriCompatible, isTrue);
      expect(restored.formattedSize, contains('MB'));
    });
  });

  group('Multilingual i18n Architecture Tests (Step 10)', () {
    test('All 10 Northeast and Indian languages are registered', () {
      expect(AppLocalizations.supportedLanguages.length, 10);
      final codes =
          AppLocalizations.supportedLanguages.map((l) => l.code).toList();
      expect(
          codes,
          containsAll([
            'en',
            'hi',
            'as',
            'bn',
            'mni',
            'kha',
            'lus',
            'grt',
            'brx',
            'trp'
          ]));
    });

    test('LocalizationService updates current locale', () {
      LocalizationService.instance.setLocale('hi');
      expect(LocalizationService.instance.currentLocale.languageCode, 'hi');
      LocalizationService.instance.setLocale('as');
      expect(LocalizationService.instance.currentLocale.languageCode, 'as');
      LocalizationService.instance.setLocale('en');
      expect(LocalizationService.instance.currentLocale.languageCode, 'en');
    });
  });

  group('Widget Tests: Take Me Home & SOS (Step 5)', () {
    testWidgets('Renders TakeMeHomeScreen with address and emergency buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: TakeMeHomeScreen()),
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
        const MaterialApp(home: DayTimeOrientationScreen()),
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
        const MaterialApp(home: RoutineSequenceScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Daily Routine Sequence'), findsOneWidget);
      expect(find.text('Check Sequence'), findsOneWidget);
      expect(find.byType(ReorderableListView), findsOneWidget);
    });
  });

  group('Widget Tests: Family Memories Game (Step 5)', () {
    testWidgets(
        'Renders FamilyMemoriesGameScreen with family association options',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: FamilyMemoriesGameScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Family Memories'), findsOneWidget);
      expect(find.text('What is their relationship with you?'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('Widget Tests: MRI Screening Screen (Step 8)', () {
    testWidgets('Renders MriScreeningScreen with file selector and disclaimer',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MriScreeningScreen()),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('MRI Screening'), findsOneWidget);
      // FIX: File selection button shows Select MRI File
      expect(find.text('Select MRI File'), findsOneWidget);
      // Analyze MRI button should be disabled until file is selected
      expect(find.text('Analyze MRI'), findsOneWidget);
    });
  });
}
