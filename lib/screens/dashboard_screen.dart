// lib/screens/dashboard_screen.dart
//
// SmritiCare Mobile Dashboard / Home Screen
// Designed specifically for Android phones and elderly users.
// Features:
// - Header with brand badge, time-based greeting, date, and patient profile pill
// - Next Reminder high-priority card (Medicine at 10:00 AM)
// - Today's Activity metrics (Games: 0, Streak: 0 days, Score: 0)
// - Quick Actions 6-card grid (Games, Reminders, SOS, Location, Progress, Caregiver)
// - Your Progress indicators (Memory: 75%, Attention: 60%, Pattern: 80%)
// - Mobile-first layout with SafeArea and SingleChildScrollView

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../core/services/game_storage_service.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/today_activity_section.dart';
import '../widgets/next_reminder_card.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/progress_summary_card.dart';
import '../widgets/sos_button.dart';
// FIX: Import offline-first step counter service and daily steps widget
import '../core/services/step_counter_service.dart';
import '../features/patient/widgets/daily_steps_card.dart';
import '../core/services/caregiver_service.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(String moduleId)? onNavigateModule;

  const DashboardScreen({super.key, this.onNavigateModule});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // FIX: Initialize offline step tracking on the main patient home screen
    StepCounterService.instance.init();
  }

  void _handleNavigate(BuildContext context, String moduleId) {
    if (widget.onNavigateModule != null) {
      widget.onNavigateModule!(moduleId);
    } else if (moduleId.toLowerCase() == 'games') {
      context.push('/games');
    } else if (moduleId.toLowerCase() == 'caregiver') {
      context.push('/caregiver-dashboard');
    } else if (moduleId.toLowerCase() == 'emergency' ||
        moduleId.toLowerCase() == 'sos') {
      context.push('/take-me-home');
    } else {
      context.push('/placeholder/$moduleId');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header (Greeting, Date, Patient Pill) ───────────────
              DashboardHeader(
                onProfileTap: () => _handleNavigate(context, 'profile'),
              ),

              const SizedBox(height: 18),

              // ── Main Content Body ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // FIX: Sync caregiver reminder changes to linked patient - Next Reminder Card
                    ValueListenableBuilder<int>(
                      valueListenable:
                          CaregiverService.instance.remindersNotifier,
                      builder: (context, _, __) {
                        final reminders =
                            CaregiverService.instance.getReminders();
                        final upcoming = reminders
                            .where((r) => r.isEnabled && !r.isCompleted)
                            .toList();
                        final next =
                            upcoming.isNotEmpty ? upcoming.first : null;
                        return NextReminderCard(
                          title: next?.title,
                          time: next?.time ?? 'No upcoming',
                          note: next?.description.isNotEmpty == true
                              ? next!.description
                              : (next != null
                                  ? 'Caregiver scheduled reminder'
                                  : 'All reminders completed for today'),
                          onTap: () => _handleNavigate(context, 'reminders'),
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    // FIX: Real Daily Step Counter (Target: 10,000 steps/day)
                    const DailyStepsCard(),

                    const SizedBox(height: 18),

                    // ── Prominent Emergency SOS Button for elderly patients ──
                    const SosButton(),

                    const SizedBox(height: 22),

                    // Today's Activity Metrics (live from offline game storage)
                    TodayActivitySection(
                      gamesCompleted:
                          GameStorageService.instance.getTotalGamesCompleted(),
                      streakDays:
                          GameStorageService.instance.getCurrentStreakDays(),
                      todayScore: GameStorageService.instance.getTodayScore(),
                    ),

                    const SizedBox(height: 24),

                    // Quick Actions (6 large touch-target cards)
                    QuickActionsGrid(
                      onActionTap: (moduleId) =>
                          _handleNavigate(context, moduleId),
                    ),

                    const SizedBox(height: 24),

                    // Your Progress (Cognitive indicators)
                    ProgressSummaryCard(
                      memoryScore: 75,
                      attentionScore: 60,
                      patternScore: 80,
                      onTap: () => _handleNavigate(context, 'progress'),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
