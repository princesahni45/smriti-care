// test/dashboard_test.dart
//
// Widget test verifying the SmritiCare Mobile Dashboard UI and navigation.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_care/app.dart';
import 'package:smriti_care/screens/main_shell_screen.dart';
import 'package:smriti_care/screens/dashboard_screen.dart';
import 'package:smriti_care/widgets/next_reminder_card.dart';
import 'package:smriti_care/widgets/today_activity_section.dart';
import 'package:smriti_care/widgets/progress_summary_card.dart';
import 'package:smriti_care/widgets/quick_action_card.dart';

void main() {
  testWidgets('SmritiCare Mobile Dashboard smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SmritiCareApp());
    await tester.pumpAndSettle();

    // Verify MainShellScreen and DashboardScreen render
    expect(find.byType(MainShellScreen), findsOneWidget);
    expect(find.byType(DashboardScreen), findsOneWidget);

    // Verify brand header & patient name
    expect(find.text('SmritiCare'), findsOneWidget);
    expect(find.text('Mr. Ramesh Das'), findsOneWidget);

    // Verify core sections
    expect(find.byType(NextReminderCard), findsOneWidget);
    expect(find.byType(TodayActivitySection), findsOneWidget);
    expect(find.byType(QuickActionsGrid), findsOneWidget);
    expect(find.byType(ProgressSummaryCard), findsOneWidget);

    // Verify bottom navigation bar destinations
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Games'), findsOneWidget);
    expect(find.text('Reminders'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('Dashboard navigation to games and placeholders', (WidgetTester tester) async {
    await tester.pumpWidget(const SmritiCareApp());
    await tester.pumpAndSettle();

    // Tap on Cognitive Games tab in bottom navigation
    await tester.tap(find.text('Games'));
    await tester.pumpAndSettle();

    // Should display the Cognitive Activities games hub
    expect(find.text('Cognitive Activities'), findsOneWidget);
    expect(find.text('Memory Match'), findsOneWidget);
    expect(find.text('Word Recall & Delayed Memory'), findsOneWidget);
    expect(find.text('Find the Different Object'), findsOneWidget);

    // Tap on Reminders tab in bottom navigation
    await tester.tap(find.text('Reminders'));
    await tester.pumpAndSettle();

    // Should display the Coming Soon placeholder for Reminders
    expect(find.text('COMING SOON'), findsOneWidget);
    expect(find.text('Smart Reminders'), findsOneWidget);
    expect(find.text('Back to Dashboard'), findsOneWidget);

    // Tap back button
    await tester.tap(find.text('Back to Dashboard'));
    await tester.pumpAndSettle();

    // Should be back on the dashboard
    expect(find.text('SmritiCare'), findsOneWidget);
  });
}
