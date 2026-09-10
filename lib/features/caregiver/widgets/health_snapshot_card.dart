// lib/features/caregiver/widgets/health_snapshot_card.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/caregiver_models.dart';

class HealthSnapshotCard extends StatelessWidget {
  final PatientProfile patient;
  final EmergencyContact emergencyContact;

  const HealthSnapshotCard({
    super.key,
    required this.patient,
    required this.emergencyContact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'HEALTH SNAPSHOT',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.tealDark, letterSpacing: 0.8),
              ),
              Icon(Icons.health_and_safety_outlined, size: 20, color: AppColors.teal),
            ],
          ),
          const SizedBox(height: 12),
          _buildRow('Blood group', patient.bloodGroup),
          _buildRow('Primary language', patient.primaryLanguage),
          _buildRow('Emergency contact', ' ()'),
          _buildRow('Care physician', patient.physician),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
        ],
      ),
    );
  }
}

class CareInsightCard extends StatelessWidget {
  const CareInsightCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome_rounded, size: 18, color: AppColors.violetDeep),
              SizedBox(width: 8),
              Text(
                "Today's care note",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Ramesh showed strong recognition during the family-photo activity and responded well to voice prompts.',
            style: TextStyle(fontSize: 14, color: AppColors.inkSoft, height: 1.45),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.coralPale,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.favorite_rounded, size: 14, color: AppColors.coralDeep),
                    SizedBox(width: 6),
                    Text('Mood: Calm & engaged', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.coralDeep)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
