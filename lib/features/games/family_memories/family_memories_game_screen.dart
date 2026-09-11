// lib/features/games/family_memories/family_memories_game_screen.dart
//
// Family Memories Association Game for Dementia Patients.
// Connects with Caregiver Portal's family memories to reinforce recognition of loved ones.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/game_result.dart';
import '../../../core/models/caregiver_models.dart';
import '../../../core/services/caregiver_service.dart';
import '../../../core/services/game_storage_service.dart';
import '../game_result_screen.dart';

class FamilyMemoriesGameScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const FamilyMemoriesGameScreen({super.key, this.onBack});

  @override
  State<FamilyMemoriesGameScreen> createState() =>
      _FamilyMemoriesGameScreenState();
}

class _FamilyMemoriesGameScreenState extends State<FamilyMemoriesGameScreen> {
  final List<FamilyMemoryMember> _members = [];
  int _currentIndex = 0;
  int _correctAnswers = 0;
  int _mistakesCount = 0;
  String? _selectedRelationship;
  bool _answered = false;
  final Stopwatch _stopwatch = Stopwatch();
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _stopwatch.start();
    _initFamilyData();
  }

  void _initFamilyData() {
    final existing = CaregiverService.instance.getFamilyMembers();
    if (existing.isNotEmpty) {
      _members.addAll(existing);
    } else {
      _members.addAll([
        FamilyMemoryMember(
          id: 'fam_1',
          patientId: 'MC-2048',
          name: 'Rahul Das',
          relationship: 'Son',
          notes: 'Visits every weekend, loves discussing gardening',
          avatarEmoji: '👨',
          createdAt: DateTime.now(),
        ),
        FamilyMemoryMember(
          id: 'fam_2',
          patientId: 'MC-2048',
          name: 'Priya Das',
          relationship: 'Daughter',
          notes: 'Calls every evening at 6 PM, works in healthcare',
          avatarEmoji: '👩',
          createdAt: DateTime.now(),
        ),
        FamilyMemoryMember(
          id: 'fam_3',
          patientId: 'MC-2048',
          name: 'Sneha',
          relationship: 'Granddaughter',
          notes: 'Loves listening to your bedtime folk stories',
          avatarEmoji: '👧',
          createdAt: DateTime.now(),
        ),
        FamilyMemoryMember(
          id: 'fam_4',
          patientId: 'MC-2048',
          name: 'Meera Das',
          relationship: 'Spouse',
          notes: 'Together for over 45 years, your lifelong partner',
          avatarEmoji: '👵',
          createdAt: DateTime.now(),
        ),
      ]);
    }
  }

  List<String> _getOptions(String correctRel) {
    const all = [
      'Son',
      'Daughter',
      'Granddaughter',
      'Grandson',
      'Spouse',
      'Sister',
      'Brother',
      'Dear Friend'
    ];
    final others = all.where((r) => r != correctRel).toList()..shuffle();
    final list = [correctRel, others[0], others[1], others[2]]..shuffle();
    return list;
  }

  void _handleSelect(String chosen, String correctRel) {
    if (_answered) return;

    final isCorrect = chosen == correctRel;

    setState(() {
      _selectedRelationship = chosen;
      _answered = true;
      if (isCorrect) {
        _correctAnswers++;
      } else {
        _mistakesCount++;
      }
    });

    Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      if (_currentIndex + 1 < _members.length) {
        setState(() {
          _currentIndex++;
          _selectedRelationship = null;
          _answered = false;
        });
      } else {
        _finishGame();
      }
    });
  }

  Future<void> _finishGame() async {
    _stopwatch.stop();
    final total = _members.length;
    final accuracy = ((_correctAnswers / total) * 100).round();
    final score = accuracy;
    final timeSeconds = _stopwatch.elapsed.inSeconds;
    final avgResponse =
        total > 0 ? (timeSeconds / total).toStringAsFixed(1) : '0';

    final result = GameResult(
      id: 'family_${DateTime.now().millisecondsSinceEpoch}',
      patientId: CaregiverService.instance.selectedPatientId,
      gameId: 'family-memories',
      gameName: 'Family Memories',
      score: score,
      accuracy: accuracy,
      attempts: total,
      correctAnswers: _correctAnswers,
      wrongAnswers: _mistakesCount,
      difficulty: 'Level 1',
      completionTimeSeconds: timeSeconds,
      avgResponseTimeSeconds: double.tryParse(avgResponse) ?? 0.0,
      timestamp: _startTime,
      recommendation: accuracy >= 75
          ? 'Heartwarming recognition! You remembered your loved ones with wonderful warmth.'
          : 'Family memories bring gentle comfort. Practicing familiar faces every day is comforting.',
    );

    await GameStorageService.instance.saveResult(result);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (ctx) => GameResultScreen(
            result: result,
            onPlayAgain: () {
              Navigator.of(ctx).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => const FamilyMemoriesGameScreen(),
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
    if (_members.isEmpty) return const SizedBox.shrink();

    final currentMember = _members[_currentIndex];
    final progress = (_currentIndex + 1) / _members.length;
    final options = _getOptions(currentMember.relationship);

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
          'Family Memories',
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
              // Progress Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Memory ${_currentIndex + 1} of ${_members.length}',
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

              const SizedBox(height: 24),

              // Family Member Photo & Question Card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
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
                      width: 84,
                      height: 84,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.tealLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.teal, width: 2),
                      ),
                      child: Text(
                        currentMember.avatarEmoji,
                        style: const TextStyle(fontSize: 44),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      currentMember.name,
                      style: GoogleFonts.dmSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'What is their relationship with you?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                      ),
                    ),
                    if (currentMember.notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '💡 "${currentMember.notes}"',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: AppColors.tealDark,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Choices
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final opt = options[index];
                    final isSelected = _selectedRelationship == opt;
                    final isCorrect = opt == currentMember.relationship;

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
                      onTap: _answered
                          ? null
                          : () =>
                              _handleSelect(opt, currentMember.relationship),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: border, width: 2),
                        ),
                        child: Row(
                          children: [
                            Text(
                              opt,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            const Spacer(),
                            if (_answered && isCorrect)
                              const Icon(Icons.favorite_rounded,
                                  color: Colors.green, size: 24)
                            else if (_answered && isSelected)
                              const Icon(Icons.cancel_rounded,
                                  color: AppColors.coralDeep, size: 24),
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
