// lib/features/caregiver/widgets/caregiver_header_bar.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/models/caregiver_models.dart';
import '../../../core/services/caregiver_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../widgets/dashboard_role_switcher.dart';

class CaregiverHeaderBar extends StatelessWidget {
  final CaregiverProfile profile;
  final VoidCallback onSwitchToPatient;

  const CaregiverHeaderBar({
    super.key,
    required this.profile,
    required this.onSwitchToPatient,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 400;
        final isUltraNarrow = constraints.maxWidth < 340;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isUltraNarrow
                ? 8
                : isNarrow
                    ? 10
                    : 16,
            vertical: isNarrow ? 8 : 12,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: const Border(
              bottom: BorderSide(
                color: AppColors.borderLight,
                width: 1.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        flex: 3,
                        child: AppLogo(
                          fontSize: isNarrow ? 15 : 18,
                          iconSize: isNarrow ? 20 : 26,
                        ),
                      ),
                      SizedBox(width: isNarrow ? 4 : 8),
                      Flexible(
                        flex: 2,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isNarrow ? 6 : 8,
                            vertical: isNarrow ? 2 : 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.tealPale,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            context.tr(
                              'caregiver.portal',
                              defaultText: 'Caregiver portal',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isNarrow ? 10 : 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.tealDark,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isNarrow ? 4 : 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DashboardRoleSwitcher(
                      onSwitchToPatient: onSwitchToPatient,
                    ),
                    SizedBox(width: isNarrow ? 4 : 8),
                    _buildNotificationButton(
                      context,
                      isNarrow: isNarrow,
                    ),
                    SizedBox(width: isNarrow ? 4 : 8),
                    _buildLanguageButton(
                      context,
                      isNarrow: isNarrow,
                    ),
                    SizedBox(width: isNarrow ? 4 : 8),
                    _buildProfileAvatar(isNarrow: isNarrow),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileAvatar({required bool isNarrow}) {
    final size = isNarrow ? 34.0 : 38.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.teal,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        profile.initials,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: isNarrow ? 11 : 13,
        ),
      ),
    );
  }

  Widget _buildNotificationButton(
    BuildContext context, {
    required bool isNarrow,
  }) {
    final alerts = CaregiverService.instance.getAlerts();
    final size = isNarrow ? 34.0 : 38.0;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          builder: (ctx) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Caregiver Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (alerts.isEmpty)
                      const Text(
                        'No new notifications.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.inkSoft,
                        ),
                      )
                    else
                      ...alerts.take(3).map(
                            (alert) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 5),
                                    child: Icon(
                                      Icons.circle,
                                      size: 8,
                                      color: AppColors.coral,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${alert.title} - ${alert.message}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            );
          },
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.softSection,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.notifications_outlined,
              size: isNarrow ? 18 : 20,
              color: AppColors.inkSoft,
            ),
            Positioned(
              right: isNarrow ? 6 : 8,
              top: isNarrow ? 6 : 8,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.coral,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageButton(
    BuildContext context, {
    required bool isNarrow,
  }) {
    return InkWell(
      onTap: () => context.push('/language-select'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isNarrow ? 6 : 8,
          vertical: isNarrow ? 4 : 5,
        ),
        decoration: BoxDecoration(
          color: AppColors.softSection,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language_rounded,
              size: isNarrow ? 13 : 15,
              color: AppColors.teal,
            ),
            const SizedBox(width: 3),
            ValueListenableBuilder<Locale>(
              valueListenable:
                  LocalizationService.instance.currentLocaleNotifier,
              builder: (context, locale, _) {
                return Text(
                  locale.languageCode.toUpperCase(),
                  style: TextStyle(
                    fontSize: isNarrow ? 10 : 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
