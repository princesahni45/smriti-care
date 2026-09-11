// lib/widgets/progress_summary_card.dart
//
// Accessible, high-contrast cognitive progress summary for the dashboard.
// Displays:
// - Memory: 75%
// - Attention: 60%
// - Pattern: 80%

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class ProgressSummaryCard extends StatelessWidget {
  final int memoryScore;
  final int attentionScore;
  final int patternScore;
  final VoidCallback onTap;

  const ProgressSummaryCard({
    super.key,
    this.memoryScore = 75,
    this.attentionScore = 60,
    this.patternScore = 80,
    required this.onTap,
  });

  Widget _buildProgressRow({
    required String title,
    required int percentage,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage / 100.0,
            minHeight: 12,
            backgroundColor: AppColors.borderLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Icon(Icons.trending_up_rounded,
                  size: 20, color: AppColors.violet),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your Progress',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.borderLight, width: 1.6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProgressRow(
                    title: 'Memory',
                    percentage: memoryScore,
                    icon: Icons.psychology_rounded,
                    color: AppColors.teal,
                  ),
                  const SizedBox(height: 18),
                  _buildProgressRow(
                    title: 'Attention',
                    percentage: attentionScore,
                    icon: Icons.center_focus_strong_rounded,
                    color: AppColors.blue,
                  ),
                  const SizedBox(height: 18),
                  _buildProgressRow(
                    title: 'Pattern',
                    percentage: patternScore,
                    icon: Icons.grid_view_rounded,
                    color: AppColors.violet,
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.borderLight),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Weekly cognitive summary',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8),
                      Row(
                        children: [
                          Text(
                            'View Details',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.violet,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: AppColors.violet,
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
      ],
    );
  }
}
