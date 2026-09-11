// lib/shared/widgets/dementia_voice_narration_bar.dart
//
// Dementia-Safe Voice Narration Bar with Large Replay Controls.
//
// DESIGN PRINCIPLES:
// 1. High contrast, large touch targets (minimum 48dp).
// 2. Large replay button ("Listen Again").
// 3. Clear text fallback display for hearing-impaired users or noisy settings.
// 4. Play / Pause / Stop controls.
// 5. Zero emojis in the UI or labels.

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../services/tts/text_to_speech_service.dart';
import '../../services/tts/local_text_to_speech_service.dart';

class DementiaVoiceNarrationBar extends StatefulWidget {
  final String textToNarrate;
  final String languageCode;
  final TextToSpeechService? ttsService;
  final bool autoPlay;
  final bool isSecuredContext;

  const DementiaVoiceNarrationBar({
    super.key,
    required this.textToNarrate,
    required this.languageCode,
    this.ttsService,
    this.autoPlay = false,
    this.isSecuredContext = true,
  });

  @override
  State<DementiaVoiceNarrationBar> createState() =>
      _DementiaVoiceNarrationBarState();
}

class _DementiaVoiceNarrationBarState extends State<DementiaVoiceNarrationBar> {
  late TextToSpeechService _tts;
  bool _isPlaying = false;
  bool _isPaused = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tts = widget.ttsService ?? LocalTextToSpeechService.instance;
    if (widget.autoPlay) {
      _speakText();
    }
  }

  Future<void> _speakText() async {
    setState(() {
      _errorMessage = null;
      _isPlaying = true;
      _isPaused = false;
    });

    try {
      final success = await _tts.speak(
        text: widget.textToNarrate,
        languageCode: widget.languageCode,
        isSecuredContext: widget.isSecuredContext,
      );

      if (!mounted) return;
      if (!success) {
        setState(() {
          _isPlaying = false;
          _errorMessage =
              'Audio narration is unavailable for this language. Please read the on-screen text below.';
        });
      } else {
        setState(() {
          _isPlaying = _tts.isSpeaking;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _errorMessage = e.toString().contains('TTSSafetyViolationException')
            ? 'Audio blocked: safety guardrails prohibit speaking medication dosage.'
            : 'Voice playback encountered an error.';
      });
    }
  }

  Future<void> _pauseOrResume() async {
    if (_isPaused) {
      await _tts.resume();
      if (mounted) {
        setState(() {
          _isPaused = false;
          _isPlaying = true;
        });
      }
    } else if (_isPlaying) {
      await _tts.pause();
      if (mounted) {
        setState(() {
          _isPaused = true;
          _isPlaying = false;
        });
      }
    }
  }

  Future<void> _stop() async {
    await _tts.stop();
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _isPaused = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.teal, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Indicator
          Row(
            children: [
              Icon(
                _isPlaying
                    ? Icons.volume_up_rounded
                    : Icons.record_voice_over_rounded,
                color: AppColors.tealDark,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Spoken Assistant',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.tealLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Calm Pace: 0.75x',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.tealDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Primary Text Fallback Display
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Text(
              widget.textToNarrate,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
                height: 1.4,
              ),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.coralPale,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.coralDeep,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Action Controls (Large touch targets)
          Row(
            children: [
              // Large Replay Button
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: _speakText,
                  icon: const Icon(Icons.replay_rounded,
                      size: 24, color: Colors.white),
                  label: const Text(
                    'Listen Again',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Pause / Resume Button
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: (_isPlaying || _isPaused) ? _pauseOrResume : null,
                  icon: Icon(
                    _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    size: 20,
                    color: AppColors.tealDark,
                  ),
                  label: Text(
                    _isPaused ? 'Resume' : 'Pause',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tealDark,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.teal, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Stop Button
              IconButton.filled(
                onPressed: (_isPlaying || _isPaused) ? _stop : null,
                icon: const Icon(Icons.stop_rounded,
                    size: 24, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  padding: const EdgeInsets.all(14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
