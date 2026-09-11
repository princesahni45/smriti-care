// lib/features/games/routine/routine_sequence_screen.dart
//
// Sequence & Daily Routine Game for Elderly Dementia Patients.
// Encourages executive function and sequencing of daily living activities (ADLs).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/game_result.dart';
import '../../../core/services/game_storage_service.dart';
import '../../../core/services/caregiver_service.dart';
import '../game_result_screen.dart';

class _RoutineStep {
  final String id;
  final String text;
  final IconData icon;

  const _RoutineStep({
    required this.id,
    required this.text,
    required this.icon,
  });
}

class RoutineSequenceScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const RoutineSequenceScreen({super.key, this.onBack});

  @override
  State<RoutineSequenceScreen> createState() => _RoutineSequenceScreenState();
}

class _RoutineSequenceScreenState extends State<RoutineSequenceScreen> {
  final String _routineTitle = 'Morning Medicine & Routine';
  final String _routinePrompt =
      'Put these morning activities in their natural daily order:';

  final List<_RoutineStep> _correctOrder = const [
    _RoutineStep(
      id: 'step_1',
      text: '1. Wake up and drink a glass of water',
      icon: Icons.wb_sunny_rounded,
    ),
    _RoutineStep(
      id: 'step_2',
      text: '2. Brush your teeth & wash face',
      icon: Icons.clean_hands_rounded,
    ),
    _RoutineStep(
      id: 'step_3',
      text: '3. Enjoy a warm, nutritious breakfast',
      icon: Icons.restaurant_rounded,
    ),
    _RoutineStep(
      id: 'step_4',
      text: '4. Take prescribed morning medicine',
      icon: Icons.medication_rounded,
    ),
  ];

  late List<_RoutineStep> _currentOrder;
  final Stopwatch _stopwatch = Stopwatch();
  late DateTime _startTime;
  int _attemptsCount = 0;
  int _mistakesCount = 0;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _stopwatch.start();
    // Shuffled copy
    _currentOrder = List<_RoutineStep>.from(_correctOrder)..shuffle();
  }

  void _onReorderItem(int oldIndex, int newIndex) {
    setState(() {
      final item = _currentOrder.removeAt(oldIndex);
      _currentOrder.insert(newIndex, item);
    });
  }

  void _checkOrder() {
    _attemptsCount++;
    var correctCount = 0;
    for (int i = 0; i < _currentOrder.length; i++) {
      if (_currentOrder[i].id == _correctOrder[i].id) {
        correctCount++;
      }
    }

    if (correctCount == _correctOrder.length) {
      _stopwatch.stop();
      setState(() {
        _isSuccess = true;
      });
      _finishGame();
    } else {
      setState(() {
        _mistakesCount++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Not quite right yet ($correctCount of ${_correctOrder.length} steps in place). Try dragging cards into sequence!'),
          backgroundColor: AppColors.coralDeep,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _finishGame() async {
    final timeSeconds = _stopwatch.elapsed.inSeconds;
    final accuracy =
        _mistakesCount == 0 ? 100 : (_mistakesCount == 1 ? 80 : 65);
    final score = accuracy;
    final avgResponse = _currentOrder.isNotEmpty
        ? (timeSeconds / _currentOrder.length).toStringAsFixed(1)
        : '0';

    final result = GameResult(
      id: 'routine_${DateTime.now().millisecondsSinceEpoch}',
      patientId: CaregiverService.instance.selectedPatientId,
      gameId: 'routine-sequence',
      gameName: 'Routine Sequence',
      score: score,
      accuracy: accuracy,
      attempts: _attemptsCount,
      correctAnswers: _correctOrder.length,
      wrongAnswers: _mistakesCount,
      difficulty: 'Level 1',
      completionTimeSeconds: timeSeconds,
      avgResponseTimeSeconds: double.tryParse(avgResponse) ?? 0.0,
      timestamp: _startTime,
      recommendation: accuracy >= 80
          ? 'Exceptional logical sequencing! You recalled the daily morning routine perfectly.'
          : 'Good effort! Daily routines help keep our mind organized and comfortable.',
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
                  builder: (_) => const RoutineSequenceScreen(),
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
          'Daily Routine Sequence',
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
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instruction Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.tealLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.low_priority_rounded,
                          color: AppColors.teal, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _routineTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.tealDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _routinePrompt,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Reorderable list
              Expanded(
                child: ReorderableListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _currentOrder.length,
                  onReorderItem: _onReorderItem,
                  itemBuilder: (context, index) {
                    final item = _currentOrder[index];
                    return Container(
                      key: ValueKey(item.id),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.borderLight, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.tealLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(item.icon,
                                color: AppColors.tealDark, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              item.text,
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          const Icon(Icons.drag_handle_rounded,
                              color: AppColors.muted, size: 26),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Action Check Button
              SizedBox(
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
                  icon:
                      const Icon(Icons.check_circle_outline_rounded, size: 24),
                  label: const Text(
                    'Check Sequence',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  onPressed: _isSuccess ? null : _checkOrder,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
