// lib/features/games/games_hub_screen.dart
//
// Catalog of cognitive activities for elderly dementia patients.
// Ports GamesHub.jsx with offline local history and adaptive recommendations.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/models/game_result.dart';
import '../../core/services/game_storage_service.dart';

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
    subtitle: 'Category Odd-One-Out (Attention)',
    description:
        'Spot the object that belongs to a different category than all the others. A fun, stress-free recognition exercise.',
    levels: '3 Levels',
    levelDetails: 'Easy (6 items) • Medium (8 items) • Hard (10 items)',
    badge: 'Attention',
    route: '/games/different-object',
  ),
  GameCatalogItem(
    id: 'day-time-orientation',
    icon: Icons.calendar_month_rounded,
    color: 'blue',
    title: 'Day & Time Orientation',
    subtitle: 'Temporal Orientation & Recall',
    description:
        'Gentle check-in questions exploring today\'s day of the week, time of day, current month, and year.',
    levels: 'All Stages',
    levelDetails: '5 Orientation Questions • Immediate Affirmation',
    badge: 'Essential',
    route: '/games/orientation',
  ),
  GameCatalogItem(
    id: 'routine-sequence',
    icon: Icons.low_priority_rounded,
    color: 'coral',
    title: 'Daily Routine Sequence',
    subtitle: 'Executive Function & Sequencing',
    description:
        'Put everyday morning and routine activities into order to practice executive sequencing.',
    levels: '4 Steps',
    levelDetails: 'Morning Routine • Medication • Everyday Care',
    badge: 'Daily Living',
    route: '/games/routine',
  ),
  GameCatalogItem(
    id: 'family-memories',
    icon: Icons.family_restroom_rounded,
    color: 'teal',
    title: 'Family Memories',
    subtitle: 'Loved Ones Association',
    description:
        'Recognize familiar family photos and names to strengthen social reassurance and recall.',
    levels: 'Caregiver Linked',
    levelDetails: 'Connected to Caregiver Family Memories',
    badge: 'Comforting',
    route: '/games/family-memories',
  ),
];

class GamesHubScreen extends StatefulWidget {
  final String backLabel;
  final VoidCallback? onBack;

  const GamesHubScreen({
    super.key,
    this.backLabel = 'Back to Dashboard',
    this.onBack,
  });

  @override
  State<GamesHubScreen> createState() => _GamesHubScreenState();
}

class _GamesHubScreenState extends State<GamesHubScreen> {
  List<GameResult> _recentResults = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _recentResults = GameStorageService.instance.getRecentResults(limit: 5);
    });
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 28, color: AppColors.ink),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/');
            }
          },
          tooltip: widget.backLabel,
        ),
        title: Text(
          context.tr('games.catalogTitle', defaultText: 'Cognitive Activities'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
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
                          size: 18, color: AppColors.teal),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('games.gentleFitness', defaultText: 'Gentle Brain Fitness'),
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
                    context.tr('games.fitnessHeading',
                        defaultText: 'Exercise your mind at your own comfortable pace'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.tr('games.fitnessDesc',
                        defaultText:
                            'These activities are designed for comfort, clarity, and fun. Take all the time you need — there is zero rush or pressure.'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.inkSoft,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Games List Header
            const Row(
              children: [
                Icon(Icons.sports_esports_rounded, size: 22, color: AppColors.teal),
                SizedBox(width: 8),
                Text(
                  'Available Activities',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── List of Available Games
            ...kAvailableGames.map((game) => _buildGameCard(context, game)),

            const SizedBox(height: 24),

            // ── Recent Activity & Offline History (Step 14)
            _buildHistorySection(),

            const SizedBox(height: 24),

            // ── Upcoming Roadmap Preview
            _buildUpcomingRoadmapSection(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard(BuildContext context, GameCatalogItem game) {
    Color iconBg;
    Color iconFg;

    if (game.color == 'teal') {
      iconBg = AppColors.tealPale;
      iconFg = AppColors.teal;
    } else if (game.color == 'violet') {
      iconBg = AppColors.violetPale;
      iconFg = AppColors.violetDeep;
    } else {
      iconBg = AppColors.amberPale;
      iconFg = AppColors.amberDeep;
    }

    final recommendedLevel = GameStorageService.instance.getRecommendedLevel(game.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderLight, width: 1.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      game.subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            game.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.inkSoft,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 12),

          // Adaptive level pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.tealPale,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.speed_rounded, size: 14, color: AppColors.tealDeep),
                const SizedBox(width: 6),
                Text(
                  'Recommended: Level $recommendedLevel',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.tealDeep,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 24),
              label: Text(
                'Play ${game.title}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: () async {
                await context.push(game.route);
                _loadHistory();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.history_rounded, size: 22, color: AppColors.violet),
            SizedBox(width: 8),
            Text(
              'Recent Activity & Scores',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_recentResults.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.muted, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No activities completed yet today. Play any game above to start your daily brain fitness streak!',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.muted,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ..._recentResults.map((result) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.tealPale,
                    child: Text(
                      '${result.score}%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.tealDeep,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.gameName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          '${result.difficulty} • Time: ${_formatTime(result.completionTimeSeconds)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.teal,
                    size: 20,
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildUpcomingRoadmapSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.softSection,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 20, color: AppColors.amberDeep),
              SizedBox(width: 8),
              Text(
                'Coming in Future Updates',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Pattern Recognition & Daily Routine Recall are currently in development for mobile play.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
