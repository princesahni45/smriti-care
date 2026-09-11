// lib/features/caregiver/widgets/emergency_safety_section.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/caregiver_models.dart';
import '../../../core/services/caregiver_service.dart';

class EmergencySafetySection extends StatefulWidget {
  const EmergencySafetySection({super.key});

  @override
  State<EmergencySafetySection> createState() => _EmergencySafetySectionState();
}

class _EmergencySafetySectionState extends State<EmergencySafetySection> {
  @override
  Widget build(BuildContext context) {
    final contact = CaregiverService.instance.getEmergencyContact();
    final home = CaregiverService.instance.getHomeLocation();
    final config = CaregiverService.instance.getEmergencyConfig();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Emergency & Safety Settings',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        const SizedBox(height: 6),
        const Text(
          "Used by the patient's Safe Return compass and SOS emergency button. Stored 100% offline.",
          style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 16),

        // Primary Caregiver Contact Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight, width: 1.5),
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
                            color: AppColors.tealPale,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.phone_in_talk_rounded,
                            color: AppColors.teal, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Primary Caregiver Contact',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.ink),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 20, color: AppColors.teal),
                    onPressed: () => _openEditContactDialog(context, contact),
                    tooltip: 'Edit Contact',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('${contact.name} (${contact.relationship})',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('Primary: ${contact.phone}',
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
              if (contact.secondaryPhone.isNotEmpty)
                Text('Secondary: ${contact.secondaryPhone}',
                    style:
                        const TextStyle(fontSize: 13, color: AppColors.muted)),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Safe Home Location Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight, width: 1.5),
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
                            color: AppColors.amberPale,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.home_work_rounded,
                            color: AppColors.amberDeep, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Safe Home Location',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.ink),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 20, color: AppColors.amberDeep),
                    onPressed: () => _openEditHomeDialog(context, home),
                    tooltip: 'Edit Location',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(home.address,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Coordinates: ${home.latitude}° N, ${home.longitude}° E',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Emergency Services Card (112)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.coralPale,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.coral.withValues(alpha: 0.35), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppColors.coral,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.emergency_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Hotline: ${config.emergencyNumber}',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.coralDeep),
                    ),
                    Text(
                      '${config.label} (${config.country})',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.coralDeep),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openEditContactDialog(BuildContext context, EmergencyContact cur) {
    final nameCtrl = TextEditingController(text: cur.name);
    final relCtrl = TextEditingController(text: cur.relationship);
    final phoneCtrl = TextEditingController(text: cur.phone);
    final secCtrl = TextEditingController(text: cur.secondaryPhone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Edit Caregiver Contact'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name')),
              TextField(
                  controller: relCtrl,
                  decoration: const InputDecoration(labelText: 'Relationship')),
              TextField(
                  controller: phoneCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Primary Phone')),
              TextField(
                  controller: secCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Secondary Phone')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
            onPressed: () async {
              final updated = EmergencyContact(
                name: nameCtrl.text.trim(),
                relationship: relCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                secondaryPhone: secCtrl.text.trim(),
                updatedAt: DateTime.now(),
              );
              await CaregiverService.instance.saveEmergencyContact(updated);
              if (context.mounted) {
                Navigator.pop(ctx);
                setState(() {});
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openEditHomeDialog(BuildContext context, HomeLocation cur) {
    final addrCtrl = TextEditingController(text: cur.address);
    final latCtrl = TextEditingController(text: cur.latitude.toString());
    final lngCtrl = TextEditingController(text: cur.longitude.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Edit Safe Home Location'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: addrCtrl,
                  decoration: const InputDecoration(labelText: 'Home Address')),
              TextField(
                  controller: latCtrl,
                  decoration: const InputDecoration(labelText: 'Latitude')),
              TextField(
                  controller: lngCtrl,
                  decoration: const InputDecoration(labelText: 'Longitude')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.amberDeep),
            onPressed: () async {
              final updated = HomeLocation(
                address: addrCtrl.text.trim(),
                latitude: double.tryParse(latCtrl.text) ?? 26.1856,
                longitude: double.tryParse(lngCtrl.text) ?? 91.7539,
                updatedAt: DateTime.now(),
              );
              await CaregiverService.instance.saveHomeLocation(updated);
              if (context.mounted) {
                Navigator.pop(ctx);
                setState(() {});
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
