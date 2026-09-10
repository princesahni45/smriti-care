// lib/features/caregiver/widgets/caregiver_stat_grid.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class CaregiverStatGrid extends StatelessWidget {
  final Map<String, String> metrics;

  const CaregiverStatGrid({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCard(
                label: "Today's activity",
                value: metrics['activityTime'] ?? '42 min',
                icon: Icons.access_time_rounded,
                color: AppColors.teal,
                bg: AppColors.tealPale,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCard(
                label: 'Cognitive score',
                value: metrics['cognitiveScore'] ?? '72 / 100',
                icon: Icons.trending_up_rounded,
                color: AppColors.violetDeep,
                bg: AppColors.violetPale,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCard(
                label: 'Medication',
                value: metrics['medication'] ?? '2 of 3 taken',
                icon: Icons.medication_rounded,
                color: AppColors.coralDeep,
                bg: AppColors.coralPale,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCard(
                label: 'Next appointment',
                value: metrics['nextAppointment'] ?? '12 Sep',
                icon: Icons.calendar_today_rounded,
                color: AppColors.blueDeep,
                bg: AppColors.bluePale,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
