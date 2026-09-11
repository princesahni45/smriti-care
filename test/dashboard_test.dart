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
// FIX: Verify DailyStepsCard is visible on dashboard
import 'package:smriti_care/features/patient/widgets/daily_steps_card.dart';

void main() {
  testWidgets('SmritiCare Mobile Dashboard smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SmritiCareApp());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Verify MainShellScreen and DashboardScreen render
    expect(find.byType(MainShellScreen), findsOneWidget);
    expect(find.byType(DashboardScreen), findsOneWidget);

    // Verify brand header & patient name
    expect(find.text('SmritiCare'), findsOneWidget);
    expect(find.text('Mr. Ramesh Das'), findsOneWidget);

    // Verify core sections
    expect(find.byType(NextReminderCard), findsOneWidget);
    // FIX: Daily step counter card is rendered and visible on dashboard
    expect(find.byType(DailyStepsCard), findsOneWidget);
    expect(find.byType(TodayActivitySection), findsOneWidget);
    expect(find.byType(QuickActionsGrid), findsOneWidget);
    expect(find.byType(ProgressSummaryCard), findsOneWidget);

    // Verify bottom navigation bar destinations
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('Home')), findsOneWidget);
    expect(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('Games')), findsOneWidget);
    expect(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('Reminders')), findsOneWidget);
    expect(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('Progress')), findsOneWidget);
    expect(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('Profile')), findsOneWidget);
  });

  testWidgets('Dashboard navigation to games and placeholders', (WidgetTester tester) async {
    await tester.pumpWidget(const SmritiCareApp());
    await tester.pump(const Duration(milliseconds: 100));
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
    await tester.tap(find.text('Reminders').last);
    await tester.pumpAndSettle();

    // Should display the real Daily Schedule & Reminders screen
    expect(find.text('Daily Schedule & Reminders'), findsOneWidget);

    // Tap back button
    await tester.tap(find.byTooltip('Back to Home'));
    await tester.pumpAndSettle();

    // Should be back on the dashboard
    expect(find.text('SmritiCare'), findsOneWidget);
  });
}
