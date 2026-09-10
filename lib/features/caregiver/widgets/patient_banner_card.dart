// lib/features/caregiver/widgets/patient_banner_card.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/caregiver_models.dart';

class PatientBannerCard extends StatelessWidget {
  final PatientProfile patient;
  final VoidCallback? onViewProfile;

  const PatientBannerCard({
    super.key,
    required this.patient,
    this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  patient.avatarInitials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR PATIENT',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.muted,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ' •  yrs',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: AppColors.muted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            ' • ID: ',
                            style: const TextStyle(fontSize: 12, color: AppColors.muted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.amberPale,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_outlined, size: 14, color: AppColors.amberDeep),
                    const SizedBox(width: 6),
                    Text(
                      ' Dementia (Needs regular support)',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.amberDeep,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Icon(Icons.check_circle_rounded, size: 14, color: AppColors.teal),
              SizedBox(width: 6),
              Text(
                'Live local sync • Last updated today, 9:42 AM',
                style: TextStyle(fontSize: 12, color: AppColors.tealDark, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
