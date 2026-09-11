// lib/features/voice_assistant/widgets/voice_assistant_sheet.dart
//
// Dementia-friendly voice assistant interface.
// Features:
// 1. Microphone permission handling with elderly-friendly prompt.
// 2. Clear visible listening indicator.
// 3. Stop speaking button.
// 4. Cancel and retry operations.
// 5. On-screen text fallback for hearing/speech impaired or noisy environments.
// 6. Large high-contrast touch targets.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../services/voice/speech_recognition_service.dart';
import '../../../services/voice/ai4bharat_asr_service.dart';
import '../../../services/voice/voice_intent_router.dart';
import '../../../services/voice/deterministic_voice_intent_router.dart';
import '../../../services/voice/models/voice_models.dart';
import '../../../services/tts/text_to_speech_service.dart';
import '../../../services/tts/local_text_to_speech_service.dart';
import '../../../services/voice/voice_feature_service.dart';

class VoiceAssistantSheet extends StatefulWidget {
  final SpeechRecognitionService? speechService;
  final TextToSpeechService? ttsService;
  final VoiceIntentRouter? intentRouter;
  final void Function(VoiceIntentResult intent)? onIntentResolved;

  const VoiceAssistantSheet({
    super.key,
    this.speechService,
    this.ttsService,
    this.intentRouter,
    this.onIntentResolved,
  });

  static Future<void> show(
    BuildContext context, {
    SpeechRecognitionService? speechService,
    TextToSpeechService? ttsService,
    VoiceIntentRouter? intentRouter,
    void Function(VoiceIntentResult intent)? onIntentResolved,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VoiceAssistantSheet(
        speechService: speechService,
        ttsService: ttsService,
        intentRouter: intentRouter,
        onIntentResolved: onIntentResolved,
      ),
    );
  }

  @override
  State<VoiceAssistantSheet> createState() => _VoiceAssistantSheetState();
}

class _VoiceAssistantSheetState extends State<VoiceAssistantSheet>
    with SingleTickerProviderStateMixin {
  late final SpeechRecognitionService _speech;
  late final TextToSpeechService _tts;
  late final VoiceIntentRouter _router;

  VoiceState _state = VoiceState.idle;
  String? _recognizedText;
  VoiceError? _error;
  bool _showTextFallback = false;
  VoiceIntentResult? _pendingIntent;
  String? _pendingUtterance;
  final TextEditingController _textController = TextEditingController();

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _speech = widget.speechService ?? AI4BharatASRService.instance;
    _tts = widget.ttsService ?? LocalTextToSpeechService.instance;
    _router = widget.intentRouter ?? const DeterministicVoiceIntentRouter();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _startSession();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _textController.dispose();
    _speech.cancelListening();
    _tts.stop();
    super.dispose();
  }

  Future<void> _startSession() async {
    setState(() {
      _error = null;
      _recognizedText = null;
      _state = VoiceState.listening;
    });

    final lang = LocaleController.instance.currentLocale.languageCode;
    await _speech.startListening(
      languageCode: lang,
      onResult: (text) => _handleRecognizedText(text),
      onError: (err) {
        if (!mounted) return;
        setState(() {
          _error = err;
          _state = VoiceState.error;
        });
      },
    );
  }

  Future<void> _handleRecognizedText(String text) async {
    if (!mounted) return;
    setState(() {
      _recognizedText = text;
      _state = VoiceState.processing;
    });

    final lang = LocaleController.instance.currentLocale.languageCode;
    final intent = await _router.resolveIntent(text, lang);

    if (!mounted) return;

    // 1. Safety Violation: Display boundary warning and vocalize guidance
    if (intent.isSafetyViolation) {
      setState(() {
        _state = VoiceState.idle;
        _pendingIntent = intent;
        _pendingUtterance = text;
      });
      final guidance = intent.safeFallbackMessage;
      if (guidance != null && guidance.isNotEmpty) {
        _tts.speak(text: guidance, languageCode: lang, rate: 0.75);
      }
      return;
    }

    // 2. Action requiring confirmation
    if (intent.requiresConfirmation) {
      setState(() {
        _state = VoiceState.idle;
        _pendingIntent = intent;
        _pendingUtterance = text;
      });
      final prompt = intent.confirmationPrompt;
      if (prompt != null && prompt.isNotEmpty) {
        _tts.speak(text: prompt, languageCode: lang, rate: 0.75);
      }
    } else {
      // 3. Direct execution (e.g. readNextReminder, repeatInstruction, or unknown)
      setState(() {
        _state = VoiceState.idle;
      });
      _executeIntent(intent);
    }
  }

  void _confirmPendingIntent() {
    if (_pendingIntent != null) {
      final intent = _pendingIntent!;
      setState(() {
        _pendingIntent = null;
        _pendingUtterance = null;
      });
      _executeIntent(intent);
    }
  }

  void _executeIntent(VoiceIntentResult intent) {
    widget.onIntentResolved?.call(intent);
    final lang = LocaleController.instance.currentLocale.languageCode;

    if (intent.type == VoiceIntentType.cancel) {
      Navigator.of(context).pop();
      return;
    }

    // Flow D: Repeat last verified instruction or reminder
    if (intent.type == VoiceIntentType.repeatInstruction) {
      final textToRepeat = VoiceFeatureService.instance.lastVerifiedInstruction;
      if (textToRepeat != null && textToRepeat.isNotEmpty) {
        _tts.speak(text: textToRepeat, languageCode: lang, rate: 0.75);
      } else {
        _tts.replay();
      }
      return;
    }

    // Flow A: Start a memory game
    if (intent.type == VoiceIntentType.startMemoryGame) {
      final instruction = VoiceFeatureService.instance
          .getMemoryGameInstruction(languageCode: lang);
      _tts.speak(text: instruction, languageCode: lang, rate: 0.75);
      if (mounted) {
        Navigator.of(context).pop();
        context.go('/games/memory-match');
      }
      return;
    }

    // Flow B: What should I do today? (Today's Routine)
    if (intent.type == VoiceIntentType.showTodayReminders) {
      final routineSummary = VoiceFeatureService.instance
          .getTodayRoutineSummary(languageCode: lang);
      _tts.speak(text: routineSummary, languageCode: lang, rate: 0.75);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(routineSummary),
            backgroundColor: AppColors.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
        context.go('/reminders');
      }
      return;
    }

    // Flow C: When is my medicine reminder?
    if (intent.type == VoiceIntentType.readNextReminder) {
      final medSummary = VoiceFeatureService.instance
          .getNextMedicineReminderSummary(languageCode: lang);
      _tts.speak(text: medSummary, languageCode: lang, rate: 0.75);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(medSummary),
            backgroundColor: AppColors.amberDeep,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    // Flow E: Caregiver Help (confirmed navigation)
    if (intent.type == VoiceIntentType.openCaregiverHelp) {
      const helpMsg = 'Connecting to caregiver assistance.';
      VoiceFeatureService.instance.setLastVerifiedInstruction(helpMsg);
      _tts.speak(text: helpMsg, languageCode: lang, rate: 0.75);
      if (mounted) {
        Navigator.of(context).pop();
        context.go('/caregiver-help');
      }
      return;
    }

    // General navigation
    if (intent.actionRoute != null && mounted) {
      final route = intent.actionRoute!;
      final feedback = intent.parameters['feedback'] as String?;
      if (feedback != null && feedback.isNotEmpty) {
        VoiceFeatureService.instance.setLastVerifiedInstruction(feedback);
        _tts.speak(text: feedback, languageCode: lang, rate: 0.75);
      }
      Navigator.of(context).pop();
      context.go(route);
      return;
    }

    if (intent.type == VoiceIntentType.unknown) {
      final msg = intent.safeFallbackMessage ?? 'Command not recognized.';
      VoiceFeatureService.instance.setLastVerifiedInstruction(msg);
      _tts.speak(text: msg, languageCode: lang, rate: 0.75);
    }
  }

  void _cancelPendingIntent() {
    setState(() {
      _pendingIntent = null;
      _pendingUtterance = null;
    });
    _startSession();
  }

  void _submitTextFallback() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      _handleRecognizedText(text);
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Voice Companion',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 28, color: AppColors.ink),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // State-Specific Display
            if (_error != null)
              _buildErrorView(_error!)
            else if (_pendingIntent != null)
              _buildConfirmationView()
            else if (_showTextFallback)
              _buildTextFallbackView()
            else
              _buildActiveListeningView(),

            const SizedBox(height: 20),

            // Bottom Navigation & Actions
            Row(
              children: [
                // Text input toggle (for accessibility / noisy rooms)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showTextFallback = !_showTextFallback;
                        if (_showTextFallback) {
                          _pulseController.stop();
                          _speech.cancelListening();
                        } else {
                          _pulseController.repeat(reverse: true);
                          _startSession();
                        }
                      });
                    },
                    icon: Icon(
                      _showTextFallback ? Icons.mic : Icons.keyboard,
                      color: AppColors.tealDark,
                      size: 20,
                    ),
                    label: Text(
                      _showTextFallback ? 'Use Voice' : 'Type Instead',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tealDark,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.teal, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                if (_tts.isSpeaking) ...[
                  const SizedBox(width: 12),
                  // Stop Speaking Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _tts.stop();
                        if (mounted) setState(() {});
                      },
                      icon: const Icon(Icons.volume_off, color: Colors.white),
                      label: const Text(
                        'Stop Sound',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coral,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveListeningView() {
    return Column(
      children: [
        // Pulsing listening orb
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = 1.0 + (_pulseController.value * 0.15);
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _state == VoiceState.listening
                      ? AppColors.tealLight
                      : AppColors.borderLight,
                  border: Border.all(
                    color: _state == VoiceState.listening
                        ? AppColors.teal
                        : AppColors.muted,
                    width: 3,
                  ),
                ),
                child: Icon(
                  _state == VoiceState.listening ? Icons.mic : Icons.mic_off,
                  size: 44,
                  color: _state == VoiceState.listening
                      ? AppColors.teal
                      : AppColors.muted,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        Text(
          _state == VoiceState.listening
              ? 'Listening... please speak calmly.'
              : (_recognizedText ?? 'Ready'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'You can say: "Help", "Take me home", "Reminders", or "Call doctor".',
          style: TextStyle(fontSize: 14, color: AppColors.muted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        // Stop / Cancel button
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                await _speech.stopListening();
                if (mounted) setState(() => _state = VoiceState.idle);
              },
              icon: const Icon(Icons.stop, color: Colors.white),
              label: const Text('Done Speaking',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () async {
                await _speech.cancelListening();
                if (mounted) setState(() => _state = VoiceState.idle);
              },
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: AppColors.ink, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorView(VoiceError err) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.coralPale,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.coral, width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.coralDeep, size: 36),
          const SizedBox(height: 10),
          Text(
            err.userFacingMessage,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => _startSession(),
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            label: const Text(
              'Try Again',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationView() {
    final intent = _pendingIntent!;

    // 1. Safety Violation View: Highlights medical/operational boundary
    if (intent.isSafetyViolation) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.coralPale,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.coralDeep, width: 2),
        ),
        child: Column(
          children: [
            const Icon(Icons.shield_outlined,
                color: AppColors.coralDeep, size: 44),
            const SizedBox(height: 10),
            const Text(
              'Safety Boundary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              intent.safetyViolationReason ??
                  'This action cannot be performed by voice.',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.coralDeep,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              intent.safeFallbackMessage ??
                  'Please speak with your caregiver or physician.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.ink,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _pendingIntent = null;
                  _pendingUtterance = null;
                });
                _startSession();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Understood',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 2. Action confirmation view for safe intents
    String actionTitle = 'Confirm Action';
    IconData actionIcon = Icons.check_circle_outline_rounded;

    switch (intent.type) {
      case VoiceIntentType.openGames:
        actionTitle = 'Open Brain Games?';
        actionIcon = Icons.sports_esports_rounded;
        break;
      case VoiceIntentType.startMemoryGame:
        actionTitle = 'Start Memory Match?';
        actionIcon = Icons.psychology_rounded;
        break;
      case VoiceIntentType.showTodayReminders:
        actionTitle = 'Open Today Reminders?';
        actionIcon = Icons.alarm_rounded;
        break;
      case VoiceIntentType.readNextReminder:
        actionTitle = 'Read Next Reminder?';
        actionIcon = Icons.record_voice_over_rounded;
        break;
      case VoiceIntentType.repeatInstruction:
        actionTitle = 'Repeat Instruction?';
        actionIcon = Icons.replay_rounded;
        break;
      case VoiceIntentType.openCaregiverHelp:
        actionTitle = 'Contact Caregiver / Help?';
        actionIcon = Icons.phone_in_talk_rounded;
        break;
      case VoiceIntentType.openSettings:
        actionTitle = 'Open Settings?';
        actionIcon = Icons.settings_rounded;
        break;
      case VoiceIntentType.goHome:
        actionTitle = 'Navigate Home?';
        actionIcon = Icons.home_rounded;
        break;
      case VoiceIntentType.cancel:
        actionTitle = 'Cancel Voice Session?';
        actionIcon = Icons.close_rounded;
        break;
      case VoiceIntentType.unknown:
        actionTitle = 'Proceed with Request?';
        actionIcon = Icons.help_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.teal, width: 2),
      ),
      child: Column(
        children: [
          Icon(actionIcon, color: AppColors.tealDark, size: 40),
          const SizedBox(height: 10),
          Text(
            actionTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          if (intent.confirmationPrompt != null) ...[
            const SizedBox(height: 6),
            Text(
              intent.confirmationPrompt!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.tealDark,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'We heard:',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 2),
          Text(
            '"${_pendingUtterance ?? ''}"',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.tealDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancelPendingIntent,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.border, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'No, Retry',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _confirmPendingIntent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Yes, Continue',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextFallbackView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Type your question or request:',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _textController,
          style: const TextStyle(fontSize: 18, color: AppColors.ink),
          decoration: InputDecoration(
            hintText: 'e.g. Where is my medicine?',
            hintStyle: const TextStyle(color: AppColors.muted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          onSubmitted: (_) => _submitTextFallback(),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _submitTextFallback,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.teal,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text(
            'Ask',
            style: TextStyle(
                fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
