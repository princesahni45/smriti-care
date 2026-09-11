```dart
// lib/features/caregiver/widgets/cognitive_performance_section.dart

import 'package:flutter/material.dart';

import '../../../core/models/game_result.dart';
import '../../../core/services/caregiver_service.dart';
import '../../../core/services/game_storage_service.dart';
import '../../../core/theme/app_theme.dart';

class CognitivePerformanceSection extends StatelessWidget {
  const CognitivePerformanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final caregiverService = CaregiverService.instance;
    final gameStorageService = GameStorageService.instance;

    final patientId = caregiverService.selectedPatientId;

    final recentResults = gameStorageService.getRecentResults(
      limit: 6,
      patientId: patientId,
    );

    final totalGames = gameStorageService.getTotalGamesCompleted(
      patientId: patientId,
    );

    final streak = gameStorageService.getCurrentStreakDays(
      patientId: patientId,
    );

    final avgScore = gameStorageService.getTodayScore(
      patientId: patientId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildMiniMetric(
              label: 'Completed',
              value: '$totalGames games',
              icon: Icons.emoji_events_rounded,
              color: AppColors.teal,
            ),
            const SizedBox(width: 10),
            _buildMiniMetric(
              label: 'Streak',
              value: '$streak days',
              icon: Icons.local_fire_department_rounded,
              color: AppColors.coral,
            ),
            const SizedBox(width: 10),
            _buildMiniMetric(
              label: 'Today Avg',
              value: '$avgScore%',
              icon: Icons.stars_rounded,
              color: AppColors.amberDeep,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Recent Game Sessions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 12),
        if (recentResults.isEmpty)
          _buildEmptyState()
        else
          ...recentResults.map(_buildGameResultTile),
      ],
    );
  }

  Widget _buildMiniMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 10,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.borderLight,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight,
        ),
      ),
      child: const Center(
        child: Text(
          'No cognitive games played yet. As the patient completes activities, their real-time performance and accuracy will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildGameResultTile(GameResult result) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.tealPale,
            child: Text(
              '${result.score}%',
              textAlign: TextAlign.center,
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
                  result.gameName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${result.difficulty} • '
                  'Accuracy: ${result.accuracy}% • '
                  'Correct: ${result.correctAnswers}/${result.attempts}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
                if (result.recommendation.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    result.recommendation,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tealDark,
                    ),
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
```
