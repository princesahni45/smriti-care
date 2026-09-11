// lib/features/games/orientation/day_time_orientation_screen.dart
//
// Day & Time Orientation Game for Elderly Dementia Patients.
// Gentle, non-clinical temporal orientation questions.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/game_result.dart';
import '../../../core/services/game_storage_service.dart';
import '../../../core/services/caregiver_service.dart';
import '../game_result_screen.dart';

class _OrientationQuestion {
  final String question;
  final String category;
  final IconData icon;
  final List<String> options;
  final String correctAnswer;
  final String hint;

  const _OrientationQuestion({
    required this.question,
    required this.category,
    required this.icon,
    required this.options,
    required this.correctAnswer,
    required this.hint,
  });
}

class DayTimeOrientationScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const DayTimeOrientationScreen({super.key, this.onBack});

  @override
  State<DayTimeOrientationScreen> createState() =>
      _DayTimeOrientationScreenState();
}

class _DayTimeOrientationScreenState extends State<DayTimeOrientationScreen> {
  int _currentQuestionIndex = 0;
  int _correctCount = 0;
  int _mistakesCount = 0;
  String? _selectedOption;
  bool _answered = false;
  late DateTime _startTime;
  final Stopwatch _stopwatch = Stopwatch();
  final List<_OrientationQuestion> _questions = [];

  @override
  void initState() {
    super.initState();
    _initQuestions();
    _startTime = DateTime.now();
    _stopwatch.start();
  }

  void _initQuestions() {
    final now = DateTime.now();
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final currentDay = weekdays[now.weekday - 1];

    String timeOfDay = 'Morning';
    if (now.hour >= 12 && now.hour < 17) {
      timeOfDay = 'Afternoon';
    } else if (now.hour >= 17 && now.hour < 21) {
      timeOfDay = 'Evening';
    } else if (now.hour >= 21 || now.hour < 5) {
      timeOfDay = 'Night';
    }

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final currentMonth = months[now.month - 1];

    _questions.addAll([
      _OrientationQuestion(
        question: 'What day of the week is it today?',
        category: 'Day Orientation',
        icon: Icons.calendar_today_rounded,
        correctAnswer: currentDay,
        options: _generateDayOptions(currentDay),
        hint: 'Think about what you did yesterday or this morning.',
      ),
      _OrientationQuestion(
        question: 'What time of the day is it right now?',
        category: 'Time Orientation',
        icon: Icons.wb_sunny_rounded,
        correctAnswer: timeOfDay,
        options: const ['Morning', 'Afternoon', 'Evening', 'Night'],
        hint: 'Look outside the window at the sunlight or ambient sky.',
      ),
      _OrientationQuestion(
        question: 'Which month are we in right now?',
        category: 'Month Orientation',
        icon: Icons.event_note_rounded,
        correctAnswer: currentMonth,
        options: _generateMonthOptions(currentMonth),
        hint: 'Consider the time of the year and recent festivals.',
      ),
      _OrientationQuestion(
        question: 'Which year is this?',
        category: 'Year Orientation',
        icon: Icons.history_edu_rounded,
        correctAnswer: '${now.year}',
        options: [
          '${now.year - 1}',
          '${now.year}',
          '${now.year + 1}',
          '${now.year - 5}',
        ]..shuffle(),
        hint: 'The current calendar year.',
      ),
    ]);
  }

  List<String> _generateDayOptions(String correctDay) {
    const all = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final others = all.where((d) => d != correctDay).toList()..shuffle();
    final list = [correctDay, others[0], others[1], others[2]]..shuffle();
    return list;
  }

  List<String> _generateMonthOptions(String correctMonth) {
    const all = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final others = all.where((m) => m != correctMonth).toList()..shuffle();
    final list = [correctMonth, others[0], others[1], others[2]]..shuffle();
    return list;
  }

  void _handleSelectOption(String option) {
    if (_answered) return;

    final current = _questions[_currentQuestionIndex];
    final isCorrect = option == current.correctAnswer;

    setState(() {
      _selectedOption = option;
      _answered = true;
      if (isCorrect) {
        _correctCount++;
      } else {
        _mistakesCount++;
      }
    });

    Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_currentQuestionIndex + 1 < _questions.length) {
        setState(() {
          _currentQuestionIndex++;
          _selectedOption = null;
          _answered = false;
        });
      } else {
        _finishGame();
      }
    });
  }

  Future<void> _finishGame() async {
    _stopwatch.stop();
    final total = _questions.length;
    final accuracy = ((_correctCount / total) * 100).round();
    final score = accuracy;
    final timeSeconds = _stopwatch.elapsed.inSeconds;
    final avgResponse =
        total > 0 ? (timeSeconds / total).toStringAsFixed(1) : '0';

    final result = GameResult(
      id: 'orient_${DateTime.now().millisecondsSinceEpoch}',
      patientId: CaregiverService.instance.selectedPatientId,
      gameId: 'day-time-orientation',
      gameName: 'Day & Time Orientation',
      score: score,
      accuracy: accuracy,
      attempts: total,
      correctAnswers: _correctCount,
      wrongAnswers: _mistakesCount,
      difficulty: 'Level 1',
      completionTimeSeconds: timeSeconds,
      avgResponseTimeSeconds: double.tryParse(avgResponse) ?? 0.0,
      timestamp: _startTime,
      recommendation: accuracy >= 75
          ? 'Wonderful temporal orientation! Your time and date recall is clear.'
          : 'Great effort! Reviewing the date and morning sunlight daily builds reassuring confidence.',
    );

    // FIX: Save real cognitive score after game completion
    // FIX: Sync cognitive result to linked dashboards
    await GameStorageService.instance.saveResult(result);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (ctx) => GameResultScreen(
            result: result,
            onPlayAgain: () {
              Navigator.of(ctx).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const DayTimeOrientationScreen(),
                ),
              );
            },
            onBackToGames: () {
              if (Navigator.of(ctx).canPop()) {
                Navigator.of(ctx).pop();
              } else {
                ctx.go('/games');
              }
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) return const SizedBox.shrink();

    final q = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.ink, size: 28),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/games');
            }
          },
        ),
        title: const Text(
          'Day & Time Orientation',
          style: TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 19,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tealDark,
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}% Completed',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.tealLight,
                  valueColor: const AlwaysStoppedAnimation(AppColors.teal),
                  minHeight: 8,
                ),
              ),

              const SizedBox(height: 28),

              // Question Card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.borderLight, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.tealLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(q.icon, color: AppColors.tealDark, size: 32),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      q.question,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      q.hint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Options
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: q.options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final opt = q.options[index];
                    final isSelected = _selectedOption == opt;
                    final isCorrect = opt == q.correctAnswer;

                    Color bg = AppColors.surface;
                    Color border = AppColors.borderLight;
                    Color textColor = AppColors.ink;

                    if (_answered) {
                      if (isCorrect) {
                        bg = const Color(0xFFE8F5E9);
                        border = Colors.green.shade600;
                        textColor = Colors.green.shade900;
                      } else if (isSelected) {
                        bg = AppColors.coralPale;
                        border = AppColors.coralDeep;
                        textColor = AppColors.coralDeep;
                      }
                    }

                    return InkWell(
                      onTap: _answered ? null : () => _handleSelectOption(opt),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 18),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: border, width: 2),
                        ),
                        child: Row(
                          children: [
                            Text(
                              String.fromCharCode(65 + index),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: textColor.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                opt,
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                            ),
                            if (_answered && isCorrect)
                              const Icon(Icons.check_circle_rounded,
                                  color: Colors.green, size: 26)
                            else if (_answered && isSelected)
                              const Icon(Icons.cancel_rounded,
                                  color: AppColors.coralDeep, size: 26),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
