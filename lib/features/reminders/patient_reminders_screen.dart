// lib/features/reminders/patient_reminders_screen.dart
//
// FIX: Sync caregiver reminder changes to linked patient
//
// Dedicated Patient Reminders Screen:
// - Displays all active and upcoming reminders set by the Caregiver
// - Large, elderly-accessible touch targets and high-contrast typography
// - Displays scheduled time, repeat frequency, and status badges
// - Allows patient to acknowledge/complete reminders
// - Reactive via CaregiverService.instance.remindersNotifier

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/caregiver_models.dart';
import '../../core/services/caregiver_service.dart';

class PatientRemindersScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const PatientRemindersScreen({super.key, this.onBack});

  @override
  State<PatientRemindersScreen> createState() => _PatientRemindersScreenState();
}

class _PatientRemindersScreenState extends State<PatientRemindersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.ink, size: 28),
                onPressed: widget.onBack,
              )
            : null,
        title: Text(
          context.tr('reminders.title', defaultText: "Today's Reminders"),
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<int>(
          valueListenable: CaregiverService.instance.remindersNotifier,
          builder: (context, _, __) {
            final reminders = CaregiverService.instance.getReminders();
            // Patient view: show all reminders for today / ongoing
            if (reminders.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: AppColors.tealPale,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.done_all_rounded,
                          color: AppColors.teal,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        context.tr('reminders.noReminders',
                            defaultText: 'No Reminders For Today'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('reminders.caregiverSyncNotice',
                            defaultText:
                                'Your caregiver sets reminders for medication and daily routines.'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final pending =
                reminders.where((r) => !r.isCompleted && r.isEnabled).toList();
            final completed = reminders.where((r) => r.isCompleted).toList();
            final disabled = reminders.where((r) => !r.isEnabled).toList();

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              physics: const BouncingScrollPhysics(),
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.amberPale.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.amber.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.amberDeep, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.tr('reminders.caregiverControlledNotice',
                              defaultText:
                                  'Caregiver managed reminders with live phone alerts.'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (pending.isNotEmpty) ...[
                  Text(
                    context.tr('reminders.upcoming',
                        defaultText: 'Upcoming Tasks'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...pending.map((r) => _buildReminderTile(r, context)),
                  const SizedBox(height: 20),
                ],

                if (completed.isNotEmpty) ...[
                  Text(
                    context.tr('reminders.completed',
                        defaultText: 'Completed Today'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...completed.map((r) => _buildReminderTile(r, context)),
                  const SizedBox(height: 20),
                ],

                if (disabled.isNotEmpty) ...[
                  Text(
                    context.tr('reminders.paused',
                        defaultText: 'Paused by Caregiver'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...disabled.map((r) => _buildReminderTile(r, context)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildReminderTile(CaregiverReminder r, BuildContext context) {
    IconData iconData = Icons.alarm_rounded;
    Color iconColor = AppColors.amberDeep;
    Color iconBg = AppColors.amberPale;

    switch (r.type.toLowerCase()) {
      case 'medication':
        iconData = Icons.medication_rounded;
        iconColor = AppColors.coralDeep;
        iconBg = AppColors.coralPale;
        break;
      case 'hydration':
        iconData = Icons.water_drop_rounded;
        iconColor = AppColors.tealDark;
        iconBg = AppColors.tealPale;
        break;
      case 'meal':
        iconData = Icons.restaurant_rounded;
        iconColor = AppColors.amberDeep;
        iconBg = AppColors.amberPale;
        break;
      case 'activity':
      case 'exercise':
        iconData = Icons.directions_walk_rounded;
        iconColor = AppColors.violet;
        iconBg = AppColors.violetLight;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: r.isCompleted
            ? AppColors.surface.withValues(alpha: 0.6)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: r.isCompleted ? AppColors.borderLight : AppColors.border,
          width: 1.5,
        ),
        boxShadow: r.isCompleted
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: r.isCompleted ? Colors.grey.shade200 : iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconData,
              color: r.isCompleted ? Colors.grey.shade500 : iconColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: r.isCompleted ? AppColors.muted : AppColors.ink,
                    decoration:
                        r.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color:
                          r.isCompleted ? AppColors.muted : AppColors.amberDeep,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      r.time,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: r.isCompleted
                            ? AppColors.muted
                            : AppColors.amberDeep,
                      ),
                    ),
                    if (r.repeat.isNotEmpty && r.repeat != 'Once') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          r.repeat,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (r.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    r.description,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          r.isCompleted ? AppColors.muted : AppColors.inkSoft,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Action Button: Done / Completed
          if (!r.isCompleted && r.isEnabled)
            ElevatedButton(
              onPressed: () async {
                // FIX: Sync caregiver reminder changes to linked patient
                await CaregiverService.instance.acknowledgeReminder(r.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Completed: ${r.title}'),
                      backgroundColor: AppColors.tealDark,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                context.tr('reminders.done', defaultText: 'Done'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          else if (r.isCompleted)
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.teal,
              size: 28,
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Paused',
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ),
        ],
      ),
    );
  }
}
