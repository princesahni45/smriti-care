// lib/features/patient/widgets/patient_cognitive_performance_card.dart
//
// FIX: Added real-time elder-friendly cognitive performance card for Patient Dashboard
// Displays own latest cognitive performance, domain scores, normalized percentage,
// latest assessment, and real trend without faking data.

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/game_result.dart';
import '../../../core/services/game_storage_service.dart';
import '../../../core/services/caregiver_service.dart';

class PatientCognitivePerformanceCard extends StatefulWidget {
  const PatientCognitivePerformanceCard({super.key});

  @override
  State<PatientCognitivePerformanceCard> createState() =>
      _PatientCognitivePerformanceCardState();
}

class _PatientCognitivePerformanceCardState
    extends State<PatientCognitivePerformanceCard> {
  @override
  Widget build(BuildContext context) {
    final patient = CaregiverService.instance.getPatientProfile();
    final history =
        GameStorageService.instance.getHistory(patientId: patient.id);

    final trendInfo =
        GameStorageService.instance.getCognitiveTrend(patientId: patient.id);

    // Latest overall assessment or latest game
    final latestGame = history.isNotEmpty ? history.first : null;
    final latestScore = latestGame?.normalizedPercentage ?? 0;

    // Collect distinct latest games by domain/gameId
    final Map<String, GameResult> latestByDomain = {};
    for (final r in history) {
      if (!latestByDomain.containsKey(r.gameId)) {
        latestByDomain[r.gameId] = r;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row: Icon + Section Title
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
                    child: const Icon(
                      Icons.psychology_rounded,
                      color: AppColors.teal,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cognitive Performance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Recent game results',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (history.isNotEmpty && history.first.syncStatus == 'pending')
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.amberPale,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_queue_rounded,
                          size: 13, color: AppColors.amberDeep),
                      SizedBox(width: 4),
                      Text(
                        'Offline Saved',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.amberDeep,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 18),

          if (history.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.softSection,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text(
                  'No games completed yet.\nPlay a game above to see your score!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                    height: 1.4,
                  ),
                ),
              ),
            )
          else ...[
            // ── Domain breakdown items
            ...latestByDomain.values.take(3).map((game) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        game.gameName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.tealPale,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${game.normalizedPercentage}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.tealDark,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 10),
            const Divider(color: AppColors.borderLight, height: 1),
            const SizedBox(height: 12),

            // ── Latest Assessment Banner
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Latest Assessment',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  '$latestScore%',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.teal,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // ── Trend Row (strictly real data)
            Row(
              children: [
                Icon(
                  trendInfo.hasEnoughData
                      ? (trendInfo.delta! >= 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded)
                      : Icons.info_outline_rounded,
                  size: 15,
                  color: trendInfo.hasEnoughData
                      ? (trendInfo.delta! >= 0
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFC62828))
                      : AppColors.muted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    trendInfo.text,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: trendInfo.hasEnoughData
                          ? (trendInfo.delta! >= 0
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFC62828))
                          : AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
