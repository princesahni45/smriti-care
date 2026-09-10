// lib/widgets/dashboard_header.dart
//
// Accessible, high-contrast header for SmritiCare.
// Features:
// - App brand badge
// - Time-based friendly greeting ("Good Morning 👋")
// - Formatted local date
// - Patient profile card with caregiver connection indicator

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../core/localization/app_localizations.dart';
import 'dashboard_role_switcher.dart';

class DashboardHeader extends StatelessWidget {
  final VoidCallback? onProfileTap;

  const DashboardHeader({super.key, this.onProfileTap});

  /// Dynamic time-of-day greeting with multilingual support
  String _getGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return '${context.tr('patient.greetingMorning', defaultText: 'Good Morning')} 👋';
    }
    if (hour >= 12 && hour < 17) {
      return '${context.tr('patient.greetingAfternoon', defaultText: 'Good Afternoon')} ☀️';
    }
    if (hour >= 17 && hour < 21) {
      return '${context.tr('patient.greetingEvening', defaultText: 'Good Evening')} 🌇';
    }
    return '${context.tr('patient.greetingNight', defaultText: 'Good Night')} 🌙';
  }

  /// Formatted date matching SmritiCare design with localization
  String _formattedDate(BuildContext context) {
    final now = DateTime.now();
    const weekdayKeys = [
      'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
    ];
    const monthKeys = [
      'january', 'february', 'march', 'april', 'may', 'june',
      'july', 'august', 'september', 'october', 'november', 'december'
    ];
    final weekdayName = context.tr('dates.${weekdayKeys[now.weekday - 1]}');
    final monthName = context.tr('dates.${monthKeys[now.month - 1]}');
    return '$weekdayName, $monthName ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        border: const Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.tealDeep.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Brand Bar & Date ────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Brand badge
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.tealLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.teal.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.psychology_rounded,
                          color: AppColors.teal,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SmritiCare',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            context.tr('landing.footerTagline', defaultText: 'Cognitive Companion'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.tealDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Right Action Buttons (Role Switcher & Language selector)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Role Switcher Pill [ 👤 Patient ▼ ] / [ 👥 Caregiver ▼ ]
                  const DashboardRoleSwitcher(),
                  const SizedBox(width: 6),

                  // Language Switcher Pill Button [ 🌐 EN ]
                  InkWell(
                    onTap: () => context.push('/language-select'),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.softSection,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.language_rounded, size: 16, color: AppColors.teal),
                          const SizedBox(width: 4),
                          ValueListenableBuilder<Locale>(
                            valueListenable:
                                LocalizationService.instance.currentLocaleNotifier,
                            builder: (context, loc, _) {
                              return Text(
                                loc.languageCode.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Friendly Greeting & Date ────────────────────────────────
          Text(
            _getGreeting(context),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formattedDate(context),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),

          const SizedBox(height: 16),

          // ── Patient Profile Pill ────────────────────────────────────
          InkWell(
            onTap: onProfileTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1.2),
              ),
              child: Row(
                children: [
                  // Patient Avatar
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.teal,
                    child: Text(
                      'R',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Patient info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          AppConstants.patientFullName,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.verified_user_rounded,
                              size: 14,
                              color: AppColors.teal,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${context.tr('caregiver.role', defaultText: 'Caregiver')}: ${AppConstants.caregiverName}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.tealDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Subtle indicator
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
