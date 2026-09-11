// lib/features/caregiver/tabs/caregiver_home_tab.dart
//
// Caregiver Overview / Home Tab:
// - Time-based greeting: Good Morning / Afternoon / Evening, Caregiver
// - Currently selected patient banner with switch option
// - 6 Summary Cards:
//   1. Today\'s Cognitive Score
//   2. Games Completed Today
//   3. Daily Streak
//   4. Cognitive Risk Level (Low/Moderate/High)
//   5. Last Assessment Date & Time
//   6. Recent Patient Activity Status
// - Quick Shortcuts & Recent Activity Timeline

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/caregiver_models.dart';
import '../../../core/services/caregiver_service.dart';
import '../../../core/services/step_storage_service.dart';
import '../widgets/patient_banner_card.dart';
import '../widgets/activity_timeline_section.dart';

class CaregiverHomeTab extends StatelessWidget {
  final VoidCallback onSwitchPatientTap;
  final void Function(int targetTab) onNavigateTab;

  const CaregiverHomeTab({
    super.key,
    required this.onSwitchPatientTap,
    required this.onNavigateTab,
  });

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  @override
  Widget build(BuildContext context) {
    final patient = CaregiverService.instance.getPatientProfile();
    final caregiver = CaregiverService.instance.getCaregiverProfile();
    final metrics = CaregiverService.instance.getOverviewMetrics();
    final risk = CaregiverService.instance.getRiskAssessment();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting & Welcome Bar
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_greeting, ${caregiver.name.split(" ").first}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Monitoring care & cognitive progress',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onSwitchPatientTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.tealPale,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.teal.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horiz_rounded,
                          size: 16, color: AppColors.tealDark),
                      SizedBox(width: 4),
                      Text(
                        'Switch',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.tealDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Active Patient Card
          PatientBannerCard(
            patient: patient,
            onViewProfile: () => onNavigateTab(1), // Navigates to Patient Tab
          ),

          const SizedBox(height: 20),

          // Section Title: Quick Health & Cognitive Overview
          const Text(
            'Health & Cognitive Summary',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),

          // 6 Summary Cards in 2x3 Grid
          _buildSummaryCardsGrid(context, metrics, risk),

          const SizedBox(height: 22),

          // FIX: Added MRI Screening to Caregiver Dashboard
          // MRI Screening Featured Card
          _buildMriScreeningCard(context),

          const SizedBox(height: 22),

          // FIX: Added authorized caregiver/doctor activity access
          // Patient Physical Activity & Step Tracking Section
          _buildPatientActivitySection(context, patient),

          const SizedBox(height: 22),

          // Quick Action Shortcuts
          const Text(
            'Quick Care Actions',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          _buildQuickActionCards(context),

          const SizedBox(height: 22),

          // Recent Activity Timeline
          const ActivityTimelineSection(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSummaryCardsGrid(
    BuildContext context,
    Map<String, String> metrics,
    RiskAssessment risk,
  ) {
    Color riskColor;
    Color riskBg;
    switch (risk.level) {
      case RiskLevel.low:
        riskColor = AppColors.tealDark;
        riskBg = AppColors.tealPale;
        break;
      case RiskLevel.moderate:
        riskColor = AppColors.amberDeep;
        riskBg = AppColors.amberPale;
        break;
      case RiskLevel.high:
        riskColor = AppColors.coralDeep;
        riskBg = AppColors.coralPale;
        break;
    }

    return Column(
      children: [
        Row(
          children: [
            // 1. Today's Cognitive Score
            Expanded(
              child: _buildSummaryCard(
                title: 'Cognitive Score',
                value: metrics['cognitiveScore'] ?? '78 / 100',
                subtitle: 'Target: 70+',
                icon: Icons.psychology_rounded,
                iconColor: AppColors.teal,
                bgColor: AppColors.tealPale,
                onTap: () => onNavigateTab(2),
              ),
            ),
            const SizedBox(width: 12),
            // 2. Games Completed Today
            Expanded(
              child: _buildSummaryCard(
                title: 'Games Completed',
                value: metrics['gamesCompleted'] ?? '3 / 4',
                subtitle: 'Daily goal: 4 games',
                icon: Icons.sports_esports_rounded,
                iconColor: AppColors.blueDeep,
                bgColor: AppColors.bluePale,
                onTap: () => onNavigateTab(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // 3. Daily Streak
            Expanded(
              child: _buildSummaryCard(
                title: 'Daily Streak',
                value: metrics['streak'] ?? '5 days',
                subtitle: 'Active engagement',
                icon: Icons.local_fire_department_rounded,
                iconColor: AppColors.coral,
                bgColor: AppColors.coralPale,
                onTap: () => onNavigateTab(2),
              ),
            ),
            const SizedBox(width: 12),
            // 4. Cognitive Risk Level
            Expanded(
              child: _buildSummaryCard(
                title: 'Screening Risk',
                value: risk.label.split(' ').first,
                subtitle: 'Non-clinical indicator',
                icon: Icons.shield_outlined,
                iconColor: riskColor,
                bgColor: riskBg,
                valueColor: riskColor,
                onTap: () => onNavigateTab(3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // 5. Last Assessment
            Expanded(
              child: _buildSummaryCard(
                title: 'Last Assessment',
                value: metrics['lastAssessment'] ?? 'Today, 10:45 AM',
                subtitle: 'Comprehensive check',
                icon: Icons.access_time_rounded,
                iconColor: AppColors.violetDeep,
                bgColor: AppColors.violetPale,
                onTap: () => onNavigateTab(2),
              ),
            ),
            const SizedBox(width: 12),
            // 6. Recent Activity Status
            Expanded(
              child: _buildSummaryCard(
                title: 'Recent Activity',
                value: 'Word Recall',
                subtitle: 'Score: 88% • 10m ago',
                icon: Icons.check_circle_outline_rounded,
                iconColor: AppColors.teal,
                bgColor: AppColors.softSection,
                onTap: () => onNavigateTab(2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    Color? valueColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: AppColors.muted,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? AppColors.ink,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // FIX: Added MRI Screening featured card to Caregiver Dashboard
  Widget _buildMriScreeningCard(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => context.push('/mri-screening'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight, width: 1.5),
            gradient: const LinearGradient(
              colors: [
                AppColors.tealBg,
                AppColors.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.tealPale,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.biotech_rounded,
                  color: AppColors.teal,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MRI Screening',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'AI-assisted dementia MRI screening',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Open',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // FIX: Added authorized caregiver/doctor activity access
  Widget _buildPatientActivitySection(
      BuildContext context, PatientProfile patient) {
    // Retrieve today's cached step record and recent 7-day history
    final today = StepStorageService.instance.getTodayRecordCached();
    final steps = today?.steps ?? 0;
    final goal = today?.goal ?? 10000;
    final progress = (steps / goal).clamp(0.0, 1.0);
    final remaining = (goal - steps).clamp(0, goal);
    final history = StepStorageService.instance
        .getRecentHistory(days: 7, patientId: patient.id);
    final syncStatus = today?.syncStatus ?? 'offline';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.tealPale,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.directions_walk_rounded,
                        color: AppColors.teal, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patient Activity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Daily Walking & Steps',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: syncStatus == 'synced'
                      ? AppColors.tealPale
                      : AppColors.softSection,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  syncStatus == 'synced' ? 'Synced' : 'Saved Locally',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: syncStatus == 'synced'
                        ? AppColors.tealDark
                        : AppColors.muted,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Steps Progress Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today: $steps / $goal',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}% completed',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.teal,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.tealPale,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            steps >= goal
                ? '🎉 Daily Goal Completed!'
                : '$remaining steps remaining to reach daily target',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: steps >= goal ? const Color(0xFF2E7D32) : AppColors.muted,
            ),
          ),

          if (history.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 10),
            const Text(
              'Recent History (Last 7 Days)',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkSoft),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: history.take(5).map((rec) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    '${rec.date.substring(5)}: ${rec.steps}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkSoft),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActionCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionPill(
            icon: Icons.alarm_add_rounded,
            label: 'Add Reminder',
            color: AppColors.teal,
            bgColor: AppColors.tealPale,
            onTap: () => onNavigateTab(3), // Alerts & Reminders tab
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionPill(
            icon: Icons.people_alt_outlined,
            label: 'Family Photos',
            color: AppColors.violetDeep,
            bgColor: AppColors.violetPale,
            onTap: () => onNavigateTab(4), // Profile & Safety tab
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionPill(
            icon: Icons.biotech_rounded,
            label: 'MRI Scan',
            color: AppColors.tealDark,
            bgColor: AppColors.tealPale,
            onTap: () => context.push('/mri-screening'),
          ),
        ),
      ],
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
