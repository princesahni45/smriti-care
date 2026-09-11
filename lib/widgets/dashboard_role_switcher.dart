```dart
// lib/widgets/dashboard_role_switcher.dart
//
// Reusable role switcher widget displayed in top-right headers.
//
// Supported modes:
// - Patient
// - Caregiver
// - Doctor

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/services/caregiver_auth_service.dart';
import '../core/theme/app_theme.dart';

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

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Select Dashboard View',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.muted,
                      ),
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                _buildRoleOption(
                  context: sheetContext,
                  title: 'Patient',
                  subtitle:
                      'Elder-friendly interface. No password required.',
                  isSelected: isPatient,
                  color: AppColors.teal,
                  icon: Icons.person_outline_rounded,
                  onTap: () {
                    Navigator.of(sheetContext).pop();

                    if (isPatient) return;

                    authService.switchToPatientMode();

                    if (onSwitchToPatient != null) {
                      onSwitchToPatient!();
                    } else {
                      context.go('/dashboard');
                    }
                  },
                ),

                const SizedBox(height: 10),

                _buildRoleOption(
                  context: sheetContext,
                  title: 'Caregiver',
                  subtitle:
                      'Protected portal. Verification required.',
                  isSelected: isCaregiver,
                  color: AppColors.violetDeep,
                  icon: Icons.groups_outlined,
                  onTap: () {
                    Navigator.of(sheetContext).pop();

                    if (isCaregiver) return;

                    if (authService
                        .switchToCaregiverModeIfAuthenticated()) {
                      if (onSwitchToCaregiver != null) {
                        onSwitchToCaregiver!();
                      } else {
                        context.go('/caregiver');
                      }
                    } else {
                      context.push('/caregiver-login');
                    }
                  },
                ),

                const SizedBox(height: 10),

                _buildRoleOption(
                  context: sheetContext,
                  title: 'Doctor',
                  subtitle:
                      'Clinical portal. Patient and MRI monitoring.',
                  isSelected: isDoctor,
                  color: const Color(0xFF00695C),
                  icon: Icons.medical_services_outlined,
                  onTap: () {
                    Navigator.of(sheetContext).pop();

                    if (isDoctor) return;

                    if (authService
                        .switchToDoctorModeIfAuthenticated()) {
                      if (onSwitchToDoctor != null) {
                        onSwitchToDoctor!();
                      } else {
                        context.go('/doctor');
                      }
                    } else {
                      context.push('/doctor-login');
                    }
                  },
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool isSelected,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.08)
              : AppColors.softSection,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color
                : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? color
                          : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: color,
                size: 22,
              )
            else
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.muted,
                size: 14,
              ),
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
        final Color backgroundColor;
        final Color borderColor;
        final Color textColor;
        final IconData icon;

        if (isDoctor) {
          label = 'Doctor';
          backgroundColor = const Color(0xFFE0F2F1);
          borderColor = const Color(0xFF80CBC4);
          textColor = const Color(0xFF00695C);
          icon = Icons.medical_services_outlined;
        } else if (!isPatient) {
          label = 'Caregiver';
          backgroundColor = AppColors.violetLight;
          borderColor = AppColors.violetBorder;
          textColor = AppColors.violetDeep;
          icon = Icons.groups_outlined;
        } else {
          label = 'Patient';
          backgroundColor = AppColors.softSection;
          borderColor = AppColors.borderLight;
          textColor = AppColors.ink;
          icon = Icons.person_outline_rounded;
        }

        return InkWell(
          onTap: () {
            _showRoleSelectionSheet(context);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 36,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: textColor,
                ),
                const SizedBox(width: 5),
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
```
