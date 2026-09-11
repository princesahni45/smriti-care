// test/step_tracking_test.dart
//
// Unit tests for DailyStepRecord and StepStorageService logic.

import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_care/core/models/daily_step_record.dart';
import 'package:smriti_care/core/services/step_storage_service.dart';

void main() {
  group('DailyStepRecord Model Tests', () {
    test(
        'Calculates progress percentage, remaining steps, and goal completion correctly',
        () {
      final record = DailyStepRecord(
        patientId: 'MC-2048',
        date: '2026-09-11',
        steps: 6420,
        goal: 10000,
        baselineSensorValue: 1000,
        lastSensorValue: 7420,
        updatedAt: DateTime.now(),
      );

      expect(record.progressPercentage, closeTo(0.642, 0.001));
      expect(record.remainingSteps, equals(3580));
      expect(record.isGoalCompleted, isFalse);
    });

    test('Caps progress percentage at 1.0 when steps exceed goal of 10,000',
        () {
      final completedRecord = DailyStepRecord(
        patientId: 'MC-2048',
        date: '2026-09-11',
        steps: 12450,
        goal: 10000,
        baselineSensorValue: 1000,
        lastSensorValue: 13450,
        updatedAt: DateTime.now(),
      );

      expect(completedRecord.progressPercentage, equals(1.0));
      expect(completedRecord.remainingSteps, equals(0));
      expect(completedRecord.isGoalCompleted, isTrue);
    });

    test('Serializes to and from Map accurately', () {
      final record = DailyStepRecord(
        patientId: 'MC-2048',
        date: '2026-09-11',
        steps: 5000,
        goal: 10000,
        baselineSensorValue: 200,
        lastSensorValue: 5200,
        updatedAt: DateTime(2026, 9, 11, 14, 0),
        syncStatus: 'pending',
      );

      final map = record.toMap();
      final recreated = DailyStepRecord.fromMap(map);

      expect(recreated.patientId, equals(record.patientId));
      expect(recreated.date, equals(record.date));
      expect(recreated.steps, equals(record.steps));
      expect(recreated.goal, equals(record.goal));
      expect(recreated.baselineSensorValue, equals(record.baselineSensorValue));
      expect(recreated.lastSensorValue, equals(record.lastSensorValue));
      expect(recreated.syncStatus, equals(record.syncStatus));
    });
  });

  group('StepStorageService Logic Tests', () {
    test('Calculates today steps monotonically and rebases on sensor reboot',
        () async {
      StepStorageService.instance.clearForTesting();

      // Step count starts with sensor reading 5000
      final rec1 = await StepStorageService.instance.updateSteps(
        patientId: 'MC-2048',
        sensorValue: 5000,
      );
      expect(rec1.steps, greaterThanOrEqualTo(0));

      // Sensor advances by 120 steps
      final rec2 = await StepStorageService.instance.updateSteps(
        patientId: 'MC-2048',
        sensorValue: 5120,
      );
      expect(rec2.steps, equals(120));

      // Phone reboots: sensor resets to 50
      final rec3 = await StepStorageService.instance.updateSteps(
        patientId: 'MC-2048',
        sensorValue: 50,
      );
      // Accumulated steps must NOT be lost
      expect(rec3.steps, greaterThanOrEqualTo(120));
    });
  });
}
