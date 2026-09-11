// lib/core/voice/widgets/voice_assistant_modal.dart
//
// Elder-friendly Voice Assistant Modal Bottom Sheet.
// Features:
// - Automatic listening on open
// - Big touch targets and clear pulsing mic indicator
// - Multilingual guidance for English, Hindi, and Assamese
// - Large confirmation buttons for sensitive actions
// - Graceful text fallback input field

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../localization/app_localizations.dart';
import '../voice_assistant_controller.dart';
import '../voice_action_executor.dart';

/// Displays the SmritiCare Voice Assistant modal bottom sheet.
Future<void> showVoiceAssistantModal({
  required BuildContext context,
  String? currentRoute,
  void Function(String route, {Map<String, dynamic>? arguments})? onNavigate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (modalContext) => VoiceAssistantModal(
      currentRoute: currentRoute,
      onNavigate: onNavigate,
    ),
  );
}

class VoiceAssistantModal extends StatefulWidget {
  final String? currentRoute;
  final void Function(String route, {Map<String, dynamic>? arguments})?
      onNavigate;

  const VoiceAssistantModal({
    super.key,
    this.currentRoute,
    this.onNavigate,
  });

  @override
  State<VoiceAssistantModal> createState() => _VoiceAssistantModalState();
}

class _VoiceAssistantModalState extends State<VoiceAssistantModal>
    with SingleTickerProviderStateMixin {
  late final VoiceAssistantController _controller;
  late final TextEditingController _textInputController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _textInputController = TextEditingController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _controller = VoiceAssistantController(
      actionExecutor: VoiceActionExecutor(
        onNavigate: (route, {arguments}) {
          Navigator.of(context).pop();
          if (widget.onNavigate != null) {
            widget.onNavigate!(route, arguments: arguments);
          }
        },
      ),
    );

    _controller.addListener(_onControllerUpdate);

    // Automatic listening after opening the assistant
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.openAssistant(
        currentRoute: widget.currentRoute,
        autoListen: true,
      );
    });
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _textInputController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _submitTextInput() {
    final text = _textInputController.text.trim();
    if (text.isNotEmpty) {
      _textInputController.clear();
      _controller.processTextInput(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _controller.status;
    final lang = _controller.activeLanguageCode;
    final isConfirming = _controller.isConfirming;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 24 + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Top Handle ───────────────────────────────────────────────
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 14),

              // ── Header: Title & Language Badge ────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.tealPale,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.record_voice_over_rounded,
                          color: AppColors.teal,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _getTitle(lang),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 26),
                    tooltip: 'Close',
                    onPressed: () async {
                      await _controller.cancelAssistant();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Current Language Display Badge ────────────────────────────
              _buildLanguageBadge(lang),

              const SizedBox(height: 18),

              // ── Simple Elderly-Friendly Listening & Status State ─────────
              _buildMicrophonePill(status, lang),

              const SizedBox(height: 18),

              // ── Recognized / Transcribed Speech Card ──────────────────────
              _buildFeedbackCard(status, lang),

              // ── Sensitive Confirmation Buttons (If Confirming) ────────────
              if (isConfirming) ...[
                const SizedBox(height: 18),
                _buildConfirmationActions(lang),
              ],

              const SizedBox(height: 18),

              // ── Text Fallback Input Bar ───────────────────────────────────
              _buildTextFallbackBar(lang),

              const SizedBox(height: 16),

              // ── Large Elderly-Friendly Cancel Button ──────────────────────
              _buildLargeCancelButton(lang),

              const SizedBox(height: 14),

              // ── Quick Suggestion Chips ────────────────────────────────────
              _buildQuickSuggestions(lang),
            ],
          ),
        ),
      ),
    );
  }

  /// Displays current active language banner (Requirement 5).
  Widget _buildLanguageBadge(String lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.tealPale,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.teal.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.translate_rounded,
            size: 18,
            color: AppColors.tealDeep,
          ),
          const SizedBox(width: 8),
          Text(
            _getLanguageLabelText(lang),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.tealDeep,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicrophonePill(VoiceAssistantStatus status, String lang) {
    final isListening = status == VoiceAssistantStatus.listening;
    final isProcessing = status == VoiceAssistantStatus.processing;
    final isExecuting = status == VoiceAssistantStatus.executing;
    final isSpeaking = status == VoiceAssistantStatus.speaking;
    final isError = status == VoiceAssistantStatus.error;
    final isCancelled = status == VoiceAssistantStatus.cancelled;

    Color color = AppColors.teal;
    IconData icon = Icons.mic_rounded;
    String statusText = _getStatusText(status, lang);

    if (isListening) {
      color = AppColors.coralDeep;
      icon = Icons.mic_rounded;
    } else if (isProcessing) {
      color = Colors.amber.shade800;
      icon = Icons.hourglass_top_rounded;
    } else if (isExecuting) {
      color = AppColors.tealDeep;
      icon = Icons.task_alt_rounded;
    } else if (isSpeaking) {
      color = AppColors.tealDeep;
      icon = Icons.volume_up_rounded;
    } else if (isError) {
      color = Colors.red.shade700;
      icon = Icons.error_outline_rounded;
    } else if (isCancelled) {
      color = Colors.blueGrey;
      icon = Icons.cancel_outlined;
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = isListening ? 1.0 + (_pulseController.value * 0.12) : 1.0;
        return Column(
          children: [
            GestureDetector(
              onTap: () {
                if (isListening) {
                  _controller.stopListening();
                } else if (!_controller.isProcessingCommand) {
                  _controller.startListening();
                }
              },
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    boxShadow: [
                      BoxShadow(
                        color:
                            color.withValues(alpha: isListening ? 0.45 : 0.2),
                        blurRadius: isListening ? 22 : 10,
                        spreadRadius: isListening ? 8 : 1,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 42),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              statusText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeedbackCard(VoiceAssistantStatus status, String lang) {
    final transcript = _controller.activeTranscript;
    final feedback = _controller.lastFeedback;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.softSection,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Recognized / Transcribed Text Header & Body (Requirement 5) ─
          Row(
            children: [
              const Icon(
                Icons.record_voice_over_outlined,
                size: 18,
                color: AppColors.teal,
              ),
              const SizedBox(width: 8),
              Text(
                _getRecognizedTextHeader(lang),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            transcript.isNotEmpty
                ? '“$transcript”'
                : _getWaitingTranscriptHint(lang),
            style: TextStyle(
              fontSize: 19,
              fontWeight:
                  transcript.isNotEmpty ? FontWeight.w700 : FontWeight.w500,
              color: transcript.isNotEmpty ? AppColors.ink : AppColors.muted,
              height: 1.3,
            ),
          ),

          // ── Assistant Feedback / Prompt ────────────────────────────────
          if (feedback.isNotEmpty && feedback != transcript) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.assistant_rounded,
                  size: 18,
                  color: AppColors.tealDeep,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    feedback,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tealDeep,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (transcript.isEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _getDefaultPrompt(lang),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.muted,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfirmationActions(String lang) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 24),
              label: Text(
                _getConfirmLabel(lang),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _controller.confirmPendingAction(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 54,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.coralDeep,
                side: const BorderSide(color: AppColors.coralDeep, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.cancel_rounded, size: 24),
              label: Text(
                _getCancelLabel(lang),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _controller.cancelPendingAction(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextFallbackBar(String lang) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _textInputController,
            style: const TextStyle(fontSize: 16, color: AppColors.ink),
            decoration: InputDecoration(
              hintText: _getTextPlaceholder(lang),
              hintStyle: const TextStyle(fontSize: 15, color: AppColors.muted),
              filled: true,
              fillColor: AppColors.softSection,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: AppColors.borderLight, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.teal, width: 2),
              ),
            ),
            onSubmitted: (_) => _submitTextInput(),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 52,
          width: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _submitTextInput,
            child:
                const Icon(Icons.send_rounded, color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }

  /// Large elderly-friendly Cancel button (Requirement 6).
  Widget _buildLargeCancelButton(String lang) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.coralDeep,
          side: const BorderSide(color: AppColors.coralDeep, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.close_rounded, size: 28),
        label: Text(
          _getLargeCancelText(lang),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: () async {
          await _controller.cancelAssistant();
          if (mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  Widget _buildQuickSuggestions(String lang) {
    final chips = _getSuggestionChips(lang);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips.map((c) {
        return ActionChip(
          label: Text(c.label, style: const TextStyle(fontSize: 13)),
          avatar: Icon(c.icon, size: 16, color: AppColors.tealDeep),
          backgroundColor: AppColors.tealPale,
          side: BorderSide.none,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          onPressed: () => _controller.processTextInput(c.command),
        );
      }).toList(),
    );
  }

  // ── LOCALIZATION STRINGS ─────────────────────────────────────────────────

  String _getTitle(String lang) {
    return context.tr(
      'voice.buttonLabel',
      defaultText: lang == 'hi'
          ? 'स्मृति केयर सहायक'
          : (lang == 'as' ? 'স্মৃতি কেয়াৰ সহায়ক' : 'SmritiCare Assistant'),
    );
  }

  String _getLanguageLabelText(String lang) {
    return context.tr(
      'voice.activeLanguage',
      defaultText: lang == 'hi'
          ? 'सक्रिय भाषा: हिंदी (HI)'
          : (lang == 'as'
              ? 'সক্ৰিয় ভাষা: অসমীয়া (AS)'
              : 'Active Language: English (EN)'),
    );
  }

  String _getRecognizedTextHeader(String lang) {
    return context.tr(
      'voice.recognizedSpeech',
      defaultText: lang == 'hi'
          ? 'पहचाना गया आदेश (Recognized):'
          : (lang == 'as'
              ? 'চিনাক্ত কৰা বাক্য (Recognized):'
              : 'Recognized Speech:'),
    );
  }

  String _getWaitingTranscriptHint(String lang) {
    return context.tr(
      'voice.waitingHint',
      defaultText: lang == 'hi'
          ? 'आपकी आवाज़ सुनी जा रही है... बोलिए'
          : (lang == 'as'
              ? 'আপোনাৰ কথা শুনা হৈছে... কওক'
              : 'Listening for your voice... Speak naturally'),
    );
  }

  String _getLargeCancelText(String lang) {
    return context.tr(
      'voice.cancel',
      defaultText: lang == 'hi'
          ? 'रद्द करें (Cancel)'
          : (lang == 'as' ? 'বাতিল কৰক (Cancel)' : 'Cancel'),
    );
  }

  String _getStatusText(VoiceAssistantStatus status, String lang) {
    final statusKey = 'voice.status.${status.name}';
    return context.tr(
      statusKey,
      defaultText: () {
        switch (status) {
          case VoiceAssistantStatus.opening:
            return lang == 'hi'
                ? 'सहायक शुरू हो रहा है...'
                : (lang == 'as' ? 'सहায়ক আৰম্ভ হৈছে...' : 'Opening assistant...');
          case VoiceAssistantStatus.listening:
            return lang == 'hi'
                ? 'सुन रहा हूँ... बोलिए'
                : (lang == 'as' ? 'শুনি আছোঁ... কওক' : 'Listening... Speak now');
          case VoiceAssistantStatus.processing:
            return lang == 'hi'
                ? 'समझ रहा हूँ...'
                : (lang == 'as'
                    ? 'প্ৰক্ৰিয়া কৰি আছোঁ...'
                    : 'Processing command...');
          case VoiceAssistantStatus.executing:
            return lang == 'hi'
                ? 'कार्य किया जा रहा है...'
                : (lang == 'as'
                    ? 'কাৰ্য সম্পাদন কৰা হৈছে...'
                    : 'Executing action...');
          case VoiceAssistantStatus.speaking:
            return lang == 'hi'
                ? 'बोल रहा हूँ...'
                : (lang == 'as' ? 'কৈ আছোঁ...' : 'Speaking...');
          case VoiceAssistantStatus.error:
            return lang == 'hi'
                ? 'त्रुटि। कृपया दोबारा बोलें या नीचे लिखें।'
                : (lang == 'as'
                    ? 'ত্ৰুটি। অনুগ্ৰহ কৰি পুনৰ কওক বা লিখক।'
                    : 'Could not understand. Tap mic to retry or type below.');
          case VoiceAssistantStatus.cancelled:
            return lang == 'hi'
                ? 'कार्य रद्द कर दिया गया'
                : (lang == 'as' ? 'কাৰ্য বাতিল কৰা হ’ল' : 'Action cancelled');
          case VoiceAssistantStatus.idle:
            return lang == 'hi'
                ? 'बोलने के लिए माइक दबाएं'
                : (lang == 'as' ? 'ক’বলৈ মাইকত টিপক' : 'Tap mic to speak');
        }
      }(),
    );
  }

  String _getDefaultPrompt(String lang) {
    return context.tr(
      'voice.defaultPrompt',
      defaultText: lang == 'hi'
          ? 'नमस्ते! आप बोल सकते हैं: "खेल खेलें", "दवाई बताओ", या "मदद चाहिए"'
          : (lang == 'as'
              ? 'নমস্কাৰ! আপুনি ক’ব পাৰে: "খেল খেলক", "ঔষধৰ সোঁৱৰণী", বা "সাহায্য লাগে"'
              : 'Hello! Say "Play games", "Check reminders", or "Emergency help".'),
    );
  }

  String _getConfirmLabel(String lang) {
    return context.tr(
      'voice.confirmYes',
      defaultText: lang == 'hi'
          ? 'हाँ, पुष्टि करें'
          : (lang == 'as' ? 'হয়, নিশ্চিত কৰক' : 'Yes, Confirm'),
    );
  }

  String _getCancelLabel(String lang) {
    return context.tr(
      'voice.confirmNo',
      defaultText: lang == 'hi'
          ? 'नहीं, रद्द करें'
          : (lang == 'as' ? 'নহয়, বাতিল কৰক' : 'Cancel'),
    );
  }

  String _getTextPlaceholder(String lang) {
    return context.tr(
      'voice.typePlaceholder',
      defaultText: lang == 'hi'
          ? 'यहाँ आदेश टाइप करें...'
          : (lang == 'as'
              ? 'ইয়াত নিৰ্দেশ টাইপ কৰক...'
              : 'Type a command here...'),
    );
  }

  List<({String label, String command, IconData icon})> _getSuggestionChips(
      String lang) {
    return [
      (
        label: context.tr('voice.chips.brainGames',
            defaultText: lang == 'hi'
                ? 'दिमागी खेल'
                : (lang == 'as' ? 'মগজুৰ খেল' : 'Brain Games')),
        command: lang == 'hi'
            ? 'खेल खेलें'
            : (lang == 'as' ? 'খেল খেলক' : 'play games'),
        icon: Icons.extension_rounded
      ),
      (
        label: context.tr('voice.chips.reminders',
            defaultText: lang == 'hi'
                ? 'दवाई रिमाइंडर'
                : (lang == 'as' ? 'ঔষধৰ সোঁৱৰণী' : 'Reminders')),
        command: lang == 'hi'
            ? 'मेरी दवाई'
            : (lang == 'as' ? 'মোৰ ঔষধ' : 'check reminders'),
        icon: Icons.medication_rounded
      ),
      (
        label: context.tr('voice.chips.emergencySos',
            defaultText: lang == 'hi'
                ? 'आपातकाल'
                : (lang == 'as' ? 'জৰুৰীকালীন সাহায্য' : 'Emergency SOS')),
        command: lang == 'hi'
            ? 'मदद चाहिए'
            : (lang == 'as' ? 'সাহায্য লাগে' : 'emergency help'),
        icon: Icons.emergency_rounded
      ),
      (
        label: context.tr('voice.chips.takeMeHome',
            defaultText: lang == 'hi'
                ? 'घर का रास्ता'
                : (lang == 'as' ? 'ঘৰৰ পথ' : 'Take Me Home')),
        command: lang == 'hi'
            ? 'घर ले चलो'
            : (lang == 'as' ? 'ঘৰলৈ লৈ যাওক' : 'take me home'),
        icon: Icons.home_rounded
      ),
    ];
  }
}
