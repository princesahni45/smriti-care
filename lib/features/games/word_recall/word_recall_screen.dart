// lib/features/games/word_recall/word_recall_screen.dart
//
// Word Recall & Delayed Memory cognitive game for Flutter.
// Full 7-stage state machine:
// levelSelect -> intro -> learning -> immediateRecall -> distraction -> delayedRecall -> result

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/game_result.dart';
import '../../../core/services/game_storage_service.dart';
import '../../../core/services/caregiver_service.dart';
import '../../../shared/widgets/smriti_button.dart';
import '../game_result_screen.dart';
import 'word_data.dart';

enum WordRecallStep {
  levelSelect,
  intro,
  learning,
  immediateRecall,
  distraction,
  delayedRecall,
  result,
}

class RecallScore {
  final List<String> correct;
  final List<String> incorrect;
  final List<String> missed;
  final int accuracy;

  const RecallScore({
    required this.correct,
    required this.incorrect,
    required this.missed,
    required this.accuracy,
  });
}

class WordRecallScreen extends StatefulWidget {
  const WordRecallScreen({super.key});

  @override
  State<WordRecallScreen> createState() => _WordRecallScreenState();
}

class _WordRecallScreenState extends State<WordRecallScreen> {
  int _currentLevel = 1;
  WordRecallStep _step = WordRecallStep.levelSelect;

  List<WordItem> _targetWordObjs = [];
  List<String> _targetWordsPlain = [];
  int _secondsLeft = 25;
  Timer? _countdownTimer;

  List<String> _immediateOptions = [];
  final List<String> _immediateSelected = [];
  RecallScore? _immediateResult;

  int _distractionIndex = 0;

  List<String> _delayedOptions = [];
  final List<String> _delayedSelected = [];
  RecallScore? _delayedResult;

  @override
  void initState() {
    super.initState();
    _currentLevel =
        GameStorageService.instance.getRecommendedLevel('word-recall');
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _setupGame(int levelId) {
    _countdownTimer?.cancel();
    final cfg = kWordRecallLevels[levelId]!;

    List<WordItem> wordObjs;
    List<String> distractorPool;
    int distractorCount;

    if (cfg.mode == 'random') {
      final pool = [...kWordBankL1]..shuffle(Random());
      wordObjs = pool.sublist(0, cfg.count);
      final chosenWords = wordObjs.map((w) => w.word).toList();
      final leftover = kWordBankL1
          .map((w) => w.word)
          .where((w) => !chosenWords.contains(w))
          .toList();
      distractorPool = [...leftover, ...kDistractorBankL1]..shuffle(Random());
      distractorCount = cfg.distractorCount;
    } else {
      wordObjs = List.from(cfg.fixedWords!);
      distractorPool = List.from(cfg.fixedDistractors!)..shuffle(Random());
      distractorCount = distractorPool.length;
    }

    final targets = wordObjs.map((w) => w.word).toList();
    final chosenDistractors = distractorPool.take(distractorCount).toList();
    final allOptions = [...targets, ...chosenDistractors]..shuffle(Random());

    setState(() {
      _currentLevel = levelId;
      _targetWordObjs = wordObjs;
      _targetWordsPlain = targets;
      _secondsLeft = cfg.learningSeconds;
      _immediateOptions = allOptions;
      _immediateSelected.clear();
      _immediateResult = null;
      _distractionIndex = 0;
      _delayedOptions = buildDelayedOptions(
          targets, cfg.fixedDistractors ?? kDistractorBankL1);
      _delayedSelected.clear();
      _delayedResult = null;
      _step = WordRecallStep.learning;
    });

    _startCountdown();
  }

  List<String> buildDelayedOptions(
      List<String> targets, List<String> distractorPool) {
    final shuffled = [...distractorPool]..shuffle(Random());
    final picked = shuffled.take(targets.length).toList();
    return [...targets, ...picked]..shuffle(Random());
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() {
          _secondsLeft = 0;
          _step = WordRecallStep.immediateRecall;
        });
      } else {
        setState(() {
          _secondsLeft--;
        });
      }
    });
  }

  void _startLearning() {
    _setupGame(_currentLevel);
  }

  void _goToImmediateRecall() {
    _countdownTimer?.cancel();
    setState(() {
      _step = WordRecallStep.immediateRecall;
    });
  }

  RecallScore _scoreSelection(List<String> selected, List<String> targetWords) {
    final correct = targetWords.where((w) => selected.contains(w)).toList();
    final incorrect = selected.where((w) => !targetWords.contains(w)).toList();
    final missed = targetWords.where((w) => !selected.contains(w)).toList();
    final accuracy = targetWords.isNotEmpty
        ? ((correct.length / targetWords.length) * 100).round()
        : 0;

    return RecallScore(
      correct: correct,
      incorrect: incorrect,
      missed: missed,
      accuracy: accuracy,
    );
  }

  void _submitImmediate() {
    final result = _scoreSelection(_immediateSelected, _targetWordsPlain);
    setState(() {
      _immediateResult = result;
      _step = WordRecallStep.distraction;
      _distractionIndex = 0;
    });
  }

  void _handleDistractionAnswer() {
    if (_distractionIndex + 1 >= kDistractionQuestions.length) {
      setState(() {
        _step = WordRecallStep.delayedRecall;
      });
    } else {
      setState(() {
        _distractionIndex++;
      });
    }
  }

  void _submitDelayed() {
    final result = _scoreSelection(_delayedSelected, _targetWordsPlain);
    final immAcc = _immediateResult?.accuracy ?? result.accuracy;
    final combinedAccuracy = ((immAcc + result.accuracy) / 2).round();
    final recommendation = GameStorageService.instance
        .getAdaptiveRecommendation(
            'word-recall', combinedAccuracy, _currentLevel);

    // FIX: Save cognitive game result for caregiver dashboard
    final patientId = CaregiverService.instance.selectedPatientId;
    final gameResult = GameResult(
      id: 'wr_${DateTime.now().millisecondsSinceEpoch}',
      patientId: patientId,
      gameId: 'word-recall',
      gameName: 'Word Recall',
      score: combinedAccuracy,
      maxScore: 100,
      accuracy: combinedAccuracy,
      attempts: _targetWordsPlain.length * 2,
      correctAnswers:
          (_immediateResult?.correct.length ?? 0) + result.correct.length,
      wrongAnswers:
          (_immediateResult?.incorrect.length ?? 0) + result.incorrect.length,
      difficulty: kWordRecallLevels[_currentLevel]!.label,
      completionTimeSeconds: 60,
      timestamp: DateTime.now(),
      recommendation: recommendation,
    );
    GameStorageService.instance.saveResult(gameResult);

    setState(() {
      _delayedResult = result;
      _step = WordRecallStep.result;
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameResultScreen(
          result: gameResult,
          onPlayAgain: () {
            Navigator.of(context).pop();
            final nextLvl =
                GameStorageService.instance.getRecommendedLevel('word-recall');
            setState(() {
              _currentLevel = nextLvl;
              _step = WordRecallStep.intro;
            });
          },
          onBackToGames: () => context.go('/games'),
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (_step == WordRecallStep.levelSelect) {
              context.go('/games');
            } else {
              _countdownTimer?.cancel();
              setState(() {
                _step = WordRecallStep.levelSelect;
              });
            }
          },
          tooltip: 'Back',
        ),
        title: Row(
          children: [
            IconBubble.violet(icon: Icons.menu_book_rounded, size: 34),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('games.wordRecallTitle',
                      defaultText: 'Word Recall'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  context.tr('games.wordRecallSubtitle',
                      defaultText: 'Gentle word memory & delayed recall'),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: _buildCurrentStepView(),
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_step) {
      case WordRecallStep.levelSelect:
        return _buildLevelSelectView();
      case WordRecallStep.intro:
        return _buildIntroView();
      case WordRecallStep.learning:
        return _buildLearningView();
      case WordRecallStep.immediateRecall:
        return _buildImmediateRecallView();
      case WordRecallStep.distraction:
        return _buildDistractionView();
      case WordRecallStep.delayedRecall:
        return _buildDelayedRecallView();
      case WordRecallStep.result:
        return _buildResultView();
    }
  }

  // 1. Level Select View
  Widget _buildLevelSelectView() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.violetPale,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.menu_book_rounded,
              color: AppColors.violetDeep, size: 32),
        ),
        const SizedBox(height: 16),
        Text(
          'Choose Difficulty',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Pick how you would like to play today. Take all the time you need.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
              ),
        ),
        const SizedBox(height: 28),
        ...[1, 2, 3].map((lvlId) {
          final cfg = kWordRecallLevels[lvlId]!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _currentLevel = lvlId;
                    _step = WordRecallStep.intro;
                  });
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border:
                        Border.all(color: AppColors.borderLight, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  cfg.label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.violetPale,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    cfg.difficulty,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.violetDeep,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              cfg.tagline,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.muted,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 16, color: AppColors.violetDeep),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // 2. Intro View
  Widget _buildIntroView() {
    final cfg = kWordRecallLevels[_currentLevel]!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.violetPale,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.menu_book_rounded,
                color: AppColors.violetDeep, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            cfg.label,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'A list of familiar words will appear on screen. Look at them and try to remember as many as you can. We will ask you about them in a little bit!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.inkSoft,
                  height: 1.55,
                ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: SmritiButton.secondary(
                  label: 'Change Level',
                  onPressed: () {
                    setState(() {
                      _step = WordRecallStep.levelSelect;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SmritiButton(
                  label: 'Start Game',
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  onPressed: _startLearning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Learning View
  Widget _buildLearningView() {
    final totalSeconds = kWordRecallLevels[_currentLevel]!.learningSeconds;
    final progress = (_secondsLeft / totalSeconds).clamp(0.0, 1.0);

    return Column(
      children: [
        Text(
          'Take your time to look at and remember these words:',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
        ),
        const SizedBox(height: 20),

        // Word cards grid
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: _targetWordObjs.map((w) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.teal, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.teal.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(w.emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 10),
                  Text(
                    w.word,
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),

        // Timer indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_outlined,
                size: 20, color: AppColors.tealDark),
            const SizedBox(width: 8),
            Text(
              'Viewing time remaining: ${_secondsLeft}s',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.tealDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.tealLight,
            valueColor: const AlwaysStoppedAnimation(AppColors.teal),
          ),
        ),
        const SizedBox(height: 28),

        SmritiButton(
          label: "I'm Ready",
          width: double.infinity,
          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
          onPressed: _goToImmediateRecall,
        ),
      ],
    );
  }

  // 4. Immediate Recall View
  Widget _buildImmediateRecallView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Which words do you remember from the list?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tap each word you saw to select it:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
              ),
        ),
        const SizedBox(height: 24),

        // Selectable chips
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: _immediateOptions.map((word) {
            final isSelected = _immediateSelected.contains(word);
            return FilterChip(
              label: Text(
                word,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.ink,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.teal,
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isSelected ? AppColors.teal : AppColors.border,
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _immediateSelected.add(word);
                  } else {
                    _immediateSelected.remove(word);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 32),

        SmritiButton(
          label: 'Submit Answers',
          width: double.infinity,
          icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
          onPressed: _submitImmediate,
        ),
      ],
    );
  }

  // 5. Distraction View
  Widget _buildDistractionView() {
    final q = kDistractionQuestions[_distractionIndex];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.amberPale,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: AppColors.amberDeep, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            'Quick Question Break',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            q.prompt,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
          ),
          const SizedBox(height: 24),

          // Options
          Column(
            children: q.options.map((opt) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _handleDistractionAnswer,
                    style: OutlinedButton.styleFrom(
                      side:
                          const BorderSide(color: AppColors.border, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      backgroundColor: AppColors.softSection,
                    ),
                    child: Text(
                      opt,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          TextButton(
            onPressed: () {
              setState(() {
                _step = WordRecallStep.delayedRecall;
              });
            },
            child: const Text(
              'Skip to Delayed Recall →',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 6. Delayed Recall View
  Widget _buildDelayedRecallView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Now, can you recall the words from earlier?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tap every word you remember seeing initially:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
              ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: _delayedOptions.map((word) {
            final isSelected = _delayedSelected.contains(word);
            return FilterChip(
              label: Text(
                word,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.ink,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.violet,
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isSelected ? AppColors.violet : AppColors.border,
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _delayedSelected.add(word);
                  } else {
                    _delayedSelected.remove(word);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        SmritiButton(
          label: 'Submit Final Answers',
          width: double.infinity,
          icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
          onPressed: _submitDelayed,
        ),
      ],
    );
  }

  // 7. Result View
  Widget _buildResultView() {
    final totalTargets = _targetWordsPlain.length;
    final immCorrect = _immediateResult?.correct.length ?? 0;
    final immAccuracy = _immediateResult?.accuracy ?? 0;
    final delCorrect = _delayedResult?.correct.length ?? 0;
    final delAccuracy = _delayedResult?.accuracy ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
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
            'Level Completed!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            kWordRecallLevels[_currentLevel]!.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 24),

          // Two side-by-side recall cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.softSection,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('games.immediateRecall',
                            defaultText: 'Immediate Recall'),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.muted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$immCorrect / $totalTargets',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$immAccuracy% accurate',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.tealDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.softSection,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('games.delayedRecall',
                            defaultText: 'Delayed Recall'),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.muted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$delCorrect / $totalTargets',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$delAccuracy% accurate',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.violetDeep,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Encouragement
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.tealLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded,
                    color: AppColors.amberDeep, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _currentLevel < 3
                        ? 'Great effort! Every bit of daily practice helps strengthen recall.'
                        : 'Outstanding! You have completed all three levels today!',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tealDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Actions
          if (_currentLevel < 3) ...[
            SmritiButton(
              label:
                  'Next Level (${kWordRecallLevels[_currentLevel + 1]!.difficulty})',
              width: double.infinity,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              onPressed: () {
                setState(() {
                  _currentLevel++;
                  _step = WordRecallStep.intro;
                });
              },
            ),
            const SizedBox(height: 10),
          ],
          SmritiButton.secondary(
            label: 'Play Again',
            width: double.infinity,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            onPressed: () {
              setState(() {
                _step = WordRecallStep.intro;
              });
            },
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => context.go('/games'),
            child: const Text(
              'Back to Games',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
