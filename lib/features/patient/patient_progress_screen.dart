// lib/features/patient/patient_progress_screen.dart
//
// Elder-friendly Cognitive Progress & History Screen for Patients.
// Displays live statistics from GameStorageService:
// - Streak, games played, and average accuracy
// - Per-game performance indicators
// - Recent activity log with comforting encouraging feedback

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/game_storage_service.dart';

class PatientProgressScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const PatientProgressScreen({super.key, this.onBack});

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = GameStorageService.instance;
    final totalGames = storage.getTotalGamesCompleted();
    final streakDays = storage.getCurrentStreakDays();
    final avgAccuracy = storage.getAverageAccuracy();
    final recentResults = storage.getRecentResults(limit: 5);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink, size: 28),
          onPressed: () => _handleBack(context),
          tooltip: 'Back to Home',
        ),
        title: Text(
          context.tr('dashboard.progress', defaultText: 'Your Activity & Progress'),
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top 3 Stat Cards ──────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    icon: Icons.emoji_events_rounded,
                    color: AppColors.amber,
                    bgColor: AppColors.amberPale,
                    value: '$totalGames',
                    label: 'Games Played',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    icon: Icons.local_fire_department_rounded,
                    color: AppColors.coral,
                    bgColor: AppColors.coralPale,
                    value: '$streakDays d',
                    label: 'Day Streak',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    icon: Icons.verified_rounded,
                    color: AppColors.teal,
                    bgColor: AppColors.tealPale,
                    value: totalGames > 0 ? '$avgAccuracy%' : '--',
                    label: 'Avg Score',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Encouraging Affirmation Banner ───────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.tealPale.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.teal,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wonderful Effort!',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Practicing gentle cognitive games every day helps keep your mind bright and active.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.inkSoft,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Game Breakdown Cards ─────────────────────────────────
            const Text(
              'Activity Breakdown',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 14),

            _buildGameRow(
              title: 'Memory Match',
              icon: Icons.psychology_rounded,
              color: AppColors.teal,
              stats: storage.getStatsForGame('memory-match'),
            ),
            const SizedBox(height: 10),
            _buildGameRow(
              title: 'Word Recall',
              icon: Icons.menu_book_rounded,
              color: AppColors.violet,
              stats: storage.getStatsForGame('word-recall'),
            ),
            const SizedBox(height: 10),
            _buildGameRow(
              title: 'Find the Different Object',
              icon: Icons.auto_awesome_rounded,
              color: AppColors.amber,
              stats: storage.getStatsForGame('different-object'),
            ),
            const SizedBox(height: 10),
            _buildGameRow(
              title: 'Day & Time Orientation',
              icon: Icons.calendar_month_rounded,
              color: AppColors.blue,
              stats: storage.getStatsForGame('day-time-orientation'),
            ),
            const SizedBox(height: 10),
            _buildGameRow(
              title: 'Daily Routine Sequence',
              icon: Icons.low_priority_rounded,
              color: AppColors.coral,
              stats: storage.getStatsForGame('routine-sequence'),
            ),
            const SizedBox(height: 10),
            _buildGameRow(
              title: 'Family Memories',
              icon: Icons.family_restroom_rounded,
              color: AppColors.teal,
              stats: storage.getStatsForGame('family-memories'),
            ),

            const SizedBox(height: 28),

            // ── Recent Activity History ─────────────────────────────
            const Text(
              'Recent Activity History',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),

            if (recentResults.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.sports_esports_outlined, size: 40, color: AppColors.muted),
                    SizedBox(height: 10),
                    Text(
                      'No games played yet',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Play a fun game from the Games tab to start building your cognitive progress history!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                  ],
                ),
              )
            else
              ...recentResults.map(
                (r) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.tealPale,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.gameName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              '${r.timestamp.day}/${r.timestamp.month}/${r.timestamp.year} • ${r.difficulty}',
                              style: const TextStyle(fontSize: 12, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: r.accuracy >= 75 ? AppColors.tealPale : AppColors.amberPale,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${r.accuracy}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: r.accuracy >= 75 ? AppColors.tealDark : AppColors.amberDeep,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameRow({
    required String title,
    required IconData icon,
    required Color color,
    required dynamic stats,
  }) {
    final int gamesPlayed = (stats.gamesPlayed as num?)?.toInt() ?? 0;
    final int avgAccuracy = (stats.avgAccuracy as num?)?.round() ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          Text(
            gamesPlayed > 0 ? '$avgAccuracy% ($gamesPlayed played)' : 'Not played yet',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: gamesPlayed > 0 ? AppColors.tealDark : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
