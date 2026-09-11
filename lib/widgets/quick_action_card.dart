// lib/widgets/quick_action_card.dart
//
// Elderly-friendly, large touch-target quick action cards.
// Designed with high contrast, large icons, readable typography, and soft category colors.

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/localization/app_localizations.dart';

class QuickActionItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const QuickActionItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class QuickActionCard extends StatelessWidget {
  final QuickActionItem item;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: item.color.withValues(alpha: 0.35),
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: item.color.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon inside circular tinted bubble
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        item.icon,
                        color: item.color,
                        size: 26,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: item.color.withValues(alpha: 0.7),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title & Subtitle
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickActionsGrid extends StatelessWidget {
  final void Function(String moduleId) onActionTap;

  const QuickActionsGrid({super.key, required this.onActionTap});

  List<QuickActionItem> _getItems(BuildContext context) => [
        QuickActionItem(
          id: 'games',
          title: context.tr('landing.cognitiveGames',
              defaultText: 'Cognitive Games'),
          subtitle: context.tr('patient.trainMemory',
              defaultText: 'Gentle brain play'),
          icon: Icons.psychology_rounded,
          color: AppColors.teal,
        ),
        QuickActionItem(
          id: 'assessment',
          title: context.tr('landing.aiPersonalization',
              defaultText: 'Cognitive Check'),
          subtitle: context.tr('landing.featAIDesc',
              defaultText: 'Gentle assessment'),
          icon: Icons.assignment_turned_in_rounded,
          color: AppColors.blue,
        ),
        const QuickActionItem(
          id: 'mri',
          title: 'MRI Screening',
          subtitle: 'AI structural scan',
          icon: Icons.document_scanner_rounded,
          color: AppColors.violet,
        ),
        QuickActionItem(
          id: 'emergency',
          title: context.tr('sos.sosButton', defaultText: 'Emergency SOS'),
          subtitle: context.tr('sos.takeMeHome', defaultText: 'Take me home'),
          icon: Icons.emergency_rounded,
          color: AppColors.coral,
        ),
        QuickActionItem(
          id: 'reminders',
          title: context.tr('reminders.title', defaultText: 'Reminders'),
          subtitle:
              context.tr('reminders.routine', defaultText: 'Pills & routine'),
          icon: Icons.access_time_filled_rounded,
          color: AppColors.amber,
        ),
        QuickActionItem(
          id: 'caregiver',
          title:
              context.tr('caregiver.portal', defaultText: 'Caregiver Portal'),
          subtitle: context.tr('landing.careCircle',
              defaultText: 'Family & insights'),
          icon: Icons.family_restroom_rounded,
          color: AppColors.navy,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final activeItems = _getItems(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Icon(Icons.touch_app_rounded,
                  size: 22, color: AppColors.teal),
              const SizedBox(width: 8),
              Text(
                context.tr('patient.todayActivities',
                    defaultText: 'Quick Actions'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activeItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (context, index) {
            final item = activeItems[index];
            return QuickActionCard(
              item: item,
              onTap: () => onActionTap(item.id),
            );
          },
        ),
      ],
    );
  }
}
