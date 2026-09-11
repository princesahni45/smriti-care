// lib/features/doctor/widgets/doctor_patient_card.dart
//
// Patient Card displayed in Doctor Dashboard & My Patients tab.
// Shows patient details, cognitive score, trend indicator, and MRI status.

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/caregiver_models.dart';
import '../models/doctor_models.dart';
import 'patient_attention_badge.dart';

class DoctorPatientCard extends StatelessWidget {
  final PatientProfile patient;
  final int? latestScore;
  final double? trendPercent;
  final DateTime? lastAssessedAt;
  final String mriStatus; // 'Review Pending', 'Reviewed', 'No MRI'
  final PatientAttentionStatus attentionStatus;
  final VoidCallback onViewPatient;

  const DoctorPatientCard({
    super.key,
    required this.patient,
    this.latestScore,
    this.trendPercent,
    this.lastAssessedAt,
    required this.mriStatus,
    required this.attentionStatus,
    required this.onViewPatient,
  });

  @override
  Widget build(BuildContext context) {
    // Format last test relative text
    String lastTestText = 'No tests yet';
    if (lastAssessedAt != null) {
      final diff = DateTime.now().difference(lastAssessedAt!);
      if (diff.inDays == 0) {
        lastTestText = 'Today';
      } else if (diff.inDays == 1) {
        lastTestText = 'Yesterday';
      } else {
        lastTestText = '${diff.inDays} days ago';
      }
    }

    // Trend indicator color & text
    Color trendColor = AppColors.muted;
    String trendText = 'Stable';
    IconData trendIcon = Icons.remove_rounded;

    if (trendPercent != null) {
      if (trendPercent! > 0) {
        trendColor = const Color(0xFF2E7D32);
        trendText = '↑ +${trendPercent!.toStringAsFixed(0)}%';
        trendIcon = Icons.trending_up_rounded;
      } else if (trendPercent! < 0) {
        trendColor = const Color(0xFFC62828);
        trendText = '↓ ${trendPercent!.abs().toStringAsFixed(0)}%';
        trendIcon = Icons.trending_down_rounded;
      }
    }

    // MRI badge color
    Color mriBadgeColor = Colors.grey.shade600;
    Color mriBadgeBg = Colors.grey.shade100;
    if (mriStatus == 'Review Pending') {
      mriBadgeColor = const Color(0xFFE65100);
      mriBadgeBg = const Color(0xFFFFF3E0);
    } else if (mriStatus == 'Reviewed') {
      mriBadgeColor = const Color(0xFF2E7D32);
      mriBadgeBg = const Color(0xFFE8F5E9);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onViewPatient,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Avatar, Name, Age, Attention Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.tealLight,
                      child: Text(
                        patient.avatarInitials,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.tealDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  patient.fullName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              PatientAttentionBadge(status: attentionStatus),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Age: ${patient.age} • ${patient.location} • ID: ${patient.id}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
                const SizedBox(height: 12),

                // Metrics row: Cognitive Score, Trend, Last Test, MRI Status
                Row(
                  children: [
                    // Cognitive Score
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cognitive Score',
                            style: TextStyle(fontSize: 11, color: AppColors.muted),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            latestScore != null ? '$latestScore / 100' : '—',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Trend
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Trend',
                            style: TextStyle(fontSize: 11, color: AppColors.muted),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(trendIcon, size: 14, color: trendColor),
                              const SizedBox(width: 2),
                              Text(
                                trendText,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: trendColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Last Test
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Last Test',
                            style: TextStyle(fontSize: 11, color: AppColors.muted),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lastTestText,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Bottom row: MRI badge & View Patient button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: mriBadgeBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: mriBadgeColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.biotech_rounded, size: 14, color: mriBadgeColor),
                          const SizedBox(width: 4),
                          Text(
                            'MRI: $mriStatus',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: mriBadgeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Row(
                      children: [
                        Text(
                          'View Patient',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.tealDark,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: AppColors.tealDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
