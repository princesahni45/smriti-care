// lib/features/patient/widgets/daily_steps_card.dart
//
// FIX: Added offline-first step tracking UI card for Patient Dashboard
// Displays today's steps, 10,000-step goal, visual progress bar, percentage,
// remaining steps, and goal completion state with zero RenderFlex overflow.

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/daily_step_record.dart';
import '../../../core/services/step_counter_service.dart';
import '../../../core/localization/app_localizations.dart';

class DailyStepsCard extends StatelessWidget {
  const DailyStepsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StepTrackingStatus>(
      valueListenable: StepCounterService.instance.statusNotifier,
      builder: (context, status, _) {
        return ValueListenableBuilder<DailyStepRecord>(
          valueListenable: StepCounterService.instance.recordNotifier,
          builder: (context, record, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: StepCounterService.instance.isWalkingNotifier,
              builder: (context, isWalking, _) {
                // FIX: Prevent RenderFlex overflow on narrow mobile screens
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: AppColors.borderLight, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.teal.withValues(alpha: 0.05),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Header Row: Icon + Title + Status Pill
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isWalking
                                          ? AppColors.tealPale
                                          : AppColors.softSection,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.directions_walk_rounded,
                                      color: isWalking
                                          ? AppColors.teal
                                          : AppColors.inkSoft,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.tr('patient.dailyActivity',
                                            defaultText: 'Daily Activity'),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      Text(
                                        context.tr('patient.todaysSteps',
                                            defaultText: "Today's Steps"),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.muted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              _buildStatusBadge(
                                  context, status, record.syncStatus),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // ── In case sensor is unsupported or permission required
                          if (status ==
                              StepTrackingStatus.permissionRequired) ...[
                            _buildPermissionNotice(context),
                          ] else if (status ==
                              StepTrackingStatus.unsupported) ...[
                            _buildUnsupportedNotice(context),
                          ] else ...[
                            // ── Live Steps Counter Display
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    _formatSteps(record.steps),
                                    style: const TextStyle(
                                      fontSize: 42,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.ink,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  Text(
                                    context
                                        .tr('patient.steps',
                                            defaultText: 'steps')
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.muted,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ── Goal info & percentage
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${context.tr('patient.goal', defaultText: 'Goal')}: ${_formatSteps(record.goal)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.inkSoft,
                                  ),
                                ),
                                Text(
                                  '${(record.progressPercentage * 100).toInt()}% ${context.tr('patient.completed', defaultText: 'completed')}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: record.isGoalCompleted
                                        ? AppColors.tealDark
                                        : AppColors.teal,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // ── Progress Bar (capped visually at 100%)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: record.progressPercentage,
                                minHeight: 12,
                                backgroundColor: AppColors.tealPale,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  record.isGoalCompleted
                                      ? const Color(0xFF2E7D32)
                                      : AppColors.teal,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // ── Completion Banner / Remaining Steps
                            if (record.isGoalCompleted) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: const Color(0xFFA5D6A7)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('🎉 ',
                                        style: TextStyle(fontSize: 16)),
                                    Flexible(
                                      child: Text(
                                        context.tr('patient.dailyGoalCompleted',
                                            defaultText:
                                                'Daily Goal Completed!'),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1B5E20),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              Text(
                                '${_formatSteps(record.remainingSteps)} ${context.tr('patient.stepsRemaining', defaultText: 'steps remaining')}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(
      BuildContext context, StepTrackingStatus status, String syncStatus) {
    if (status == StepTrackingStatus.loading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.tealPale,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sync_rounded,
              size: 12,
              color: AppColors.tealDark,
            ),
            SizedBox(width: 4),
            Text(
              'Connecting...',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.tealDark,
              ),
            ),
          ],
        ),
      );
    }

    if (status == StepTrackingStatus.permissionRequired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.coralPale,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Permission Needed',
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.coralDeep),
        ),
      );
    }

    if (status == StepTrackingStatus.unsupported) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.softSection,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Sensor N/A',
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.muted),
        ),
      );
    }

    final isSynced = syncStatus == 'synced';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSynced ? AppColors.tealPale : AppColors.softSection,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSynced ? Icons.cloud_done_rounded : Icons.offline_pin_rounded,
            size: 13,
            color: isSynced ? AppColors.tealDark : AppColors.muted,
          ),
          const SizedBox(width: 4),
          Text(
            isSynced
                ? context.tr('patient.synced', defaultText: 'Synced')
                : context.tr('patient.offlineSavedOnDevice',
                    defaultText: 'Saved Offline'),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isSynced ? AppColors.tealDark : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionNotice(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.coralPale.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            context.tr('patient.stepPermissionRequired',
                defaultText:
                    'SmritiCare needs physical activity access to count your daily steps.'),
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.inkSoft),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => StepCounterService.instance.retry(),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: Text(context.tr('patient.enableStepTracking',
                    defaultText: 'Grant Permission')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => StepCounterService.instance.openAppSettings(),
                icon: const Icon(Icons.settings_outlined, size: 16),
                label: const Text('Settings'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.teal,
                  side: const BorderSide(color: AppColors.teal),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnsupportedNotice(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.softSection,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.muted, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.tr('patient.stepTrackingUnsupported',
                  defaultText:
                      'Step tracking is not supported on this device sensor.'),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }

  String _formatSteps(int count) {
    return count.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
