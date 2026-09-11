// lib/features/caregiver/tabs/caregiver_progress_tab.dart
//
// Patient Progress & Cognitive Reports Tab:
// - Graphical progress tracking (Daily, Weekly, Monthly)
// - Response Time Tracking & Accuracy Rate
// - Assessment History log
// - Dedicated 7 Cognitive Game Reports Breakdown:
//   1. Word Recall Game
//   2. Delayed Recall Game
//   3. Day & Time Orientation
//   4. Attention & Focus
//   5. Sequence & Number
//   6. Pattern Recognition
//   7. Family Memories Game

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/caregiver_models.dart';
import '../../../core/services/caregiver_service.dart';
import '../../../core/services/game_storage_service.dart';
import '../widgets/weekly_engagement_chart.dart';

class CaregiverProgressTab extends StatefulWidget {
  const CaregiverProgressTab({super.key});

  @override
  State<CaregiverProgressTab> createState() => _CaregiverProgressTabState();
}

class _CaregiverProgressTabState extends State<CaregiverProgressTab> {
  int _chartPeriod = 0; // 0: Weekly, 1: Monthly

  @override
  Widget build(BuildContext context) {
    final selectedPatient = CaregiverService.instance.getPatientProfile();
    final weeklyData = CaregiverService.instance.getWeeklyEngagement(patientId: selectedPatient.id);
    final assessmentHistory = CaregiverService.instance.getAssessmentHistory(patientId: selectedPatient.id);
    final gameReports = CaregiverService.instance.getCognitiveGameReports(patientId: selectedPatient.id);

    final totalGames = GameStorageService.instance.getTotalGamesCompleted(patientId: selectedPatient.id);
    final avgResponseTime = GameStorageService.instance.getAverageResponseTime(patientId: selectedPatient.id);
    final overallAccuracy = GameStorageService.instance.getAverageAccuracy(patientId: selectedPatient.id);

    final avgTimeStr = totalGames > 0 ? '${avgResponseTime.toStringAsFixed(1)} sec' : '--';
    final avgTimeSubtitle = totalGames > 0 ? 'Across $totalGames sessions' : 'No sessions completed';
    final accuracyStr = totalGames > 0 ? '${overallAccuracy.round()}%' : '--';
    final accuracySubtitle = totalGames > 0
        ? (overallAccuracy >= 80 ? 'Consistent stability' : 'Needs daily practice')
        : 'No sessions completed';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cognitive Progress & Reports',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: -0.4,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tealPale,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  selectedPatient.fullName.split(' ').first,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.tealDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Live analytics across cognitive domains and response speed.',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 18),

          // Key Performance Metrics Strip (Response Time & Accuracy)
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Avg Response Time',
                  value: avgTimeStr,
                  subtitle: avgTimeSubtitle,
                  icon: Icons.timer_outlined,
                  color: AppColors.teal,
                  bgColor: AppColors.tealPale,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Overall Accuracy',
                  value: accuracyStr,
                  subtitle: accuracySubtitle,
                  icon: Icons.pie_chart_outline_rounded,
                  color: AppColors.blueDeep,
                  bgColor: AppColors.bluePale,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Chart Section with Period Switcher
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
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
                    const Text(
                      'Performance Trends',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    // Toggle Weekly vs Monthly
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.softSection,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          _buildPeriodBtn('Weekly', _chartPeriod == 0,
                              () => setState(() => _chartPeriod = 0)),
                          _buildPeriodBtn('Monthly', _chartPeriod == 1,
                              () => setState(() => _chartPeriod = 1)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_chartPeriod == 0)
                  WeeklyEngagementChart(data: weeklyData)
                else
                  _buildMonthlyChart(),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 7 Dedicated Cognitive Game Reports Breakdown
          const Row(
            children: [
              Icon(Icons.psychology_rounded, color: AppColors.teal, size: 22),
              SizedBox(width: 8),
              Text(
                'Individual Game Reports',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Domain breakdown for Word Recall, Orientation, Attention, Sequence, and Memory.',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 14),

          // Render all 7 game reports
          ...gameReports.map((report) => _buildGameReportCard(report)),

          const SizedBox(height: 24),

          // Assessment History Log
          const Row(
            children: [
              Icon(Icons.history_rounded, color: AppColors.teal, size: 22),
              SizedBox(width: 8),
              Text(
                'Assessment History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          if (assessmentHistory.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight, width: 1.2),
              ),
              child: const Center(
                child: Text(
                  'No assessment history yet for this patient.\nCompleted cognitive sessions will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight, width: 1.2),
              ),
              child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: assessmentHistory.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.borderLight),
              itemBuilder: (ctx, idx) {
                final item = assessmentHistory[idx];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.tealPale,
                    child: Text(
                      '${item["score"]}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.tealDark,
                      ),
                    ),
                  ),
                  title: Text(
                    '${item["type"]} • ${item["date"]}',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink),
                  ),
                  subtitle: Text(
                    'Time: ${item["time"]} • Status: ${item["status"]}',
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.tealPale,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${item["status"]}',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.tealDark),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPeriodBtn(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4)
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppColors.tealDark : AppColors.muted,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: bgColor, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.tealDark),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart() {
    final monthly = CaregiverService.instance.getMonthlyEngagement();
    return Column(
      children: [
        const SizedBox(height: 10),
        SizedBox(
          height: 140,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: monthly.map((m) {
              final score = (m['score'] as num).toDouble();
              final heightRatio = (score / 100).clamp(0.1, 1.0);
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    '%',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 28,
                    height: 90 * heightRatio,
                    decoration: BoxDecoration(
                      color: AppColors.teal,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    m['month'] as String,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkSoft),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildGameReportCard(CognitiveGameReport report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.tealPale,
                child: Text(
                  '%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.tealDark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink),
                    ),
                    Text(
                      report.category,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.tealPale,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Stable',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tealDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.softSection,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ': ',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkSoft),
                ),
                Text(
                  ': ',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            report.statusDescription,
            style: const TextStyle(
                fontSize: 12, color: AppColors.muted, height: 1.3),
          ),
        ],
      ),
    );
  }
}
