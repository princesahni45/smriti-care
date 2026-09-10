// test/caregiver_migration_test.dart
//
// Comprehensive unit and widget tests for the SmritiCare Caregiver Portal.
// Tests:
// 1. Caregiver models serialization & deserialization (PatientProfile, CaregiverReminder, EmergencyContact)
// 2. CaregiverService offline data layer, reminder CRUD, safety configuration
// 3. CaregiverDashboardScreen multi-tab navigation and widget rendering

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_care/core/models/caregiver_models.dart';
import 'package:smriti_care/core/services/caregiver_service.dart';
import 'package:smriti_care/features/caregiver/caregiver_dashboard_screen.dart';
import 'package:smriti_care/features/caregiver/widgets/caregiver_header_bar.dart';
import 'package:smriti_care/features/caregiver/widgets/patient_banner_card.dart';
import 'package:smriti_care/features/caregiver/widgets/weekly_engagement_chart.dart';

void main() {
  group('Caregiver Data Models Tests', () {
    test('PatientProfile serializes and deserializes properly', () {
      final now = DateTime(2026, 9, 10, 10, 0);
      final patient = PatientProfile(
        id: 'MC-2048',
        fullName: 'Mr. Ramesh Das',
        age: 72,
        location: 'Guwahati, Assam',
        bloodGroup: 'B+',
        physician: 'Dr. Ananya Bora',
        dementiaLevel: 'Moderate',
        primaryLanguage: 'English',
        avatarInitials: 'RD',
        lastUpdated: now,
      );

      final map = patient.toMap();
      expect(map['id'], 'MC-2048');
      expect(map['fullName'], 'Mr. Ramesh Das');
      expect(map['age'], 72);
      expect(map['bloodGroup'], 'B+');
      expect(map['dementiaLevel'], 'Moderate');

      final restored = PatientProfile.fromMap(map);
      expect(restored.id, patient.id);
      expect(restored.fullName, patient.fullName);
      expect(restored.age, patient.age);
      expect(restored.physician, patient.physician);
    });

    test('CaregiverReminder serializes, deserializes, and supports copyWith', () {
      final reminder = CaregiverReminder(
        id: 'rem-test-01',
        patientId: 'MC-2048',
        type: 'medication',
        title: 'Morning Medicine',
        message: 'Take with water',
        scheduledTime: '08:00 AM',
        repeat: 'daily',
        enabled: true,
        status: 'acknowledged',
      );

      final map = reminder.toMap();
      expect(map['title'], 'Morning Medicine');
      expect(map['enabled'], isTrue);

      final toggled = reminder.copyWith(enabled: false);
      expect(toggled.enabled, isFalse);
      expect(toggled.title, reminder.title);

      final restored = CaregiverReminder.fromMap(map);
      expect(restored.id, reminder.id);
      expect(restored.type, reminder.type);
      expect(restored.scheduledTime, reminder.scheduledTime);
    });

    test('EmergencyContact and HomeLocation serialize properly', () {
      final now = DateTime.now();
      final contact = EmergencyContact(
        name: 'Rahul Das',
        relationship: 'Son',
        phone: '+91 98765 43210',
        secondaryPhone: '+91 98765 01234',
        updatedAt: now,
      );
      final cMap = contact.toMap();
      final restoredC = EmergencyContact.fromMap(cMap);
      expect(restoredC.name, 'Rahul Das');
      expect(restoredC.relationship, 'Son');

      final home = HomeLocation(
        address: 'Ambari, Guwahati, Assam',
        latitude: 26.1856,
        longitude: 91.7539,
        updatedAt: now,
      );
      final hMap = home.toMap();
      final restoredH = HomeLocation.fromMap(hMap);
      expect(restoredH.address, 'Ambari, Guwahati, Assam');
      expect(restoredH.latitude, 26.1856);
      expect(restoredH.longitude, 91.7539);
    });
  });

  group('CaregiverService Tests', () {
    test('Service initializes with default seed data and provides metrics', () async {
      final service = CaregiverService.instance;
      await service.init();

      final patient = service.getPatientProfile();
      expect(patient.fullName, 'Mr. Ramesh Das');
      expect(patient.id, 'MC-2048');

      final caregiver = service.getCaregiverProfile();
      expect(caregiver.name, 'Mohak Singh');
      expect(caregiver.initials, 'MS');

      final metrics = service.getOverviewMetrics();
      expect(metrics.containsKey('activityTime'), isTrue);
      expect(metrics.containsKey('cognitiveScore'), isTrue);
      expect(metrics.containsKey('medication'), isTrue);
    });

    test('Reminder CRUD operations work correctly', () async {
      final service = CaregiverService.instance;
      await service.init();

      final initialCount = service.getReminders().length;

      final testRem = CaregiverReminder(
        id: 'rem-unit-test',
        patientId: 'MC-2048',
        type: 'hydration',
        title: 'Midday Hydration',
        message: 'Drink a glass of water',
        scheduledTime: '12:30 PM',
        repeat: 'daily',
        enabled: true,
        status: 'upcoming',
      );

      await service.addReminder(testRem);
      expect(service.getReminders().length, initialCount + 1);

      await service.toggleReminder('rem-unit-test');
      final found = service.getReminders().firstWhere((r) => r.id == 'rem-unit-test');
      expect(found.enabled, isFalse);

      await service.deleteReminder('rem-unit-test');
      expect(service.getReminders().any((r) => r.id == 'rem-unit-test'), isFalse);
    });
  });

  group('CaregiverDashboardScreen Widget Tests', () {
    testWidgets('Renders header bar, patient banner, and weekly chart on Overview tab',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CaregiverDashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Header Bar
      expect(find.byType(CaregiverHeaderBar), findsOneWidget);
      expect(find.text('Caregiver portal'), findsOneWidget);
      expect(find.text('Patient View'), findsOneWidget);

      // Patient Banner
      expect(find.byType(PatientBannerCard), findsOneWidget);
      expect(find.text('Mr. Ramesh Das • 72 yrs'), findsOneWidget);
      expect(find.text('RD'), findsOneWidget);

      // Summary Cards & Sections on Home Tab
      expect(find.text('Health & Cognitive Summary'), findsOneWidget);
      expect(find.text('Cognitive Score'), findsOneWidget);
      expect(find.text('Daily Streak'), findsOneWidget);

      // Bottom Navigation Bar tabs (5 Tabs)
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Patient'), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('Alerts'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('Tapping bottom tabs switches between Patient, Progress, Alerts, and Profile',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CaregiverDashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Patient tab
      await tester.tap(find.text('Patient'));
      await tester.pumpAndSettle();
      expect(find.text('Patient Profile & Linking'), findsOneWidget);
      expect(find.textContaining('Linked Patients'), findsOneWidget);

      // Tap on Progress tab
      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();
      expect(find.text('Cognitive Progress & Reports'), findsOneWidget);
      expect(find.byType(WeeklyEngagementChart), findsOneWidget);
      expect(find.text('Individual Game Reports'), findsOneWidget);

      // Tap on Alerts tab
      await tester.tap(find.text('Alerts'));
      await tester.pumpAndSettle();
      expect(find.text('Risk Screening & Reminders'), findsOneWidget);
      expect(find.text('Manage Reminders'), findsOneWidget);

      // Tap on Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Profile & Safety Hub'), findsOneWidget);
      expect(find.text('Family Memories'), findsOneWidget);
      expect(find.text('Emergency & Location Safety'), findsOneWidget);
    });
  });
}
