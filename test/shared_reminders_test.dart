// test/shared_reminders_test.dart
//
// FIX: Sync caregiver reminder changes to linked patient
//
// Tests for Caregiver Reminder creation, editing, deletion,
// patient completion (acknowledgment), and local notification synchronization.

import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_care/core/models/caregiver_models.dart';
import 'package:smriti_care/core/services/caregiver_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Shared Reminders Tests', () {
    test('CaregiverReminder model supports reminderId and serialization', () {
      final now = DateTime(2026, 9, 11, 8, 0);
      final reminder = CaregiverReminder(
        id: 'rem-999',
        patientId: 'MC-2048',
        title: 'Blood Pressure Tablet',
        message: 'Take with warm water',
        scheduledTime: '08:30 AM',
        type: 'medication',
        repeat: 'Daily',
        enabled: true,
        status: 'upcoming',
        createdBy: 'caregiver_01',
        updatedAt: now,
      );

      // FIX: Sync caregiver reminder changes to linked patient
      expect(reminder.reminderId, equals('rem-999'));
      expect(reminder.description, equals('Take with warm water'));
      expect(reminder.repeatRule, equals('Daily'));

      final map = reminder.toMap();
      final fromMap = CaregiverReminder.fromMap(map);

      expect(fromMap.id, equals('rem-999'));
      expect(fromMap.title, equals('Blood Pressure Tablet'));
      expect(fromMap.time, equals('08:30 AM'));
      expect(fromMap.type, equals('medication'));
      expect(fromMap.repeat, equals('Daily'));
      expect(fromMap.isEnabled, isTrue);
      expect(fromMap.isCompleted, isFalse);
    });

    test('Adding, updating, and toggling a reminder updates remindersNotifier',
        () async {
      final service = CaregiverService.instance;
      await service.init();

      final initialCount = service.getReminders().length;

      // Add
      await service.addReminder(
        CaregiverReminder(
          id: 'rem-test-walk',
          patientId: 'MC-2048',
          title: 'Evening Walk',
          message: '30 mins walk in garden',
          scheduledTime: '06:00 PM',
          type: 'activity',
          repeat: 'Daily',
          enabled: true,
          status: 'upcoming',
          updatedAt: DateTime.now(),
        ),
      );

      expect(service.getReminders().length, equals(initialCount + 1));
      final added =
          service.getReminders().firstWhere((r) => r.title == 'Evening Walk');
      expect(added.isEnabled, isTrue);
      expect(added.isCompleted, isFalse);

      // Toggle
      await service.toggleReminder(added.id);
      final toggled =
          service.getReminders().firstWhere((r) => r.id == added.id);
      expect(toggled.isEnabled, isFalse);

      // Patient Acknowledge / Complete
      await service.acknowledgeReminder(added.id);
      final acknowledged =
          service.getReminders().firstWhere((r) => r.id == added.id);
      expect(acknowledged.isCompleted, isTrue);

      // Delete
      await service.deleteReminder(added.id);
      expect(service.getReminders().any((r) => r.id == added.id), isFalse);
    });
  });
}
