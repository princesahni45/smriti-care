// lib/widgets/quick_action_card.dart
//
// Elderly-friendly, large touch-target quick action cards.
// Designed with high contrast, large icons, readable typography, and soft category colors.

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

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
              color: item.color.withOpacity(0.35),
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: item.color.withOpacity(0.08),
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
                      color: item.color.withOpacity(0.12),
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
                    color: item.color.withOpacity(0.7),
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

  static const List<QuickActionItem> items = [
    QuickActionItem(
      id: 'games',
      title: 'Cognitive Games',
      subtitle: 'Gentle brain play',
      icon: Icons.psychology_rounded,
      color: AppColors.teal,
    ),
    QuickActionItem(
      id: 'reminders',
      title: 'Reminders',
      subtitle: 'Pills & schedules',
      icon: Icons.access_time_filled_rounded,
      color: AppColors.amber,
    ),
    QuickActionItem(
      id: 'emergency',
      title: 'Emergency SOS',
      subtitle: 'One-tap alerts',
      icon: Icons.emergency_rounded,
      color: AppColors.coral,
    ),
    QuickActionItem(
      id: 'location',
      title: 'Safe Location',
      subtitle: 'Take me home',
      icon: Icons.location_on_rounded,
      color: AppColors.blue,
    ),
    QuickActionItem(
      id: 'progress',
      title: 'Your Progress',
      subtitle: 'Daily memory stats',
      icon: Icons.bar_chart_rounded,
      color: AppColors.violet,
    ),
    QuickActionItem(
      id: 'caregiver',
      title: 'Caregiver',
      subtitle: 'Family connection',
      icon: Icons.family_restroom_rounded,
      color: AppColors.navy,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Icon(Icons.touch_app_rounded, size: 22, color: AppColors.teal),
              SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: TextStyle(
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
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
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
