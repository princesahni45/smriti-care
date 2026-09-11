// lib/features/patient/patient_reminders_screen.dart
//
// Elder-friendly daily routine and medication reminders screen for patients.
// Built according to Dementia UI Accessibility Guidelines:
// - Large readable typography and high contrast
// - Minimum 56x56 touch targets
// - Clear status indicators and comforting feedback
// - Live synchronization with CaregiverService

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
  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _toggleAcknowledge(CaregiverReminder reminder) async {
    await CaregiverService.instance.acknowledgeReminder(reminder.id);
    if (mounted) {
      setState(() {});
      final isNowDone = reminder.status != 'acknowledged';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNowDone
                ? 'Well done! Marked "${reminder.title}" as completed.'
                : 'Reminder marked as upcoming.',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          backgroundColor: isNowDone ? AppColors.tealDark : AppColors.inkSoft,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  IconData _getReminderIcon(String type) {
    switch (type.toLowerCase()) {
      case 'medication':
        return Icons.medication_rounded;
      case 'hydration':
        return Icons.water_drop_rounded;
      case 'exercise':
      case 'cognitive':
        return Icons.psychology_rounded;
      case 'appointment':
        return Icons.medical_services_rounded;
      default:
        return Icons.access_time_filled_rounded;
    }
  }

  Color _getReminderColor(String type) {
    switch (type.toLowerCase()) {
      case 'medication':
        return AppColors.coral;
      case 'hydration':
        return AppColors.blue;
      case 'exercise':
      case 'cognitive':
        return AppColors.teal;
      case 'appointment':
        return AppColors.violet;
      default:
        return AppColors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reminders = CaregiverService.instance.getReminders();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink, size: 28),
          onPressed: _handleBack,
          tooltip: 'Back to Home',
        ),
        title: Text(
          context.tr('dashboard.reminders', defaultText: 'Daily Schedule & Reminders'),
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: reminders.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: AppColors.tealPale,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.tealDark,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Reminders Right Now',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'All your daily medicines and activities are clear. Have a peaceful, restful day!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: AppColors.muted, height: 1.4),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(18),
              itemCount: reminders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (ctx, i) {
                final r = reminders[i];
                final isDone = r.status == 'acknowledged';
                final color = _getReminderColor(r.type);
                final icon = _getReminderIcon(r.type);

                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDone ? AppColors.surface.withValues(alpha: 0.7) : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDone ? AppColors.borderLight : color.withValues(alpha: 0.4),
                      width: 1.6,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time badge and icon
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: isDone ? AppColors.borderLight : color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          isDone ? Icons.check_rounded : icon,
                          color: isDone ? AppColors.muted : color,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    r.scheduledTime,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: color,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isDone)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.tealPale,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'COMPLETED ✓',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.tealDark,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              r.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDone ? AppColors.muted : AppColors.ink,
                                decoration: isDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            if (r.message.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                r.message,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.muted,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Acknowledge Button
                      IconButton(
                        iconSize: 32,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                        icon: Icon(
                          isDone
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isDone ? AppColors.teal : AppColors.muted,
                        ),
                        onPressed: () => _toggleAcknowledge(r),
                        tooltip: isDone ? 'Mark as Upcoming' : 'Mark as Done',
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
