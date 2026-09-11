// lib/core/voice/voice_action.dart
//
// Represents an executable action resolved from a VoiceIntent.

import 'voice_intent.dart';

/// Categories of executable actions.
enum VoiceActionType {
  /// Deterministic route navigation.
  navigate,

  /// Query or announce reminders from storage.
  readReminders,

  /// Add a reminder to CaregiverService.
  addReminder,

  /// Trigger emergency SOS / alert caregiver.
  triggerEmergency,

  /// Change active application language.
  changeLanguage,

  /// Announce cognitive status / streak / date.
  speakStatus,

  /// Speak help / capability guide.
  speakHelp,

  /// Adjust difficulty using the deterministic adaptive difficulty mechanism.
  adaptiveDifficulty,

  /// Read next routine activity from existing routine data.
  readRoutine,

  /// Custom extension action.
  custom,

  /// Unknown action or missing context requiring clarification.
  unknown,
}

/// Executable action encapsulating destination, parameters, and confirmation workflow.
class VoiceAction {
  /// Unique identifier for this action instance.
  final String id;

  /// The originating intent.
  final VoiceIntent intent;

  /// Classification of action to execute.
  final VoiceActionType type;

  /// Whether user must confirm before execution (e.g. SOS, deletion).
  final bool requiresConfirmation;

  /// Localized prompt to speak/display when confirmation is needed.
  /// Keys: 'en', 'hi', 'as'.
  final Map<String, String> confirmationPrompts;

  /// Localized feedback messages upon completion.
  /// Keys: 'en', 'hi', 'as'.
  final Map<String, String> feedbackMessages;

  /// Payload parameters required by the executor (e.g. route path, arguments).
  final Map<String, dynamic> payload;

  VoiceAction({
    required this.id,
    required this.intent,
    required this.type,
    this.requiresConfirmation = false,
    this.confirmationPrompts = const {},
    this.feedbackMessages = const {},
    this.payload = const {},
  });

  /// Retrieve localized confirmation prompt with fallback to English.
  String getConfirmationPrompt(String langCode) {
    return confirmationPrompts[langCode] ??
        confirmationPrompts['en'] ??
        'Are you sure you want to proceed?';
  }

  /// Convenience getter for target route from payload
  String? get targetRoute => payload['targetRoute'] as String?;

  /// Retrieve localized feedback message with fallback to English.
  String getFeedbackMessage(String langCode) {
    return feedbackMessages[langCode] ??
        feedbackMessages['en'] ??
        'Action completed.';
  }

  /// Helper factory for navigation actions.
  factory VoiceAction.navigate({
    required String id,
    required VoiceIntent intent,
    required String targetRoute,
    Map<String, dynamic>? routeArguments,
    Map<String, String>? feedbackMessages,
  }) {
    return VoiceAction(
      id: id,
      intent: intent,
      type: VoiceActionType.navigate,
      requiresConfirmation: false,
      feedbackMessages: feedbackMessages ??
          {
            'en': 'Opening screen.',
            'hi': 'स्क्रीन खोली जा रही है।',
            'as': 'স্ক্ৰীন খুলি থকা হৈছে।',
          },
      payload: {
        'targetRoute': targetRoute,
        if (routeArguments != null) 'arguments': routeArguments,
      },
    );
  }

  /// Helper factory for emergency SOS action (Sensitive).
  factory VoiceAction.emergencySos({
    required String id,
    required VoiceIntent intent,
  }) {
    return VoiceAction(
      id: id,
      intent: intent,
      type: VoiceActionType.triggerEmergency,
      requiresConfirmation: true,
      confirmationPrompts: const {
        'en': 'Do you want to call emergency help and alert your caregiver?',
        'hi':
            'क्या आप आपातकालीन सहायता और अपने देखभालकर्ता को सचेत करना चाहते हैं?',
        'as':
            'আপুনি জৰুৰীকালীন সাহায্য আৰু আপোনাৰ তত্ত্বাৱধায়কক সতৰ্ক কৰিব বিচাৰে নেকি?',
      },
      feedbackMessages: const {
        'en': 'Emergency SOS triggered. Help is on the way.',
        'hi': 'आपातकालीन एसओएस सक्रिय कर दिया गया है। सहायता आ रही है।',
        'as': 'জৰুৰীকালীন সাহায্য আৰম্ভ কৰা হ’ল। সহায় আহি আছে।',
      },
      payload: {'route': '/take-me-home'},
    );
  }

  /// Helper factory for CALL_CAREGIVER action: navigates to dedicated confirmation screen.
  factory VoiceAction.callCaregiver({
    required String id,
    required VoiceIntent intent,
  }) {
    return VoiceAction.navigate(
      id: id,
      intent: intent,
      targetRoute: '/caregiver-confirm',
      feedbackMessages: const {
        'en': 'Opening caregiver call confirmation.',
        'hi': 'देखभालकर्ता से संपर्क की पुष्टि स्क्रीन खोली जा रही है।',
        'as': 'তত্ত্বাৱধায়কৰ যোগাযোগ নিশ্চিতকৰণ পৃষ্ঠা খোলা হৈছে।',
      },
    );
  }

  /// Helper factory for language switch action.
  factory VoiceAction.changeLanguage({
    required String id,
    required VoiceIntent intent,
    required String languageCode,
  }) {
    return VoiceAction(
      id: id,
      intent: intent,
      type: VoiceActionType.changeLanguage,
      requiresConfirmation: false,
      feedbackMessages: {
        'en': 'Language changed to English.',
        'hi': 'भाषा बदलकर हिन्दी कर दी गई है।',
        'as': 'ভাষা অসমীয়ালৈ সলনি কৰা হৈছে।',
      },
      payload: {'languageCode': languageCode},
    );
  }

  @override
  String toString() =>
      'VoiceAction(id: $id, type: $type, confirm: $requiresConfirmation, payload: $payload)';
}
