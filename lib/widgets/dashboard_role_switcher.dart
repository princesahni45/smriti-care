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

  const DashboardRoleSwitcher({
    super.key,
    this.onSwitchToPatient,
    this.onSwitchToCaregiver,
  });

  void _showRoleSelectionSheet(BuildContext context) {
    final authService = CaregiverAuthService.instance;
    final isPatient = authService.currentMode == DashboardMode.patient;

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
                isSelected: !isPatient,
                color: AppColors.violetDeep,
                onTap: () {
                  Navigator.pop(ctx);
                  if (isPatient) {
                    if (authService.switchToCaregiverModeIfAuthenticated()) {
                      // Session already active in this app run
                      if (onSwitchToCaregiver != null) {
                        onSwitchToCaregiver!();
                      } else {
                        context.go('/caregiver');
                      }
                    } else {
                      // Requires caregiver authentication
                      context.push('/caregiver-login');
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
        final isPatient =
            CaregiverAuthService.instance.currentMode == DashboardMode.patient;

        final label = isPatient ? '👤 Patient' : '👥 Caregiver';
        final bg = isPatient ? AppColors.softSection : AppColors.violetLight;
        final borderColor =
            isPatient ? AppColors.borderLight : AppColors.violetBorder;
        final textColor = isPatient ? AppColors.ink : AppColors.violetDeep;

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
