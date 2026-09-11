// lib/features/doctor/widgets/patient_attention_badge.dart
//
// Clean clinical badge representing deterministic attention status.
// Transparent, non-diagnostic: "Review Suggested", "Monitor", "Stable", "Insufficient Data".

import 'package:flutter/material.dart';
import '../models/doctor_models.dart';

class PatientAttentionBadge extends StatelessWidget {
  final PatientAttentionStatus status;
  final bool showReason;

  const PatientAttentionBadge({
    super.key,
    required this.status,
    this.showReason = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: status.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: status.color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(status.icon, size: 14, color: status.color),
              const SizedBox(width: 6),
              Text(
                status.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: status.color,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        if (showReason && status.reason.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            status.reason,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}
