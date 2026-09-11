```dart
// lib/features/games/different_object/different_object_screen.dart
//
// Find the Different Object cognitive game for Flutter.
// Ported from DifferentObject.jsx with tactile touch targets, gentle hints,
// feedback banners, and level completion summary.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/models/game_result.dart';
import '../../../core/services/caregiver_service.dart';
import '../../../core/services/game_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/smriti_button.dart';
import '../game_result_screen.dart';
import 'categories_data.dart';

class GameFeedback {
  final String type;
  final String title;
  final String text;

  const GameFeedback({
    required this.type,
    required this.title,
    required this.text,
  });
}

class DifferentObjectScreen extends StatefulWidget {
  const DifferentObjectScreen({super.key});

  @override
  State<DifferentObjectScreen> createState() =>
      _DifferentObjectScreenState();
}

class _DifferentObjectScreenState extends State<DifferentObjectScreen> {
  int _currentLevel = 1;
  List<DifferentObjectQuestion> _questions = [];
  int _currentIndex = 0;

  String? _selectedId;
  int _wrongAttempts = 0;
  int _totalWrongAttempts = 0;

  bool _isAnswered = false;
  GameFeedback? _feedback;
  bool _showHint = false;

  int _score = 0;
  int _seconds = 0;
  bool _running = false;
  bool _finished = false;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _currentLevel = GameStorageService.instance
        .getRecommendedLevel('different-object');

    _initLevel(_currentLevel);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initLevel(int level) {
    _timer?.cancel();

    final config = kDifferentObjectLevels[level];

    if (config == null) {
      return;
    }

    final generatedQuestions = <DifferentObjectQuestion>[];
    String? lastCategory;

    for (int i = 0; i < config.questionsCount; i++) {
      final question = generateDifferentObjectQuestion(
        config.totalItems,
        lastCategory,
      );

      generatedQuestions.add(question);
      lastCategory = question.commonCategory;
    }

    setState(() {
      _currentLevel = level;
      _questions = generatedQuestions;
      _currentIndex = 0;
      _selectedId = null;
      _wrongAttempts = 0;
      _totalWrongAttempts = 0;
      _isAnswered = false;
      _feedback = null;
      _showHint = false;
      _score = 0;
      _seconds = 0;
      _running = false;
      _finished = false;
    });
  }

  void _startTimer() {
    _timer?.cancel();

    setState(() {
      _running = true;
    });

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted || !_running || _finished) {
          return;
        }

        setState(() {
          _seconds++;
        });
      },
    );
  }

  void _handleObjectTap(GameObjectChoice item) {
    if (_isAnswered || _finished) {
      return;
    }

    if (!_running) {
      _startTimer();
    }

    final currentQuestion = _questions[_currentIndex];

    setState(() {
      _selectedId = item.id;
    });

    if (item.isOdd) {
      setState(() {
        _isAnswered = true;
        _score++;

        _feedback = GameFeedback(
          type: 'correct',
          title: 'Correct! Well Done',
          text:
              "That's right! ${item.emoji} ${item.name} is a "
              '${item.categoryName.toLowerCase()}, while all other items '
              'are ${currentQuestion.commonCategory.toLowerCase()}.',
        );
      });
    } else {
      final nextWrongAttempts = _wrongAttempts + 1;
      final nextTotalWrongAttempts = _totalWrongAttempts + 1;

      setState(() {
        _wrongAttempts = nextWrongAttempts;
        _totalWrongAttempts = nextTotalWrongAttempts;

        if (nextWrongAttempts >= 3) {
          _showHint = true;
          _feedback = GameFeedback(
            type: 'hint',
            title: 'Here is a gentle hint',
            text:
                'Most of these items are '
                '${currentQuestion.commonCategory.toLowerCase()}. '
                'Look for the ${currentQuestion.oddItem.name} '
                '${currentQuestion.oddItem.emoji}!',
          );
        } else {
          _feedback = const GameFeedback(
            type: 'wrong',
            title: 'Try Again',
            text:
                'Take another look at the items and see which one '
                'belongs to a different group.',
          );
        }
      });
    }
  }

  void _handleNextQuestion() {
    if (_currentIndex + 1 < _questions.length) {
      setState(() {
        _currentIndex++;
        _selectedId = null;
        _wrongAttempts = 0;
        _isAnswered = false;
        _feedback = null;
        _showHint = false;
      });
    } else {
      _timer?.cancel();

      setState(() {
        _running = false;
        _finished = true;
      });

      _showResults();
    }
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showResults() {
    if (!mounted || _questions.isEmpty) {
      return;
    }

    final totalAttempts = _score + _totalWrongAttempts;

    final accuracy = totalAttempts > 0
        ? ((_score / totalAttempts) * 100).round()
        : 100;

    final config = kDifferentObjectLevels[_currentLevel];

    if (config == null) {
      return;
    }

    final recommendation = GameStorageService.instance
        .getAdaptiveRecommendation(
      'different-object',
      accuracy,
      _currentLevel,
    );

    final gameResult = GameResult(
      id: 'do_${DateTime.now().millisecondsSinceEpoch}',
      patientId: CaregiverService.instance.selectedPatientId,
      gameId: 'different-object',
      gameName: 'Find the Different Object',
      score: accuracy,
      accuracy: accuracy,
      attempts: totalAttempts,
      correctAnswers: _score,
      wrongAnswers: _totalWrongAttempts,
      difficulty: config.label,
      completionTimeSeconds: _seconds,
      timestamp: DateTime.now(),
      recommendation: recommendation,
    );

    GameStorageService.instance.saveResult(gameResult);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          return GameResultScreen(
            result: gameResult,
            onPlayAgain: () {
              Navigator.of(context).pop();

              final recommendedLevel = GameStorageService.instance
                  .getRecommendedLevel('different-object');

              _initLevel(recommendedLevel);
            },
            onBackToGames: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/games');
              }
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion =
        _questions.isNotEmpty && _currentIndex < _questions.length
            ? _questions[_currentIndex]
            : null;

    final config = kDifferentObjectLevels[_currentLevel];

    if (config == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'All Games',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/games');
            }
          },
        ),
        title: Row(
          children: [
            IconBubble.amber(
              icon: Icons.auto_awesome_rounded,
              size: 34,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(
                      'games.findDifferentTitle',
                      defaultText: 'Find the Different Object',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    context.tr(
                      'games.findDifferentSubtitle',
                      defaultText: 'Gentle category recognition',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.borderLight,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
        child: Column(
          children: [
            _buildLevelControls(),
            const SizedBox(height: 18),
            _buildStatsStrip(config),
            const SizedBox(height: 16),
            _buildInstructionCard(context),
            const SizedBox(height: 20),
            if (currentQuestion != null)
              _buildObjectsGrid(currentQuestion),
            const SizedBox(height: 20),
            if (_feedback != null) _buildFeedbackBanner(_feedback!),
            const SizedBox(height: 18),
            if (_isAnswered)
              SmritiButton(
                label: _currentIndex + 1 < _questions.length
                    ? context.tr(
                        'games.next',
                        defaultText: 'Next Question',
                      )
                    : context.tr(
                        'progress.viewDetails',
                        defaultText: 'View Results',
                      ),
                width: double.infinity,
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                ),
                onPressed: _handleNextQuestion,
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [1, 2, 3].map((level) {
              final selected = _currentLevel == level;

              return GestureDetector(
                onTap: () => _initLevel(level),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.amberDeep
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? AppColors.amberDeep
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Text(
                    kDifferentObjectLevels[level]!.label
                        .split('—')
                        .first
                        .trim(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? Colors.white
                          : AppColors.inkSoft,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        IconButton(
          onPressed: () => _initLevel(_currentLevel),
          icon: const Icon(
            Icons.refresh_rounded,
            color: AppColors.inkSoft,
          ),
          tooltip: 'Restart',
        ),
      ],
    );
  }

  Widget _buildStatsStrip(DifferentObjectLevelConfig config) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.track_changes_rounded,
            color: AppColors.violetDeep,
            bgColor: AppColors.violetPale,
            label: 'Question',
            value: '${_currentIndex + 1} / ${config.questionsCount}',
          ),
          Container(
            width: 1,
            height: 32,
            color: AppColors.borderLight,
          ),
          _StatItem(
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.tealDark,
            bgColor: AppColors.tealLight,
            label: 'Correct',
            value: '$_score',
          ),
          Container(
            width: 1,
            height: 32,
            color: AppColors.borderLight,
          ),
          _StatItem(
            icon: Icons.timer_outlined,
            color: AppColors.amberDeep,
            bgColor: AppColors.amberPale,
            label: 'Time',
            value: _formatTime(_seconds),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard(BuildContext context) {
    final instruction = context.tr(
      'games.findDifferentInstruction',
      defaultText: 'Find the object that is different from the others.',
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.softSection,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              instruction,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.volume_up_rounded,
              color: AppColors.teal,
            ),
            tooltip: context.tr(
              'games.readAloud',
              defaultText: 'Read Aloud',
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(instruction),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: AppColors.teal,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildObjectsGrid(DifferentObjectQuestion question) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 400;
        final columns = isWide ? 3 : 2;
        const spacing = 12.0;

        final itemWidth =
            (constraints.maxWidth - (columns - 1) * spacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: question.objects.map((item) {
            final isSelected = _selectedId == item.id;
            final isHintItem = _showHint && item.isOdd;
            final isCorrectRevealed = _isAnswered && item.isOdd;

            Color backgroundColor = AppColors.surface;
            Color borderColor = AppColors.borderLight;
            double borderWidth = 1.5;

            if (isCorrectRevealed) {
              backgroundColor = const Color(0xFFE8F9F5);
              borderColor = const Color(0xFF157F7A);
              borderWidth = 2.5;
            } else if (isHintItem) {
              backgroundColor = AppColors.amberPale;
              borderColor = AppColors.amber;
              borderWidth = 2;
            } else if (isSelected) {
              backgroundColor = AppColors.softSection;
              borderColor = AppColors.coral;
              borderWidth = 2;
            }

            return GestureDetector(
              onTap: () => _handleObjectTap(item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: itemWidth,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: borderColor,
                    width: borderWidth,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.emoji,
                      style: const TextStyle(fontSize: 38),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFeedbackBanner(GameFeedback feedback) {
    late Color backgroundColor;
    late Color borderColor;
    late Color iconColor;
    late IconData icon;

    if (feedback.type == 'correct') {
      backgroundColor = const Color(0xFFE8F9F5);
      borderColor = const Color(0xFF157F7A);
      iconColor = AppColors.tealDark;
      icon = Icons.check_circle_rounded;
    } else if (feedback.type == 'hint') {
      backgroundColor = AppColors.amberPale;
      borderColor = AppColors.amber;
      iconColor = AppColors.amberDeep;
      icon = Icons.lightbulb_rounded;
    } else {
      backgroundColor = AppColors.coralPale;
      borderColor = AppColors.coral;
      iconColor = AppColors.coralDeep;
      icon = Icons.info_outline_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feedback.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feedback.text,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.ink,
                        height: 1.45,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```
