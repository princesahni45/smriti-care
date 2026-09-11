// lib/features/caregiver/widgets/reminder_management_section.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/caregiver_models.dart';
import '../../../core/services/caregiver_service.dart';

class ReminderManagementSection extends StatefulWidget {
  const ReminderManagementSection({super.key});

  @override
  State<ReminderManagementSection> createState() =>
      _ReminderManagementSectionState();
}

class _ReminderManagementSectionState extends State<ReminderManagementSection> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final reminders = CaregiverService.instance.getReminders();
    final filtered = reminders.where((r) {
      if (_selectedFilter == 'completed') return r.status == 'acknowledged';
      if (_selectedFilter == 'upcoming') return r.status == 'upcoming';
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Today's Reminders",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                elevation: 0,
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Reminder',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              onPressed: () => _openAddReminderDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _buildFilterChip('All ()', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip('Completed ()', 'completed'),
            const SizedBox(width: 8),
            _buildFilterChip('Upcoming ()', 'upcoming'),
          ],
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Center(
              child: Text(
                'No reminders in this category.',
                style: TextStyle(color: AppColors.muted, fontSize: 14),
              ),
            ),
          )
        else
          ...filtered.map((r) => _buildReminderItem(r)),
      ],
    );
  }

  Widget _buildFilterChip(String label, String key) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.teal : AppColors.softSection,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? AppColors.teal : AppColors.borderLight),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }

  Widget _buildReminderItem(CaregiverReminder r) {
    final isDone = r.status == 'acknowledged';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1.4),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDone ? AppColors.tealLight : AppColors.softSection,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDone ? Icons.check_circle_rounded : Icons.schedule_rounded,
              color: isDone ? AppColors.teal : AppColors.amberDeep,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color:
                            isDone ? AppColors.tealLight : AppColors.amberPale,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isDone ? 'Completed' : 'Upcoming',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color:
                              isDone ? AppColors.tealDark : AppColors.amberDeep,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  ' • ',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: r.enabled,
            activeThumbColor: AppColors.teal,
            onChanged: (val) async {
              await CaregiverService.instance.toggleReminder(r.id);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  void _openAddReminderDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final timeCtrl = TextEditingController(text: '03:00 PM');
    final noteCtrl = TextEditingController();
    String selectedType = 'medication';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Patient Reminder',
              style: TextStyle(fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Reminder Title',
                    hintText: 'e.g. Afternoon Medicine',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: timeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Time',
                    hintText: '03:00 PM',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                      labelText: 'Category', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(
                        value: 'medication', child: Text('💊 Medication')),
                    DropdownMenuItem(
                        value: 'hydration', child: Text('💧 Hydration')),
                    DropdownMenuItem(
                        value: 'cognitive_activity',
                        child: Text('🧠 Brain Activity')),
                    DropdownMenuItem(
                        value: 'appointment', child: Text('📅 Appointment')),
                    DropdownMenuItem(
                        value: 'daily_routine',
                        child: Text('🚶 Daily Routine')),
                  ],
                  onChanged: (v) =>
                      setDlgState(() => selectedType = v ?? 'medication'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Gentle Instructions',
                    hintText: 'Take with half glass of water',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final newRem = CaregiverReminder(
                  id: 'rem_',
                  patientId: 'MC-2048',
                  type: selectedType,
                  title: titleCtrl.text.trim(),
                  message: noteCtrl.text.trim(),
                  scheduledTime: timeCtrl.text.trim(),
                  repeat: 'daily',
                  enabled: true,
                  status: 'upcoming',
                );
                await CaregiverService.instance.addReminder(newRem);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  setState(() {});
                }
              },
              child: const Text('Save Reminder',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
