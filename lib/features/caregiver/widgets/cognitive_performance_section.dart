// lib/features/caregiver/widgets/cognitive_performance_section.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/game_result.dart';
import '../../../core/services/game_storage_service.dart';
import '../../../core/services/caregiver_service.dart';

class CognitivePerformanceSection extends StatelessWidget {
  const CognitivePerformanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final patientId = CaregiverService.instance.selectedPatientId;
    final recentResults = GameStorageService.instance.getRecentResults(limit: 6, patientId: patientId);
    final totalGames = GameStorageService.instance.getTotalGamesCompleted(patientId: patientId);
    final streak = GameStorageService.instance.getCurrentStreakDays(patientId: patientId);
    final avgScore = GameStorageService.instance.getTodayScore(patientId: patientId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildMiniMetric('Completed', '$totalGames games', Icons.emoji_events_rounded, AppColors.teal),
            const SizedBox(width: 10),
            _buildMiniMetric('Streak', '$streak days', Icons.local_fire_department_rounded, AppColors.coral),
            const SizedBox(width: 10),
            _buildMiniMetric('Today Avg', '$avgScore%', Icons.stars_rounded, AppColors.amberDeep),
          ],
        ),
        const SizedBox(height: 20),

        const Text(
          'Recent Game Sessions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        const SizedBox(height: 12),

        if (recentResults.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Center(
              child: Text(
                'No cognitive games played yet. As the patient completes activities, their real-time performance and accuracy will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
              ),
            ),
          )
        else
          ...recentResults.map((r) => _buildGameResultTile(r)),
      ],
    );
  }

  Widget _buildMiniMetric(String label, String value, IconData icon, Color color) {
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
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
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
              '${r.score}%',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.tealDeep),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.gameName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  '${r.difficulty} • Accuracy: ${r.accuracy}% • Correct: ${r.correctAnswers}/${r.attempts}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                if (r.recommendation.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    r.recommendation,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.tealDark),
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
