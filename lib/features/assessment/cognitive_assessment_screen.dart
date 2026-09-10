// lib/features/assessment/cognitive_assessment_screen.dart
//
// Structured Non-Clinical Cognitive Assessment for Dementia Patients.
// Gently checks Orientation, Immediate Memory, and Attention.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/game_result.dart';
import '../../core/services/game_storage_service.dart';

class CognitiveAssessmentScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const CognitiveAssessmentScreen({super.key, this.onBack});

  @override
  State<CognitiveAssessmentScreen> createState() =>
      _CognitiveAssessmentScreenState();
}

class _CognitiveAssessmentScreenState extends State<CognitiveAssessmentScreen> {
  int _step = 0; // 0: intro, 1: orientation, 2: memory encode, 3: attention, 4: delayed recall, 5: result
  int _orientationScore = 0;
  int _memoryScore = 0;
  int _attentionScore = 0;
  String? _selectedTime;
  String? _selectedAttention;
  final Set<String> _selectedRecallWords = {};

  final List<String> _memoryWords = ['Rose', 'Bicycle', 'Watch'];
  final List<String> _recallOptions = [
    'Rose',
    'Tiger',
    'Bicycle',
    'Mango',
    'Watch',
    'River'
  ];

  void _finishAssessment() async {
    final totalScore = ((_orientationScore + _memoryScore + _attentionScore) / 30 * 100).round();
    final result = GameResult(
      id: 'assess_${DateTime.now().millisecondsSinceEpoch}',
      patientId: 'MC-2048',
      gameId: 'cognitive-assessment',
      gameName: 'Cognitive Assessment',
      score: totalScore,
      accuracy: totalScore,
      attempts: 3,
      correctAnswers: (_orientationScore ~/ 10) + (_memoryScore ~/ 10) + (_attentionScore ~/ 10),
      wrongAnswers: 3 - ((_orientationScore ~/ 10) + (_memoryScore ~/ 10) + (_attentionScore ~/ 10)),
      difficulty: 'Screening Battery',
      completionTimeSeconds: 90,
      timestamp: DateTime.now(),
      recommendation: totalScore >= 70
          ? 'Healthy cognitive engagement observed across orientation, attention, and memory recall.'
          : 'Gentle support recommended. Daily memory matching and orientation games help build confidence.',
    );

    await GameStorageService.instance.saveResult(result);

    setState(() {
      _step = 5;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink, size: 28),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: const Text(
          'Cognitive Assessment',
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 19),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _buildCurrentStep(),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _buildIntroStep();
      case 1:
        return _buildOrientationStep();
      case 2:
        return _buildMemoryEncodeStep();
      case 3:
        return _buildAttentionStep();
      case 4:
        return _buildDelayedRecallStep();
      case 5:
        return _buildResultStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIntroStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.tealLight,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.teal, width: 2),
          ),
          child: const Icon(Icons.psychology_rounded, color: AppColors.tealDark, size: 44),
        ),
        const SizedBox(height: 24),
        Text(
          'Gentle Cognitive Assessment',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        const SizedBox(height: 10),
        const Text(
          'A quick, relaxing 3-minute exercise checking your orientation, attention, and memory recall.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 36),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            onPressed: () => setState(() => _step = 1),
            child: const Text('Begin Assessment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildOrientationStep() {
    final now = DateTime.now();
    String currentTime = 'Morning';
    if (now.hour >= 12 && now.hour < 17) {
      currentTime = 'Afternoon';
    } else if (now.hour >= 17) {
      currentTime = 'Evening';
    }

    final options = ['Morning', 'Afternoon', 'Evening', 'Night'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Section 1 of 3: Orientation',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.tealDark)),
        const SizedBox(height: 12),
        Text(
          'What time of day is it right now?',
          style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        const SizedBox(height: 24),
        ...options.map((opt) {
          final isSelected = _selectedTime == opt;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedTime = opt;
                  _orientationScore = (opt == currentTime) ? 10 : 5;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.tealLight : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.teal : AppColors.borderLight,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  opt,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.tealDark : AppColors.ink,
                  ),
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _selectedTime == null ? null : () => setState(() => _step = 2),
            child: const Text('Continue to Memory',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildMemoryEncodeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Section 2 of 3: Memory Encoding',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.tealDark)),
        const SizedBox(height: 12),
        Text(
          'Please remember these 3 words:',
          style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        const Text('Read them carefully. We will ask you to recall them shortly.',
            style: TextStyle(fontSize: 14, color: AppColors.muted)),
        const SizedBox(height: 28),
        ..._memoryWords.map(
          (w) => Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.tealPale,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, color: AppColors.teal, size: 28),
                const SizedBox(width: 16),
                Text(
                  w,
                  style: GoogleFonts.dmSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.tealDeep,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => setState(() => _step = 3),
            child: const Text('I Have Remembered Them',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildAttentionStep() {
    const question = 'Which of the following comes next in the sequence:\n2, 4, 6, 8, ... ?';
    const options = ['9', '10', '12', '14'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Section 3 of 3: Attention & Focus',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.tealDark)),
        const SizedBox(height: 12),
        Text(
          question,
          style: GoogleFonts.dmSans(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        const SizedBox(height: 24),
        ...options.map((opt) {
          final isSelected = _selectedAttention == opt;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedAttention = opt;
                  _attentionScore = (opt == '10') ? 10 : 4;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.tealLight : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.teal : AppColors.borderLight,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  opt,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppColors.tealDark : AppColors.ink,
                  ),
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _selectedAttention == null ? null : () => setState(() => _step = 4),
            child: const Text('Proceed to Delayed Recall',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildDelayedRecallStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Delayed Memory Recall',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.tealDark)),
        const SizedBox(height: 12),
        Text(
          'Select the 3 words you remembered earlier:',
          style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _recallOptions.map((word) {
            final isSelected = _selectedRecallWords.contains(word);
            return FilterChip(
              label: Text(word,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.ink,
                  )),
              selected: isSelected,
              selectedColor: AppColors.teal,
              backgroundColor: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedRecallWords.add(word);
                  } else {
                    _selectedRecallWords.remove(word);
                  }
                  // Calculate memory score
                  int correct = 0;
                  for (final w in _selectedRecallWords) {
                    if (_memoryWords.contains(w)) correct++;
                  }
                  _memoryScore = (correct * 3.33).round();
                });
              },
            );
          }).toList(),
        ),
        const Spacer(),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _selectedRecallWords.length >= 2 ? _finishAssessment : null,
            child: const Text('Complete Assessment',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildResultStep() {
    final overallScore = ((_orientationScore + _memoryScore + _attentionScore) / 30 * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
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
              const Text('Overall Cognitive Index',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.muted)),
              const SizedBox(height: 8),
              Text(
                '$overallScore%',
                style: GoogleFonts.dmSans(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: AppColors.tealDeep,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _metricTile('Orientation', '$_orientationScore / 10'),
                  _metricTile('Memory', '$_memoryScore / 10'),
                  _metricTile('Attention', '$_attentionScore / 10'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.tealPale,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.thumb_up_rounded, color: AppColors.teal, size: 28),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Wonderful work! Consistent daily checkups support memory stability and caregiver awareness.',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.tealDark),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/');
              }
            },
            child: const Text('Return to Dashboard',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _metricTile(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
      ],
    );
  }
}
