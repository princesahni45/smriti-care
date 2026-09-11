// lib/features/caregiver/widgets/patient_cognitive_progress_card.dart
//
// FIX: Added real-time Patient Cognitive Progress card for Caregiver Dashboard
// Displays linked patient's real score data: latest score, game name, score/maxScore,
// percentage, date, 7-day average, trend if enough data exists, and offline cache state.

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/game_storage_service.dart';
import '../../../core/services/caregiver_service.dart';

class PatientCognitiveProgressCard extends StatelessWidget {
  final String? patientId;

  const PatientCognitiveProgressCard({super.key, this.patientId});

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final isToday =
        now.year == dt.year && now.month == dt.month && now.day == dt.day;

    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute $ampm';

    if (isToday) {
      return 'Today, $timeStr';
    }
    final isYesterday = now.subtract(const Duration(days: 1)).day == dt.day &&
        now.month == dt.month &&
        now.year == dt.year;
    if (isYesterday) {
      return 'Yesterday, $timeStr';
    }
    return '${dt.day}/${dt.month}/${dt.year}, $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    final effectivePatientId =
        patientId ?? CaregiverService.instance.selectedPatientId;
    final patient = CaregiverService.instance
        .getLinkedPatients()
        .firstWhere((p) => p.id == effectivePatientId,
            orElse: () => CaregiverService.instance.getPatientProfile());

    final history =
        GameStorageService.instance.getHistory(patientId: effectivePatientId);

    final sevenDayAvg = GameStorageService.instance
        .get7DayAveragePercentage(patientId: effectivePatientId);
    final trendInfo = GameStorageService.instance
        .getCognitiveTrend(patientId: effectivePatientId);

    final latestGame = history.isNotEmpty ? history.first : null;
    final isOfflineCached =
        history.isNotEmpty && history.any((r) => r.syncStatus == 'pending');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row: Title & Linked Patient Badge
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
                      Icons.insights_rounded,
                      color: AppColors.teal,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Patient Cognitive Progress',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tealPale,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  patient.fullName.split(' ').first,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.tealDark,
                  ),
                ),
              ),
            ],
          ),

          // ── Offline Warning if showing cached data
          if (isOfflineCached) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.amberPale,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.amberDeep.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off_rounded,
                      size: 16, color: AppColors.amberDeep),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Offline - showing last synced cognitive data',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.amberDeep,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          if (history.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.softSection,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text(
                  'No cognitive assessments completed yet for this patient.\nAs the patient completes games, real results will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.muted,
                    height: 1.4,
                  ),
                ),
              ),
            )
          else ...[
            // ── Latest Score Highlight Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.softSection,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        latestGame!.gameName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.teal,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${latestGame.normalizedPercentage}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Score: ${latestGame.score} / ${latestGame.maxScore}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 13, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Text(
                        'Last completed: ${_formatTimestamp(latestGame.timestamp)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── 7-Day Average & Trend Strip
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.tealPale.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.teal.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '7-Day Average',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.tealDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${sevenDayAvg.round()}%',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.tealDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Score Trend',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          trendInfo.hasEnoughData
                              ? (trendInfo.delta! >= 0
                                  ? '+${trendInfo.delta!.toStringAsFixed(0)}%'
                                  : '${trendInfo.delta!.toStringAsFixed(0)}%')
                              : 'Pending',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: trendInfo.hasEnoughData
                                ? (trendInfo.delta! >= 0
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFFC62828))
                                : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (!trendInfo.hasEnoughData) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 13, color: AppColors.muted),
                  SizedBox(width: 4),
                  Text(
                    'Not enough data for trend yet.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 18),

            // ── Recent Assessments List
            const Text(
              'Recent Assessments',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),

            ...history.take(4).map((r) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.gameName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${r.score} / ${r.maxScore} • ${_formatTimestamp(r.timestamp)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${r.normalizedPercentage}%',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.teal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
