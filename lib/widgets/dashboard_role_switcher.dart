// lib/widgets/dashboard_role_switcher.dart
//
// Reusable role switcher widget displayed in top-right headers.
// Displays:
//   [ 👤 Patient ▼ ]   in Patient Mode
//   [ 👥 Caregiver ▼ ] in Caregiver Mode
// Accompanied by the multilingual language switcher [ 🌐 EN ].

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../core/services/caregiver_auth_service.dart';

class DashboardRoleSwitcher extends StatelessWidget {
  final VoidCallback? onSwitchToPatient;
  final VoidCallback? onSwitchToCaregiver;
  final VoidCallback? onSwitchToDoctor;

  const DashboardRoleSwitcher({
    super.key,
    this.onSwitchToPatient,
    this.onSwitchToCaregiver,
    this.onSwitchToDoctor,
  });

  void _showRoleSelectionSheet(BuildContext context) {
    final authService = CaregiverAuthService.instance;
    final currentMode = authService.currentMode;
    final isPatient = currentMode == DashboardMode.patient;
    final isCaregiver = currentMode == DashboardMode.caregiver;
    final isDoctor = currentMode == DashboardMode.doctor;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Dashboard View',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.close_rounded, color: AppColors.muted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Option 1: Patient Mode ─────────────────────────────────
              _buildRoleOption(
                context: ctx,
                title: '👤 Patient',
                subtitle: 'Elder-friendly interface • No password required',
                isSelected: isPatient,
                color: AppColors.teal,
                onTap: () {
                  Navigator.pop(ctx);
                  if (!isPatient) {
                    authService.switchToPatientMode();
                    if (onSwitchToPatient != null) {
                      onSwitchToPatient!();
                    } else {
                      context.go('/dashboard');
                    }
                  }
                },
              ),
              const SizedBox(height: 10),

              // ── Option 2: Caregiver Mode ───────────────────────────────
              _buildRoleOption(
                context: ctx,
                title: '👥 Caregiver',
                subtitle: 'Protected portal • Verification required',
                isSelected: isCaregiver,
                color: AppColors.violetDeep,
                onTap: () {
                  Navigator.pop(ctx);
                  if (!isCaregiver) {
                    if (authService.switchToCaregiverModeIfAuthenticated()) {
                      if (onSwitchToCaregiver != null) {
                        onSwitchToCaregiver!();
                      } else {
                        context.go('/caregiver');
                      }
                    } else {
                      context.push('/caregiver-login');
                    }
                  }
                },
              ),
              const SizedBox(height: 10),

              // ── Option 3: Doctor Mode ──────────────────────────────────
              // FIX: Added doctor role support - doctor option in role switcher
              _buildRoleOption(
                context: ctx,
                title: '🩺 Doctor',
                subtitle:
                    'Clinical portal • Multi-patient cognitive & MRI monitoring',
                isSelected: isDoctor,
                color: const Color(0xFF00796B),
                onTap: () {
                  Navigator.pop(ctx);
                  if (!isDoctor) {
                    if (authService.switchToDoctorModeIfAuthenticated()) {
                      if (onSwitchToDoctor != null) {
                        onSwitchToDoctor!();
                      } else {
                        context.go('/doctor');
                      }
                    } else {
                      context.push('/doctor-login');
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.08)
              : AppColors.softSection,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? color : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 22)
            else
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: AppColors.muted, size: 14),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CaregiverAuthService.instance,
      builder: (context, _) {
        final mode = CaregiverAuthService.instance.currentMode;
        final isPatient = mode == DashboardMode.patient;
        final isDoctor = mode == DashboardMode.doctor;

        final String label;
        final Color bg;
        final Color borderColor;
        final Color textColor;

        if (isDoctor) {
          label = '🩺 Doctor';
          bg = const Color(0xFFE0F2F1);
          borderColor = const Color(0xFF80CBC4);
          textColor = const Color(0xFF00695C);
        } else if (!isPatient) {
          label = '👥 Caregiver';
          bg = AppColors.violetLight;
          borderColor = AppColors.violetBorder;
          textColor = AppColors.violetDeep;
        } else {
          label = '👤 Patient';
          bg = AppColors.softSection;
          borderColor = AppColors.borderLight;
          textColor = AppColors.ink;
        }

        return InkWell(
          onTap: () => _showRoleSelectionSheet(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 18,
                  color: textColor,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
