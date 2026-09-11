// lib/features/games/game_result_screen.dart
//
// Elderly-friendly, celebratory Cognitive Game Result Screen.
// Fulfills Step 12:
// - Big readable score & accuracy
// - Metric breakdown (Correct, Time, Difficulty)
// - Offline adaptive difficulty recommendation
// - Action buttons: Play Again, Back to Games, View Progress / Dashboard

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/game_result.dart';

class GameResultScreen extends StatelessWidget {
  final GameResult result;
  final VoidCallback onPlayAgain;
  final VoidCallback? onBackToGames;

  const GameResultScreen({
    super.key,
    required this.result,
    required this.onPlayAgain,
    this.onBackToGames,
  });

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight, width: 1.4),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              size: 28, color: AppColors.ink),
          onPressed: onBackToGames ?? () => context.go('/games'),
        ),
        title: Text(
          result.gameName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Celebratory bubble
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.tealPale,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Text('🎉', style: TextStyle(fontSize: 44)),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                'Activity Complete!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Wonderful effort! Every gentle activity strengthens everyday recall.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),

              // Main Score Highlight Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.tealLight, AppColors.surface],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border, width: 1.8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Cognitive Activity Score',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tealDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${result.score}%',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: AppColors.tealDeep,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Accuracy: ${result.accuracy}%',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3 Metric Breakdown Cards
              Row(
                children: [
                  _buildMetricCard(
                    label: 'Answers',
                    value:
                        '${result.correctAnswers} / ${result.attempts > 0 ? result.attempts : result.correctAnswers}',
                    icon: Icons.check_circle_rounded,
                    color: AppColors.teal,
                    bgColor: AppColors.tealPale,
                  ),
                  const SizedBox(width: 10),
                  _buildMetricCard(
                    label: 'Difficulty',
                    value: result.difficulty,
                    icon: Icons.speed_rounded,
                    color: AppColors.amber,
                    bgColor: AppColors.amberPale,
                  ),
                  const SizedBox(width: 10),
                  _buildMetricCard(
                    label: 'Time Taken',
                    value: _formatTime(result.completionTimeSeconds),
                    icon: Icons.timer_rounded,
                    color: AppColors.blue,
                    bgColor: AppColors.bluePale,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Adaptive Recommendation Card (Step 13)
              if (result.recommendation.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.violetPale,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.violet.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.violetDeep,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          result.recommendation,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.violetDeep,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 28),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 24),
                  label: const Text(
                    'Play Again',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  onPressed: onPlayAgain,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.grid_view_rounded,
                      size: 22, color: AppColors.ink),
                  label: const Text(
                    'Back to Games',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink),
                  ),
                  onPressed: onBackToGames ?? () => context.go('/games'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text(
                  'Back to Dashboard',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
