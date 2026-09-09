// lib/features/games/memory_match/memory_match_screen.dart
//
// Full Memory Match cognitive game for Flutter.
// Faithfully ports MemoryMatch.jsx with responsive tactile cards,
// sound-alike visual feedback, timer, level selection, and performance scoring.

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/smriti_button.dart';

const List<String> kMemoryIconPool = [
  '🍎', '🍌', '☕', '🏠', '🌸', '🐶', '🚗', '📚'
];

class MemoryMatchLevel {
  final int pairs;
  final int cols;
  final String label;
  final int parSeconds;

  const MemoryMatchLevel({
    required this.pairs,
    required this.cols,
    required this.label,
    required this.parSeconds,
  });
}

const Map<int, MemoryMatchLevel> kMemoryLevels = {
  1: MemoryMatchLevel(pairs: 2, cols: 2, label: 'Level 1', parSeconds: 20),
  2: MemoryMatchLevel(pairs: 4, cols: 4, label: 'Level 2', parSeconds: 45),
  3: MemoryMatchLevel(pairs: 6, cols: 4, label: 'Level 3', parSeconds: 75),
};

class MemoryCardModel {
  final String id;
  final String icon;
  bool isFlipped;
  bool isMatched;

  MemoryCardModel({
    required this.id,
    required this.icon,
    this.isFlipped = false,
    this.isMatched = false,
  });
}

class MemoryMatchScreen extends StatefulWidget {
  const MemoryMatchScreen({super.key});

  @override
  State<MemoryMatchScreen> createState() => _MemoryMatchScreenState();
}

class _MemoryMatchScreenState extends State<MemoryMatchScreen> {
  int _currentLevel = 1;
  List<MemoryCardModel> _deck = [];
  final List<String> _flippedIds = [];
  int _matchedCount = 0;
  int _moves = 0;
  bool _locked = false;
  int _seconds = 0;
  bool _running = false;
  bool _finished = false;

  Timer? _timer;
  Timer? _flipBackTimer;

  @override
  void initState() {
    super.initState();
    _startLevel(_currentLevel);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _flipBackTimer?.cancel();
    super.dispose();
  }

  void _startLevel(int lvl) {
    _timer?.cancel();
    _flipBackTimer?.cancel();

    final levelConfig = kMemoryLevels[lvl]!;
    final icons = kMemoryIconPool.sublist(0, levelConfig.pairs);
    final combined = [...icons, ...icons];
    combined.shuffle(Random());

    final newDeck = List.generate(
      combined.length,
      (i) => MemoryCardModel(
        id: '$lvl-$i-${combined[i]}-${Random().nextInt(99999)}',
        icon: combined[i],
      ),
    );

    setState(() {
      _currentLevel = lvl;
      _deck = newDeck;
      _flippedIds.clear();
      _matchedCount = 0;
      _moves = 0;
      _locked = false;
      _seconds = 0;
      _running = false;
      _finished = false;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _running = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _running && !_finished) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  void _handleCardTap(MemoryCardModel card) {
    if (_locked || card.isFlipped || card.isMatched || _finished) return;
    if (_flippedIds.length == 2) return;

    if (!_running) {
      _startTimer();
    }

    setState(() {
      card.isFlipped = true;
      _flippedIds.add(card.id);
    });

    if (_flippedIds.length == 2) {
      _locked = true;
      _moves++;

      final firstId = _flippedIds[0];
      final secondId = _flippedIds[1];
      final firstCard = _deck.firstWhere((c) => c.id == firstId);
      final secondCard = _deck.firstWhere((c) => c.id == secondId);

      if (firstCard.icon == secondCard.icon) {
        // Match found
        _flipBackTimer = Timer(const Duration(milliseconds: 450), () {
          if (!mounted) return;
          setState(() {
            firstCard.isMatched = true;
            secondCard.isMatched = true;
            _matchedCount++;
            _flippedIds.clear();
            _locked = false;

            final totalPairs = kMemoryLevels[_currentLevel]!.pairs;
            if (_matchedCount == totalPairs) {
              _running = false;
              _finished = true;
              _timer?.cancel();
              _showResultsDialog();
            }
          });
        });
      } else {
        // No match — calm flip back after 900ms
        _flipBackTimer = Timer(const Duration(milliseconds: 900), () {
          if (!mounted) return;
          setState(() {
            firstCard.isFlipped = false;
            secondCard.isFlipped = false;
            _flippedIds.clear();
            _locked = false;
          });
        });
      }
    }
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  int _clampScore(num n) {
    return max(0, min(100, n.round()));
  }

  String _recommendationFor(int score) {
    if (score >= 80) return 'Excellent work! You can try the next level.';
    if (score >= 50) return 'Good work. Try this level again for more practice.';
    return 'Keep practicing at a comfortable pace.';
  }

  void _showResultsDialog() {
    final totalPairs = kMemoryLevels[_currentLevel]!.pairs;
    final accuracy =
        _moves > 0 ? _clampScore((totalPairs / _moves) * 100) : 100;
    final parSeconds = kMemoryLevels[_currentLevel]!.parSeconds;
    final timeEfficiency = _clampScore(
        100 - (max(0, _seconds - parSeconds) / parSeconds) * 100);
    final score = _clampScore(accuracy * 0.65 + timeEfficiency * 0.35);
    final recommendation = _recommendationFor(score);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.tealLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.emoji_events_rounded,
                  color: AppColors.teal, size: 32),
            ),
            const SizedBox(height: 14),
            Text(
              '${kMemoryLevels[_currentLevel]!.label} Completed!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Here is a look at your cognitive activity session.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.softSection,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ResultMetric(label: 'Moves', value: '$_moves'),
                      _ResultMetric(label: 'Accuracy', value: '$accuracy%'),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ResultMetric(
                          label: 'Time Taken', value: _formatTime(_seconds)),
                      _ResultMetric(
                          label: 'Performance', value: '$score / 100'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              recommendation,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.tealDark,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Column(
              children: [
                if (_currentLevel < 3) ...[
                  SmritiButton(
                    label: 'Next Level',
                    width: double.infinity,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _startLevel(_currentLevel + 1);
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                SmritiButton.secondary(
                  label: 'Play Again',
                  width: double.infinity,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _startLevel(_currentLevel);
                  },
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.go('/games');
                  },
                  child: Text(
                    'Back to Games',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final levelConfig = kMemoryLevels[_currentLevel]!;
    final totalPairs = levelConfig.pairs;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/games'),
          tooltip: 'All Games',
        ),
        title: Row(
          children: [
            IconBubble.teal(icon: Icons.psychology_rounded, size: 34),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Memory Match',
                    style: Theme.of(context).textTheme.titleMedium),
                Text(
                  'Gentle visual pair matching',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.muted),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            // ── Controls: Level selection & Restart
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [1, 2, 3].map((lvl) {
                    final selected = _currentLevel == lvl;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _startLevel(lvl),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.teal
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? AppColors.teal
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            kMemoryLevels[lvl]!.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : AppColors.inkSoft,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                IconButton(
                  onPressed: () => _startLevel(_currentLevel),
                  icon: const Icon(Icons.refresh_rounded,
                      color: AppColors.inkSoft),
                  tooltip: 'Restart Game',
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── Stats Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    icon: Icons.ads_click_rounded,
                    color: AppColors.violetDeep,
                    bgColor: AppColors.violetPale,
                    label: 'Moves',
                    value: '$_moves',
                  ),
                  Container(
                      width: 1, height: 32, color: AppColors.borderLight),
                  _StatItem(
                    icon: Icons.emoji_events_outlined,
                    color: AppColors.tealDark,
                    bgColor: AppColors.tealLight,
                    label: 'Matched',
                    value: '$_matchedCount / $totalPairs',
                  ),
                  Container(
                      width: 1, height: 32, color: AppColors.borderLight),
                  _StatItem(
                    icon: Icons.timer_outlined,
                    color: AppColors.amberDeep,
                    bgColor: AppColors.amberPale,
                    label: 'Time',
                    value: _formatTime(_seconds),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Instruction
            Text(
              'Tap two cards to reveal them. Find every matching pair to complete the level.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
            ),
            const SizedBox(height: 20),

            // ── Cards Grid
            _buildCardGrid(levelConfig.cols),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCardGrid(int cols) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const spacing = 12.0;
        final cardWidth = (totalWidth - (cols - 1) * spacing) / cols;
        final cardHeight = cardWidth * 1.15;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: _deck.map((card) {
            final isVisible = card.isFlipped || card.isMatched;

            return GestureDetector(
              onTap: () => _handleCardTap(card),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: cardWidth,
                height: cardHeight,
                decoration: BoxDecoration(
                  color: card.isMatched
                      ? const Color(0xFFE6F9F5)
                      : isVisible
                          ? AppColors.surface
                          : AppColors.teal,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: card.isMatched
                        ? const Color(0xFF4BBCB0)
                        : isVisible
                            ? AppColors.teal
                            : Colors.transparent,
                    width: card.isMatched ? 2 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: isVisible
                    ? Text(
                        card.icon,
                        style: TextStyle(fontSize: cardWidth * 0.45),
                      )
                    : Icon(
                        Icons.psychology_rounded,
                        color: Colors.white.withValues(alpha: 0.85),
                        size: cardWidth * 0.42,
                      ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.muted)),
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ResultMetric extends StatelessWidget {
  final String label;
  final String value;

  const _ResultMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}
