// lib/widgets/next_reminder_card.dart
//
// High-visibility, elderly-friendly card for upcoming reminders.
// Displays:
// - Title: "Next Reminder"
// - Item: Medicine 💊
// - Time: 10:00 AM
// - Clear tap action to open Reminders placeholder.

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/localization/app_localizations.dart';

class NextReminderCard extends StatelessWidget {
  final String? title;
  final String time;
  final String? note;
  final VoidCallback onTap;

  const NextReminderCard({
    super.key,
    this.title,
    this.time = '10:00 AM',
    this.note,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayTitle = title ??
        context.tr('reminders.morningMedicine',
            defaultText: 'Morning Medicine');
    final displayNote = note ??
        context.tr('reminders.morningMedicineNote',
            defaultText: 'Take with a glass of water after breakfast');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Icon(Icons.alarm_on_rounded,
                  size: 20, color: AppColors.amber),
              const SizedBox(width: 8),
              Text(
                context.tr('reminders.nextReminder',
                    defaultText: 'Next Reminder'),
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
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.amberPale,
                    AppColors.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.amber.withValues(alpha: 0.35),
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.amber.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Pill / Medicine Icon Bubble
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.amber.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.medication_rounded,
                        color: AppColors.amberDeep,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Reminder details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                displayTitle,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Time badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.amberDeep,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.access_time_filled_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    time,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          displayNote,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
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
          ),
        ),
      ],
    );
  }
}
