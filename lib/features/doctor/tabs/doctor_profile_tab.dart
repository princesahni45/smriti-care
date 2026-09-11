// lib/features/doctor/tabs/doctor_profile_tab.dart
//
// Doctor Profile & Clinical Portal Settings Tab.
// Displays physician credentials, verification disclaimer, offline status, and sign out.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/caregiver_auth_service.dart';
import '../services/doctor_service.dart';

class DoctorProfileTab extends StatelessWidget {
  const DoctorProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final doctor = DoctorService.instance.doctorProfile;
    final doctorName = DoctorService.instance.currentDoctorName;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Doctor Identity Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.tealLight,
                  child: Text(
                    doctorName.replaceAll('Dr. ', '').split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.tealDark,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctorName.startsWith('Dr.') ? doctorName : 'Dr. $doctorName',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doctor.specialization,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.tealDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doctor.hospitalOrClinic,
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
          ),
          const SizedBox(height: 18),

          // ── Verification Disclaimer Alert
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFB300)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFFF57F17), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Credential Verification Notice',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF57F17),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        doctor.verificationDisclaimer,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF424242),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Practitioner Credentials
          const Text(
            'Physician Credentials',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                _buildInfoRow('Doctor ID', doctor.doctorId, Icons.badge_rounded),
                const Divider(height: 18, color: AppColors.cardBorder),
                _buildInfoRow('Registration No.', doctor.registrationNumber, Icons.verified_user_rounded),
                const Divider(height: 18, color: AppColors.cardBorder),
                _buildInfoRow('Email Address', doctor.email, Icons.email_rounded),
                const Divider(height: 18, color: AppColors.cardBorder),
                _buildInfoRow('Phone', doctor.phone, Icons.phone_rounded),
                const Divider(height: 18, color: AppColors.cardBorder),
                _buildInfoRow('Hospital / Clinic', doctor.hospitalOrClinic, Icons.apartment_rounded),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Offline & Privacy Status
          const Text(
            'Security & Offline Status',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cloud_done_rounded, color: Color(0xFF2E7D32), size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Offline-First Local Cache',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            'Clinical logs & patient summaries stored encrypted on device.',
                            style: TextStyle(fontSize: 11, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20, color: AppColors.cardBorder),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_rounded, color: AppColors.teal, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Zero Patient Cross-Contamination',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            'Only caregivers can grant access via unique patient link codes.',
                            style: TextStyle(fontSize: 11, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Sign Out / Exit Doctor Mode Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Exit Doctor Mode?'),
                    content: const Text(
                      'You will be returned to the SmritiCare Patient Interface. You will need your medical credentials to sign back in.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Exit Doctor Mode', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await CaregiverAuthService.instance.exitDoctorMode();
                  if (context.mounted) {
                    context.go('/dashboard');
                  }
                }
              },
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFC62828)),
              label: const Text(
                'Exit Doctor Mode',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFC62828),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFFCDD2)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.muted),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}
