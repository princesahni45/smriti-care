// lib/widgets/today_activity_section.dart
//
// Clean overview of today's cognitive activities for the patient.
// Displays:
// - Games Completed: 0
// - Current Streak: 0 days
// - Today's Score: 0

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class TodayActivitySection extends StatelessWidget {
  final int gamesCompleted;
  final int streakDays;
  final int todayScore;

  const TodayActivitySection({
    super.key,
    this.gamesCompleted = 0,
    this.streakDays = 0,
    this.todayScore = 0,
  });

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderLight, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Icon bubble
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ),
            const SizedBox(height: 10),

            // Big readable number
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),

            // Clear label
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
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
              Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.teal),
              SizedBox(width: 8),
              Text(
                "Today's Activity",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard(
              label: 'Games Completed',
              value: '$gamesCompleted',
              icon: Icons.videogame_asset_rounded,
              iconColor: AppColors.teal,
              bgColor: AppColors.tealPale,
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              label: 'Current Streak',
              value: '$streakDays days',
              icon: Icons.local_fire_department_rounded,
              iconColor: AppColors.coral,
              bgColor: AppColors.coralPale,
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              label: "Today's Score",
              value: '$todayScore',
              icon: Icons.stars_rounded,
              iconColor: AppColors.amber,
              bgColor: AppColors.amberPale,
            ),
          ],
        ),
      ],
    );
  }
}
