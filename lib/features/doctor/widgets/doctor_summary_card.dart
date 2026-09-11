// lib/features/doctor/widgets/doctor_summary_card.dart
//
// Metric cards for Doctor Dashboard summary row.
// Displays key metrics with clinical styling and responsive layout.

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class DoctorSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const DoctorSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
