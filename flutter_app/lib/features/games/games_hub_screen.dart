// lib/features/games/games_hub_screen.dart
//
// Catalog of cognitive activities for elderly dementia patients.
// Ported faithfully from GamesHub.jsx in the React codebase.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/smriti_button.dart';

class GameCatalogItem {
  final String id;
  final IconData icon;
  final String color;
  final String title;
  final String subtitle;
  final String description;
  final String levels;
  final String levelDetails;
  final String badge;
  final String route;

  const GameCatalogItem({
    required this.id,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.levels,
    required this.levelDetails,
    required this.badge,
    required this.route,
  });
}

const List<GameCatalogItem> kAvailableGames = [
  GameCatalogItem(
    id: 'memory-match',
    icon: Icons.psychology_rounded,
    color: 'teal',
    title: 'Memory Match',
    subtitle: 'Visual Pair Matching',
    description:
        'Match pairs of familiar, everyday pictures to gently practice visual memory and concentration.',
    levels: '3 Levels',
    levelDetails: 'Level 1 (2 pairs) • Level 2 (4 pairs) • Level 3 (6 pairs)',
    badge: 'Popular',
    route: '/games/memory-match',
  ),
  GameCatalogItem(
    id: 'word-recall',
    icon: Icons.menu_book_rounded,
    color: 'violet',
    title: 'Word Recall & Delayed Memory',
    subtitle: 'Word Recognition & Recall',
    description:
        'Read everyday words, enjoy a gentle distraction activity, and see which words you recall later.',
    levels: '3 Difficulties',
    levelDetails: 'Easy (5 words) • Medium (5 words) • Hard (7 words)',
    badge: 'Recommended',
    route: '/games/word-recall',
  ),
  GameCatalogItem(
    id: 'different-object',
    icon: Icons.auto_awesome_rounded,
    color: 'amber',
    title: 'Find the Different Object',
    subtitle: 'Category Odd-One-Out',
    description:
        'Spot the object that belongs to a different category than all the others. A fun, stress-free recognition exercise.',
    levels: '3 Levels',
    levelDetails: 'Easy (6 items) • Medium (8 items) • Hard (10 items)',
    badge: 'New',
    route: '/games/different-object',
  ),
];

class GamesHubScreen extends StatelessWidget {
  final String backLabel;

  const GamesHubScreen({
    super.key,
    this.backLabel = 'Back to Dashboard',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/patient-dashboard');
            }
          },
          tooltip: backLabel,
        ),
        title: Row(
          children: [
            IconBubble.teal(icon: Icons.psychology_rounded, size: 36),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cognitive Games',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Thoughtful activities for memory & focus',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.borderLight, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Supportive intro banner for elderly users
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8F5F4), Color(0xFFF0FDF8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded,
                          size: 16, color: AppColors.teal),
                      const SizedBox(width: 6),
                      Text(
                        'Gentle Brain Fitness',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.tealDark,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.05,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Exercise your mind at your own comfortable pace',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'These games are designed specifically for clarity, comfort, and peace of mind. Take all the time you need. There is no rush or pressure.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.inkSoft,
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _BadgePill(
                        icon: Icons.shield_outlined,
                        label: 'Stress-Free',
                        color: AppColors.tealDark,
                        bgColor: AppColors.tealLight,
                      ),
                      _BadgePill(
                        icon: Icons.layers_outlined,
                        label: 'Level-Based',
                        color: AppColors.blueDeep,
                        bgColor: AppColors.bluePale,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Section heading
            Text(
              'Available Activities',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 14),

            // ── Games list
            ...kAvailableGames.map((game) => Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _GameCard(game: game),
                )),
          ],
        ),
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;

  const _BadgePill({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final GameCatalogItem game;

  const _GameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    Color iconBg;
    Color iconFg;
    if (game.color == 'teal') {
      iconBg = AppColors.tealLight;
      iconFg = AppColors.tealDark;
    } else if (game.color == 'violet') {
      iconBg = AppColors.violetPale;
      iconFg = AppColors.violetDeep;
    } else {
      iconBg = AppColors.amberPale;
      iconFg = AppColors.amberDeep;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(game.icon, color: iconFg, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: iconBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            game.badge,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: iconFg,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.softSection,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Text(
                            game.levels,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      game.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                    ),
                    Text(
                      game.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            game.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkSoft,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.layers_rounded, size: 16, color: AppColors.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  game.levelDetails,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SmritiButton(
            label: 'Play Game',
            width: double.infinity,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            onPressed: () => context.go(game.route),
          ),
        ],
      ),
    );
  }
}
