// lib/features/patient/caregiver_confirmation_screen.dart
//
// Patient-facing Caregiver Call Confirmation Screen.
//
// Requirements:
// 1. Invoked when patient says "Call my caregiver" (or taps Call Caregiver).
// 2. Never immediately places a call.
// 3. Clearly explains that caregiver will be contacted.
// 4. Provides large, high-contrast touch targets for Confirm and Cancel.
// 5. Supports voice response ("yes" / "call" or "no" / "cancel") using SpeechService.
// 6. Uses current selected language (English, Hindi, Assamese).
// 7. Avoids accidental confirmation (requires explicit button press or unambiguous voice affirmation).
// 8. NEVER exposes caregiver settings, credentials, or PIN data.
// 9. If no caregiver contact is configured: shows a safe configuration notice and returns home.
// 10. Does not invent phone numbers.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/caregiver_service.dart';
import '../../core/voice/speech_service.dart';
import '../../core/voice/tts_service.dart';
import '../../core/voice/voice_command.dart';
import '../../services/emergency_service.dart';

class CaregiverConfirmationScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const CaregiverConfirmationScreen({
    super.key,
    this.onBack,
  });

  @override
  State<CaregiverConfirmationScreen> createState() =>
      _CaregiverConfirmationScreenState();
}

class _CaregiverConfirmationScreenState
    extends State<CaregiverConfirmationScreen> {
  late final SpeechService _speechService;
  late final TtsService _ttsService;

  bool _isCalling = false;
  bool _isListening = false;
  String _recognizedVoice = '';

  @override
  void initState() {
    super.initState();
    _speechService = SpeechService.instance;
    _ttsService = TtsService.instance;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeVoicePrompt();
    });
  }

  Future<void> _initializeVoicePrompt() async {
    if (!mounted) return;

    final lang = LocalizationService.instance.currentLanguageCode;
    final contact = _getCaregiverContact();
    final hasValidContact = contact != null && contact.phone.trim().isNotEmpty;

    if (!hasValidContact) {
      final notConfiguredMsg = context.tr(
        'voice.caregiverConfirm.notConfiguredDesc',
        defaultText:
            'Caregiver contact details have not been set up yet. Please ask your caregiver to add their contact number in safety settings.',
      );
      await _ttsService.speak(notConfiguredMsg, lang);
      return;
    }

    final promptText = context.tr(
      'voice.caregiverConfirm.callPrompt',
      defaultText: 'Do you want to call your caregiver now?',
    );

    await _ttsService.speak(promptText, lang);

    if (_speechService.isAvailable && mounted) {
      setState(() {
        _isListening = true;
      });

      await _speechService.startListening(
        onCommand: (VoiceCommand cmd) {
          if (!mounted) return;
          _handleVoiceResponse(cmd.text);
        },
        onPartial: (String partial) {
          if (mounted && _isListening) {
            setState(() {
              _recognizedVoice = partial;
            });
          }
        },
      );
    }
  }

  void _handleVoiceResponse(String rawText) {
    final lower = rawText.trim().toLowerCase();
    setState(() {
      _recognizedVoice = rawText;
      _isListening = false;
    });

    // Explicit affirmative keywords across EN, HI, AS
    final isYes = lower.contains('yes') ||
        lower.contains('confirm') ||
        lower.contains('call') ||
        lower.contains('phone') ||
        lower.contains('हाँ') ||
        lower.contains('कॉल') ||
        lower.contains('फोन') ||
        lower.contains('হয়') ||
        lower.contains('কৰক');

    // Explicit negative keywords across EN, HI, AS
    final isNo = lower.contains('no') ||
        lower.contains('cancel') ||
        lower.contains('stop') ||
        lower.contains('back') ||
        lower.contains('नहीं') ||
        lower.contains('रद्द') ||
        lower.contains('নহয়') ||
        lower.contains('বাতিল');

    if (isYes) {
      _initiateCall();
    } else if (isNo) {
      _cancelAndGoBack();
    }
  }

  ({String name, String relationship, String phone})? _getCaregiverContact() {
    // 1. Try CaregiverService emergency contact
    final contact = CaregiverService.instance.getEmergencyContact();
    if (contact.phone.trim().isNotEmpty) {
      return (
        name: contact.name.trim().isNotEmpty ? contact.name : 'Caregiver',
        relationship: contact.relationship.trim().isNotEmpty
            ? contact.relationship
            : 'Family Contact',
        phone: contact.phone.trim(),
      );
    }

    return null;
  }

  Future<void> _initiateCall() async {
    if (_isCalling) return;

    final contact = _getCaregiverContact();
    if (contact == null || contact.phone.trim().isEmpty) {
      return;
    }

    setState(() {
      _isCalling = true;
      _isListening = false;
    });

    await _speechService.stopListening();
    if (!mounted) return;

    final lang = LocalizationService.instance.currentLanguageCode;
    final callingText = context.tr(
      'voice.caregiverConfirm.calling',
      defaultText: 'Calling caregiver...',
    );

    await _ttsService.speak(callingText, lang);

    // Invoke existing native dialer contact mechanism
    await EmergencyService.instance.launchCall(contact.phone);

    if (mounted) {
      setState(() {
        _isCalling = false;
      });
    }
  }

  Future<void> _cancelAndGoBack() async {
    await _speechService.stopListening();
    await _ttsService.stop();

    if (!mounted) return;

    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/');
    }
  }

  @override
  void dispose() {
    _speechService.stopListening();
    _ttsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contact = _getCaregiverContact();
    final hasValidContact = contact != null && contact.phone.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.ink, size: 28),
          tooltip: 'Back',
          onPressed: _cancelAndGoBack,
        ),
        title: Text(
          context.tr('voice.caregiverConfirm.title',
              defaultText: 'Contact Caregiver'),
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Safe Not Configured State ────────────────────────────────
                      if (!hasValidContact) ...[
                        const Spacer(),
                        _buildNotConfiguredCard(),
                        const Spacer(),
                        const SizedBox(height: 20),
                        _buildBackHomeButton(),
                      ] else ...[
                        // ── Caregiver Confirmation Card ───────────────────────────
                        _buildConfirmationCard(contact),
                        const SizedBox(height: 16),

                        // ── Voice Listening & Transcript Indicator ───────────────
                        _buildVoiceListeningBadge(),

                        const Spacer(),
                        const SizedBox(height: 20),

                        // ── Large Touch Targets for Confirm / Cancel ──────────────
                        _buildActionButtons(),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildConfirmationCard(
      ({String name, String relationship, String phone}) contact) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Gentle Contact Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.tealPale,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.teal, width: 2),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 48,
              color: AppColors.tealDeep,
            ),
          ),
          const SizedBox(height: 16),

          // Caregiver Name (Privacy: Only Display Name & Relationship, NO PIN / Credentials)
          Text(
            contact.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),

          // Relationship
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.tealPale,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              contact.relationship,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.tealDeep,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Clear Explanation Text
          Text(
            context.tr(
              'voice.caregiverConfirm.explanation',
              defaultText:
                  'Would you like to call your caregiver for assistance?',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceListeningBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _isListening ? AppColors.tealPale : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isListening ? AppColors.teal : AppColors.borderLight,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
            color: _isListening ? AppColors.tealDeep : AppColors.muted,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _recognizedVoice.isNotEmpty
                      ? '“$_recognizedVoice”'
                      : context.tr(
                          'voice.caregiverConfirm.listeningHint',
                          defaultText:
                              'Say "Yes" or "Call" to place the call, or "No" / "Cancel" to go back.',
                        ),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: _recognizedVoice.isNotEmpty
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: _recognizedVoice.isNotEmpty
                        ? AppColors.ink
                        : AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Large Confirm Call Button
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton.icon(
            key: const Key('caregiver_call_confirm_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: _isCalling
                ? const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : const Icon(Icons.phone_in_talk_rounded, size: 28),
            label: Text(
              _isCalling
                  ? context.tr(
                      'voice.caregiverConfirm.calling',
                      defaultText: 'Calling...',
                    )
                  : context.tr(
                      'voice.caregiverConfirm.callButton',
                      defaultText: 'Call Caregiver',
                    ),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            onPressed: _isCalling ? null : _initiateCall,
          ),
        ),
        const SizedBox(height: 14),

        // Large Cancel Button
        SizedBox(
          width: double.infinity,
          height: 60,
          child: OutlinedButton.icon(
            key: const Key('caregiver_call_cancel_button'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.coralDeep,
              side: const BorderSide(color: AppColors.coralDeep, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: const Icon(Icons.close_rounded, size: 28),
            label: Text(
              context.tr(
                'voice.caregiverConfirm.cancelButton',
                defaultText: 'Cancel & Go Back',
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: _cancelAndGoBack,
          ),
        ),
      ],
    );
  }

  Widget _buildNotConfiguredCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.coralPale, width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.coralPale,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.phone_disabled_rounded,
              color: AppColors.coralDeep,
              size: 44,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            context.tr(
              'voice.caregiverConfirm.notConfiguredTitle',
              defaultText: 'No Caregiver Contact Found',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.tr(
              'voice.caregiverConfirm.notConfiguredDesc',
              defaultText:
                  'Caregiver contact details have not been set up yet. Please ask your caregiver to add their contact number in safety settings.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackHomeButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        key: const Key('caregiver_call_back_home_button'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: const Icon(Icons.home_rounded, size: 26),
        label: Text(
          context.tr(
            'voice.caregiverConfirm.backToHome',
            defaultText: 'Return to Home',
          ),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        onPressed: _cancelAndGoBack,
      ),
    );
  }
}
