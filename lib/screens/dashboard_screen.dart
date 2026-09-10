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

class DashboardScreen extends StatelessWidget {
  final void Function(String moduleId)? onNavigateModule;

  const DashboardScreen({super.key, this.onNavigateModule});

  void _handleNavigate(BuildContext context, String moduleId) {
    if (onNavigateModule != null) {
      onNavigateModule!(moduleId);
    } else if (moduleId.toLowerCase() == 'games') {
      context.push('/games');
    } else if (moduleId.toLowerCase() == 'caregiver') {
      context.push('/caregiver-dashboard');
    } else if (moduleId.toLowerCase() == 'emergency' || moduleId.toLowerCase() == 'sos') {
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
                    // Next Reminder (High Priority for elderly patients)
                    NextReminderCard(
                      time: '10:00 AM',
                      onTap: () => _handleNavigate(context, 'reminders'),
                    ),

                    const SizedBox(height: 18),

                    // ── Prominent Emergency SOS Button for elderly patients ──
                    const SosButton(),

                    const SizedBox(height: 22),

                    // Today's Activity Metrics (live from offline game storage)
                    TodayActivitySection(
                      gamesCompleted: GameStorageService.instance.getTotalGamesCompleted(),
                      streakDays: GameStorageService.instance.getCurrentStreakDays(),
                      todayScore: GameStorageService.instance.getTodayScore(),
                    ),

                    const SizedBox(height: 24),

                    // Quick Actions (6 large touch-target cards)
                    QuickActionsGrid(
                      onActionTap: (moduleId) => _handleNavigate(context, moduleId),
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
