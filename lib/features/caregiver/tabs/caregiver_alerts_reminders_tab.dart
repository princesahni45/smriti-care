// lib/features/caregiver/tabs/caregiver_alerts_reminders_tab.dart
//
// Cognitive Risk Screening, Intelligent Alerts & Reminders Management Tab:
// - Screening indicator (Low / Moderate / High) with clinical disclaimer
// - Intelligent care alerts (score drops, missed medication, routine delays, SOS)
// - Reminders Management:
//   - Filter by Medicine, Appointment, Routine
//   - Toggle ON / OFF switch
//   - Add, Edit, Delete reminders

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/caregiver_models.dart';
import '../../../core/services/caregiver_service.dart';

class CaregiverAlertsRemindersTab extends StatefulWidget {
  const CaregiverAlertsRemindersTab({super.key});

  @override
  State<CaregiverAlertsRemindersTab> createState() =>
      _CaregiverAlertsRemindersTabState();
}

class _CaregiverAlertsRemindersTabState
    extends State<CaregiverAlertsRemindersTab> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final risk = CaregiverService.instance.getRiskAssessment();
    final alerts = CaregiverService.instance.getAlerts();
    final reminders =
        CaregiverService.instance.getReminders(type: _selectedCategory);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            context.tr('caregiver.riskAndRemindersTitle',
                defaultText: 'Risk Screening & Reminders'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('caregiver.riskAndRemindersSubtitle',
                defaultText:
                    'Real-time cognitive safety screening and patient routine scheduling.'),
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 18),

          // Cognitive Risk Level Screening Card
          _buildRiskScreeningCard(risk),

          const SizedBox(height: 22),

          // Intelligent Care Alerts Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications_active_outlined,
                      color: AppColors.coral, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${context.tr('caregiver.intelligentAlerts', defaultText: 'Intelligent Care Alerts')} (${alerts.length})',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (alerts.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Center(
                child: Text(
                  context.tr('caregiver.noAlerts',
                      defaultText: 'No active care alerts.'),
                  style: const TextStyle(color: AppColors.muted),
                ),
              ),
            )
          else
            ...alerts.map((a) => _buildAlertTile(a)),

          const SizedBox(height: 26),

          // Reminders Management Header with Add Reminder button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.alarm_rounded,
                      color: AppColors.teal, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('caregiver.manageReminders',
                        defaultText: 'Manage Reminders'),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _openAddReminderDialog(context),
                icon: const Icon(Icons.add_rounded,
                    size: 16, color: Colors.white),
                label: Text(
                  context.tr('caregiver.add', defaultText: 'Add'),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                    'all',
                    context.tr('caregiver.allReminders',
                        defaultText: 'All Reminders')),
                const SizedBox(width: 8),
                _buildFilterChip(
                    'medication',
                    context.tr('reminders.morningMedicine',
                        defaultText: 'Medicine')),
                const SizedBox(width: 8),
                _buildFilterChip(
                    'appointment',
                    context.tr('caregiver.appointments',
                        defaultText: 'Appointments')),
                const SizedBox(width: 8),
                _buildFilterChip(
                    'daily_routine',
                    context.tr('landing.dailyActivities',
                        defaultText: 'Routine')),
                const SizedBox(width: 8),
                _buildFilterChip(
                    'hydration',
                    context.tr('reminders.hydration',
                        defaultText: 'Hydration')),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Reminders List
          if (reminders.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Center(
                child: Text(
                  'No reminders found for this category.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ),
            )
          else
            ...reminders.map((r) => _buildReminderItem(r)),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRiskScreeningCard(RiskAssessment risk) {
    Color badgeColor;
    Color badgeBg;
    switch (risk.level) {
      case RiskLevel.low:
        badgeColor = AppColors.tealDark;
        badgeBg = AppColors.tealPale;
        break;
      case RiskLevel.moderate:
        badgeColor = AppColors.amberDeep;
        badgeBg = AppColors.amberPale;
        break;
      case RiskLevel.high:
        badgeColor = AppColors.coralDeep;
        badgeBg = AppColors.coralPale;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(10)),
                    child:
                        Icon(Icons.shield_rounded, color: badgeColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    risk.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: badgeColor,
                    ),
                  ),
                ],
              ),
              const Text(
                'Score:  / 100',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            risk.summary,
            style: const TextStyle(
                fontSize: 13, color: AppColors.inkSoft, height: 1.4),
          ),
          const SizedBox(height: 12),
          // Disclaimer alert box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.softSection,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: AppColors.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    risk.disclaimer,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertTile(CaregiverAlert alert) {
    Color iconColor;
    Color bgColor;
    switch (alert.type) {
      case 'emergency_sos':
        iconColor = AppColors.coralDeep;
        bgColor = AppColors.coralPale;
        break;
      case 'score_drop':
        iconColor = AppColors.amberDeep;
        bgColor = AppColors.amberPale;
        break;
      default:
        iconColor = AppColors.teal;
        bgColor = AppColors.tealPale;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: alert.acknowledged ? AppColors.softSection : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: alert.acknowledged
              ? AppColors.borderLight
              : iconColor.withValues(alpha: 0.4),
          width: alert.acknowledged ? 1 : 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: bgColor, borderRadius: BorderRadius.circular(8)),
            child: Icon(
              alert.type == 'emergency_sos'
                  ? Icons.emergency_rounded
                  : Icons.notifications_rounded,
              color: iconColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color:
                        alert.acknowledged ? AppColors.inkSoft : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alert.message,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.muted, height: 1.3),
                ),
              ],
            ),
          ),
          if (!alert.acknowledged)
            IconButton(
              icon: const Icon(Icons.check_rounded,
                  size: 18, color: AppColors.teal),
              onPressed: () async {
                await CaregiverService.instance.dismissAlert(alert.id);
                setState(() {});
              },
              tooltip: 'Acknowledge',
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedCategory == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedCategory = key),
      selectedColor: AppColors.tealLight,
      backgroundColor: AppColors.surface,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? AppColors.tealDark : AppColors.inkSoft,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? AppColors.teal : AppColors.borderLight,
        ),
      ),
    );
  }

  Widget _buildReminderItem(CaregiverReminder reminder) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  reminder.enabled ? AppColors.tealPale : AppColors.softSection,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              reminder.type == 'medication'
                  ? Icons.medication_rounded
                  : reminder.type == 'appointment'
                      ? Icons.calendar_month_rounded
                      : reminder.type == 'hydration'
                          ? Icons.water_drop_rounded
                          : Icons.alarm_rounded,
              color: reminder.enabled ? AppColors.tealDark : AppColors.muted,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: reminder.enabled ? AppColors.ink : AppColors.muted,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  ' •  • ',
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Switch(
            value: reminder.enabled,
            activeThumbColor: AppColors.teal,
            onChanged: (val) async {
              await CaregiverService.instance.toggleReminder(reminder.id);
              setState(() {});
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                size: 18, color: AppColors.muted),
            onSelected: (action) async {
              if (action == 'delete') {
                await CaregiverService.instance.deleteReminder(reminder.id);
                setState(() {});
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  context.tr('caregiver.deleteReminder',
                      defaultText: 'Delete Reminder'),
                  style: const TextStyle(color: AppColors.coralDeep),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openAddReminderDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final timeCtrl = TextEditingController(text: '10:00 AM');
    final noteCtrl = TextEditingController();
    String type = 'medication';
    String repeat = 'daily';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            context.tr('reminders.addReminder', defaultText: 'Add Reminder'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: context.tr('reminders.title',
                        defaultText: 'Title / Medication Name'),
                    hintText: 'e.g. Afternoon Medicine',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    DropdownMenuItem(
                        value: 'medication',
                        child: Text(context.tr('reminders.morningMedicine',
                            defaultText: 'Medicine'))),
                    DropdownMenuItem(
                        value: 'appointment',
                        child: Text(context.tr('reminders.appointment',
                            defaultText: 'Doctor Appointment'))),
                    DropdownMenuItem(
                        value: 'daily_routine',
                        child: Text(context.tr('reminders.routine',
                            defaultText: 'Daily Routine'))),
                    DropdownMenuItem(
                        value: 'hydration',
                        child: Text(context.tr('reminders.hydration',
                            defaultText: 'Hydration'))),
                    DropdownMenuItem(
                        value: 'cognitive_activity',
                        child: Text(context.tr('reminders.activity',
                            defaultText: 'Cognitive Exercise'))),
                  ],
                  onChanged: (v) => setDlgState(() => type = v ?? 'medication'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: timeCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Time (e.g. 02:30 PM)'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: repeat,
                  decoration:
                      const InputDecoration(labelText: 'Repeat Interval'),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Daily')),
                    DropdownMenuItem(
                        value: 'weekdays', child: Text('Weekdays')),
                    DropdownMenuItem(
                        value: 'weekends', child: Text('Weekends')),
                    DropdownMenuItem(value: 'once', child: Text('Once Only')),
                  ],
                  onChanged: (v) => setDlgState(() => repeat = v ?? 'daily'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Instructions / Dosage',
                      hintText: 'e.g. Take with warm water'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr('common.cancel', defaultText: 'Cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final newRem = CaregiverReminder(
                  id: 'rem-',
                  patientId: CaregiverService.instance.selectedPatientId,
                  type: type,
                  title: titleCtrl.text.trim(),
                  message: noteCtrl.text.trim(),
                  scheduledTime: timeCtrl.text.trim(),
                  repeat: repeat,
                  enabled: true,
                  status: 'upcoming',
                );
                await CaregiverService.instance.addReminder(newRem);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  setState(() {});
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
              child: Text(
                context.tr('caregiver.saveReminder',
                    defaultText: 'Save Reminder'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
