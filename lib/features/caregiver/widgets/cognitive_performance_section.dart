// lib/features/caregiver/widgets/cognitive_performance_section.dart
//
// FIX: Save cognitive game result for caregiver dashboard
// Live real-time cognitive progress section for Caregiver Dashboard.
// Shows latest game, score / max score, normalized percentage, date/time,
// real 7-day average, and recent game history for the selected patient.

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/game_result.dart';
import '../../../core/services/game_storage_service.dart';
import '../../../core/services/caregiver_service.dart';

class CognitivePerformanceSection extends StatelessWidget {
  const CognitivePerformanceSection({super.key});

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute $ampm';

    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'Today, $timeStr';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day) {
      return 'Yesterday, $timeStr';
    }
    return '${dt.day}/${dt.month}/${dt.year}, $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    final patientId = CaregiverService.instance.selectedPatientId;

    return ValueListenableBuilder<int>(
      valueListenable: GameStorageService.instance.changeNotifier,
      builder: (context, _, __) {
        final latest = GameStorageService.instance
            .getLatestGameResult(patientId: patientId);
        final recentResults = GameStorageService.instance
            .getRecentResults(limit: 6, patientId: patientId);
        final totalGames = GameStorageService.instance
            .getTotalGamesCompleted(patientId: patientId);
        final streak = GameStorageService.instance
            .getCurrentStreakDays(patientId: patientId);
        final avg7Day = GameStorageService.instance
            .get7DayAverageScore(patientId: patientId);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section Title
            const Text(
              'Patient Cognitive Progress',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 14),

            // ── Featured Latest Game Card (Section 5 Specs)
            if (latest != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.tealPale, AppColors.surface],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.teal,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.psychology_rounded,
                                  color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'LATEST ACTIVITY',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.tealDark,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Text(
                                  latest.gameName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: latest.syncStatus == 'synced'
                                ? const Color(0xFFE8F5E9)
                                : AppColors.amberPale,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            latest.syncStatus == 'synced'
                                ? 'Synced'
                                : 'Offline Saved',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: latest.syncStatus == 'synced'
                                  ? const Color(0xFF1B5E20)
                                  : AppColors.amberDeep,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${latest.score} / ${latest.maxScore}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: AppColors.ink,
                                letterSpacing: -1,
                              ),
                            ),
                            Text(
                              'Last played: ${_formatDateTime(latest.timestamp)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppColors.teal.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            '${latest.percentage.round()}%',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppColors.tealDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Summary Metrics Row
            Row(
              children: [
                _buildMiniMetric('Completed', '$totalGames games',
                    Icons.emoji_events_rounded, AppColors.teal),
                const SizedBox(width: 10),
                _buildMiniMetric('Streak', '$streak days',
                    Icons.local_fire_department_rounded, AppColors.coral),
                const SizedBox(width: 10),
                _buildMiniMetric(
                    '7-Day Avg',
                    avg7Day > 0 ? '${avg7Day.round()}%' : 'N/A',
                    Icons.stars_rounded,
                    AppColors.amberDeep),
              ],
            ),

            const SizedBox(height: 20),

            // ── Recent Sessions Subtitle
            const Text(
              'Recent Game Sessions',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),

            if (recentResults.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.sports_esports_outlined,
                        size: 36, color: AppColors.muted),
                    SizedBox(height: 10),
                    Text(
                      'No cognitive games played yet for this patient.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkSoft,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Whenever the patient completes any game on their phone, their real score will appear here automatically.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...recentResults.map((r) => _buildGameResultTile(r)),
          ],
        );
      },
    );
  }

  Widget _buildMiniMetric(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameResultTile(GameResult r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.tealPale,
            child: Text(
              '${r.percentage.round()}%',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: AppColors.tealDeep,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.gameName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${r.difficulty} • Score: ${r.score}/${r.maxScore} • ${_formatDateTime(r.timestamp)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                if (r.recommendation.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    r.recommendation,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tealDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
