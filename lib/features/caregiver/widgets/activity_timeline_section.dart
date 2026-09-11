// lib/features/caregiver/widgets/activity_timeline_section.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/caregiver_models.dart';
import '../../../core/services/caregiver_service.dart';

class ActivityTimelineSection extends StatelessWidget {
  const ActivityTimelineSection({super.key});

  @override
  Widget build(BuildContext context) {
    final activities = CaregiverService.instance.getRecentActivities();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Patient Activity',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        const SizedBox(height: 12),
        ...activities.map((a) => _buildTimelineTile(a)),
      ],
    );
  }

  Widget _buildTimelineTile(CaregiverActivityItem item) {
    IconData icon;
    Color color;
    Color bg;

    switch (item.iconType) {
      case 'game':
        icon = Icons.psychology_rounded;
        color = AppColors.teal;
        bg = AppColors.tealPale;
        break;
      case 'medication':
        icon = Icons.medication_rounded;
        color = AppColors.coralDeep;
        bg = AppColors.coralPale;
        break;
      case 'hydration':
        icon = Icons.water_drop_rounded;
        color = AppColors.blueDeep;
        bg = AppColors.bluePale;
        break;
      default:
        icon = Icons.check_circle_outline_rounded;
        color = AppColors.amberDeep;
        bg = AppColors.amberPale;
        break;
    }

    return Container(
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink),
                ),
                Text(
                  item.subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Text(
            item.timeAgo,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
