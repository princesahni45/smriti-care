// lib/core/voice/voice_action_executor.dart
//
// Executes resolved VoiceActions against the SmritiCare app state,
// navigation routers, and local services.

import 'package:flutter/material.dart';
import '../services/caregiver_service.dart';
import '../services/game_storage_service.dart';
import '../models/caregiver_models.dart';
import '../localization/app_localizations.dart';
import 'voice_action.dart';
import 'voice_intent.dart';
import 'voice_context.dart';

/// Result returned after executing a VoiceAction.
class VoiceExecutionResult {
  /// Whether the action completed successfully.
  final bool isSuccess;

  /// Response text synthesized for TTS output.
  final String spokenResponse;

  /// Text message for on-screen UI feedback.
  final String displayMessage;

  /// Target route if navigation was performed.
  final String? navigationRoute;

  /// Error message if action failed.
  final String? error;

  const VoiceExecutionResult({
    required this.isSuccess,
    required this.spokenResponse,
    required this.displayMessage,
    this.navigationRoute,
    this.error,
  });

  /// Convenience getter for displayMessage
  String get message => displayMessage;

  factory VoiceExecutionResult.success({
    required String spokenResponse,
    String? displayMessage,
    String? navigationRoute,
  }) {
    return VoiceExecutionResult(
      isSuccess: true,
      spokenResponse: spokenResponse,
      displayMessage: displayMessage ?? spokenResponse,
      navigationRoute: navigationRoute,
    );
  }

  factory VoiceExecutionResult.failure(String error, {String? spokenResponse}) {
    return VoiceExecutionResult(
      isSuccess: false,
      spokenResponse:
          spokenResponse ?? 'Sorry, could not complete that action.',
      displayMessage: error,
      error: error,
    );
  }
}

/// Executor responsible for performing side effects and navigation for VoiceActions.
class VoiceActionExecutor {
  /// Optional navigation callback for decoupled testing and shell integration.
  final void Function(String route, {Map<String, dynamic>? arguments})?
      onNavigate;

  const VoiceActionExecutor({this.onNavigate});

  /// Execute the given [action] in the provided [languageCode].
  Future<VoiceExecutionResult> execute(
    VoiceAction action, {
    String languageCode = 'en',
    BuildContext? context,
  }) async {
    switch (action.type) {
      case VoiceActionType.navigate:
        return _executeNavigation(action, languageCode);

      case VoiceActionType.readReminders:
        return _executeReadReminders(action, languageCode);

      case VoiceActionType.addReminder:
        return _executeAddReminder(action, languageCode);

      case VoiceActionType.triggerEmergency:
        return _executeTriggerEmergency(action, languageCode);

      case VoiceActionType.changeLanguage:
        return _executeChangeLanguage(action, languageCode);

      case VoiceActionType.speakStatus:
        return _executeSpeakStatus(action, languageCode);

      case VoiceActionType.speakHelp:
        return _executeSpeakHelp(action, languageCode);

      case VoiceActionType.adaptiveDifficulty:
        return _executeAdaptiveDifficulty(action, languageCode);

      case VoiceActionType.readRoutine:
        return _executeReadRoutine(action, languageCode);

      case VoiceActionType.custom:
        return VoiceExecutionResult.success(
          spokenResponse: action.getFeedbackMessage(languageCode),
        );

      case VoiceActionType.unknown:
        final clarification = action.getFeedbackMessage(languageCode);
        return VoiceExecutionResult.failure(
          clarification,
          spokenResponse: clarification,
        );
    }
  }

  /// Approved canonical routes in the SmritiCare application.
  /// Any route not defined here or not dynamic (like /placeholder/*) is reported as non-existent.
  static const Set<String> approvedRoutes = {
    '/',
    '/dashboard',
    '/patient-dashboard',
    '/games',
    '/games/memory-match',
    '/games/word-recall',
    '/games/different-object',
    '/games/orientation',
    '/games/routine',
    '/games/family-memories',
    '/take-me-home',
    '/emergency',
    '/assessment',
    '/caregiver-confirm',
    '/language-select',
    '/caregiver-login',
    '/caregiver',
    '/caregiver-dashboard',
    '/role-select',
    '/register',
    '/splash',
  };

  /// Validates whether a target route exists in the application.
  static bool isRouteApproved(String route) {
    if (route == '..' || route == 'pop') return true;
    if (approvedRoutes.contains(route)) return true;
    if (route.startsWith('/placeholder/')) return true;
    if (route.startsWith('/login/')) return true;
    return false;
  }

  Future<VoiceExecutionResult> _executeNavigation(
    VoiceAction action,
    String lang,
  ) async {
    final route = action.payload['targetRoute'] as String? ?? '/dashboard';
    final args = action.payload['arguments'] as Map<String, dynamic>?;

    // Route existence check: if route does not exist, report it instead of inventing a replacement
    if (!isRouteApproved(route)) {
      final errorMsg = "Target route '$route' does not exist in application.";
      final spokenFail = lang == 'hi'
          ? 'माफ़ कीजिए, यह पृष्ठ उपलब्ध नहीं है।'
          : lang == 'as'
              ? 'ক্ষমা কৰিব, এই পৃষ্ঠাখন উপলব্ধ নহয়।'
              : 'Sorry, that screen is not available.';
      return VoiceExecutionResult.failure(errorMsg, spokenResponse: spokenFail);
    }

    if (onNavigate != null) {
      onNavigate!(route, arguments: args);
    }

    final feedback = action.getFeedbackMessage(lang);
    return VoiceExecutionResult.success(
      spokenResponse: feedback,
      navigationRoute: route,
    );
  }

  Future<VoiceExecutionResult> _executeReadReminders(
    VoiceAction action,
    String lang,
  ) async {
    final reminders = CaregiverService.instance.getReminders();
    final active = reminders.where((r) => r.enabled).toList();

    String spoken;
    if (active.isEmpty) {
      switch (lang) {
        case 'hi':
          spoken = 'आज आपके लिए कोई निर्धारित रिमाइंडर नहीं है।';
          break;
        case 'as':
          spoken = 'আজি আপোনাৰ কোনো সোঁৱৰণী নিৰ্ধাৰণ কৰা হোৱা নাই।';
          break;
        case 'en':
        default:
          spoken = 'You have no active reminders scheduled for today.';
      }
    } else {
      final first = active.first;
      switch (lang) {
        case 'hi':
          spoken =
              'आपके पास ${active.length} रिमाइंडर हैं। अगला रिमाइंडर है: ${first.title} ${first.scheduledTime} पर।';
          break;
        case 'as':
          spoken =
              'আপোনাৰ ${active.length} টা সোঁৱৰণী আছে। পৰৱৰ্তী সোঁৱৰণী হৈছে: ${first.title}, সময় ${first.scheduledTime}।';
          break;
        case 'en':
        default:
          spoken =
              'You have ${active.length} reminders. Next reminder is: ${first.title} at ${first.scheduledTime}.';
      }
    }

    // Also navigate to reminders view
    const targetRoute = '/dashboard';
    if (onNavigate != null) {
      onNavigate!(targetRoute, arguments: {'tab': 2});
    }

    return VoiceExecutionResult.success(
      spokenResponse: spoken,
      navigationRoute: targetRoute,
    );
  }

  Future<VoiceExecutionResult> _executeAddReminder(
    VoiceAction action,
    String lang,
  ) async {
    final title = action.payload['title'] as String? ?? 'General Reminder';
    final time = action.payload['time'] as String? ?? '12:00 PM';

    final newReminder = CaregiverReminder(
      id: 'rem-${DateTime.now().millisecondsSinceEpoch}',
      patientId: CaregiverService.instance.selectedPatientId,
      type: 'daily_routine',
      title: title,
      message: 'Reminder for $title',
      scheduledTime: time,
      repeat: 'daily',
      enabled: true,
      status: 'upcoming',
    );

    await CaregiverService.instance.addReminder(newReminder);

    String spoken;
    switch (lang) {
      case 'hi':
        spoken = 'नया रिमाइंडर जोड़ दिया गया है: $title';
        break;
      case 'as':
        spoken = 'নতুন সোঁৱৰণী যোগ কৰা হ’ল: $title';
        break;
      case 'en':
      default:
        spoken = 'Added new reminder: $title';
    }

    return VoiceExecutionResult.success(spokenResponse: spoken);
  }

  Future<VoiceExecutionResult> _executeTriggerEmergency(
    VoiceAction action,
    String lang,
  ) async {
    const route = '/take-me-home';
    if (onNavigate != null) {
      onNavigate!(route);
    }

    final feedback = action.getFeedbackMessage(lang);
    return VoiceExecutionResult.success(
      spokenResponse: feedback,
      navigationRoute: route,
    );
  }

  Future<VoiceExecutionResult> _executeChangeLanguage(
    VoiceAction action,
    String lang,
  ) async {
    final targetLang = action.payload['languageCode'] as String? ?? 'en';
    LocalizationService.instance.setLocale(targetLang);

    final feedback = action.getFeedbackMessage(targetLang);
    return VoiceExecutionResult.success(spokenResponse: feedback);
  }

  Future<VoiceExecutionResult> _executeSpeakStatus(
    VoiceAction action,
    String lang,
  ) async {
    final now = DateTime.now();
    final streak = GameStorageService.instance.getCurrentStreakDays();
    final todayScore = GameStorageService.instance.getTodayScore();

    final timeString =
        '${now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour)}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';

    String spoken;
    switch (lang) {
      case 'hi':
        spoken =
            'वर्तमान समय $timeString है। आपकी निरंतरता $streak दिन और आज का स्कोर $todayScore अंक है।';
        break;
      case 'as':
        spoken =
            'বৰ্তমান সময় $timeString। আপোনাৰ ধাৰাবাহিকতা $streak দিন আৰু আজিৰ স্ক’ৰ $todayScore নম্বৰ।';
        break;
      case 'en':
      default:
        spoken =
            'The time is $timeString. Your streak is $streak days with a score of $todayScore points today.';
    }

    return VoiceExecutionResult.success(spokenResponse: spoken);
  }

  Future<VoiceExecutionResult> _executeSpeakHelp(
    VoiceAction action,
    String lang,
  ) async {
    String spoken;
    switch (lang) {
      case 'hi':
        spoken =
            'आप कह सकते हैं: खेल खेलें, दवाई याद दिलाओ, आपातकालीन सहायता, या मुख्य पृष्ठ पर जाएं।';
        break;
      case 'as':
        spoken =
            'আপুনি ক’ব পাৰে: খেল খেলক, ঔষধৰ সোঁৱৰণী, জৰুৰীকালীন সাহায্য, বা মূল পৃষ্ঠালৈ যাওক।';
        break;
      case 'en':
      default:
        spoken =
            'You can say: play games, check reminders, emergency help, or go to home screen.';
    }

    return VoiceExecutionResult.success(spokenResponse: spoken);
  }

  Future<VoiceExecutionResult> _executeAdaptiveDifficulty(
    VoiceAction action,
    String lang,
  ) async {
    final gameId = action.payload['gameId'] as String? ?? 'memory-match';
    final targetMode = action.payload['mode'] as String? ?? 'easier';

    final currentLvl = GameStorageService.instance.getRecommendedLevel(gameId);
    int nextLevel;
    if (targetMode == 'easier') {
      nextLevel = (currentLvl - 1).clamp(1, 3);
    } else if (targetMode == 'harder') {
      nextLevel = (currentLvl + 1).clamp(1, 3);
    } else {
      nextLevel = currentLvl;
    }

    await GameStorageService.instance.setAdaptiveLevel(gameId, nextLevel);

    String spoken;
    switch (lang) {
      case 'hi':
        spoken = 'खेल को आसान कर दिया गया है। अब स्तर $nextLevel है।';
        break;
      case 'as':
        spoken = 'খেল সহজ কৰা হ’ল। এতিয়া স্তৰ $nextLevel।';
        break;
      case 'en':
      default:
        spoken = 'Adjusted to a gentler difficulty. Now at Level $nextLevel.';
    }

    return VoiceExecutionResult.success(
      spokenResponse: spoken,
      displayMessage: 'Adaptive Difficulty: Level $nextLevel',
    );
  }

  Future<VoiceExecutionResult> _executeReadRoutine(
    VoiceAction action,
    String lang,
  ) async {
    final routineReminders = CaregiverService.instance
        .getReminders(type: 'daily_routine')
        .where((r) => r.enabled)
        .toList();

    String spoken;
    if (routineReminders.isEmpty) {
      // Fallback to general ADL sequence or first upcoming reminder
      final allUpcoming = CaregiverService.instance
          .getReminders()
          .where((r) => r.enabled)
          .toList();
      if (allUpcoming.isNotEmpty) {
        final first = allUpcoming.first;
        switch (lang) {
          case 'hi':
            spoken =
                'आपकी अगली गतिविधि है: ${first.title} ${first.scheduledTime} पर।';
            break;
          case 'as':
            spoken =
                'আপোনাৰ পৰৱৰ্তী কাৰ্য্যসূচী হৈছে: ${first.title}, সময় ${first.scheduledTime}।';
            break;
          case 'en':
          default:
            spoken =
                'Your next routine activity is: ${first.title} at ${first.scheduledTime}.';
        }
      } else {
        switch (lang) {
          case 'hi':
            spoken = 'आज के लिए कोई आगामी दिनचर्या निर्धारित नहीं है।';
            break;
          case 'as':
            spoken = 'আজিৰ বাবে কোনো নিয়ম নিৰ্ধাৰণ কৰা হোৱা নাই।';
            break;
          case 'en':
          default:
            spoken = 'You have completed all planned routine activities for today.';
        }
      }
    } else {
      final first = routineReminders.first;
      switch (lang) {
        case 'hi':
          spoken =
              'आपकी अगली गतिविधि है: ${first.title} ${first.scheduledTime} पर।';
          break;
        case 'as':
          spoken =
              'আপোনাৰ পৰৱৰ্তী কাৰ্য্যসূচী হৈছে: ${first.title}, সময় ${first.scheduledTime}।';
          break;
        case 'en':
        default:
          spoken =
              'Your next routine activity is: ${first.title} at ${first.scheduledTime}.';
      }
    }

    return VoiceExecutionResult.success(
      spokenResponse: spoken,
      displayMessage: spoken,
    );
  }

  /// Resolve a high-level [VoiceIntent] into an executable [VoiceAction].
  VoiceAction resolveAction(VoiceIntent intent, VoiceContext context) {
    final id = 'act-${DateTime.now().millisecondsSinceEpoch}';
    switch (intent.type) {
      case VoiceIntentType.OPEN_HOME:
      case VoiceIntentType.navigate:
        final target = intent.targetRoute ?? '/dashboard';
        return VoiceAction.navigate(
          id: id,
          intent: intent,
          targetRoute: target,
          feedbackMessages: const {
            'en': 'Going to home screen.',
            'hi': 'मुख्य पृष्ठ पर जा रहे हैं।',
            'as': 'মূল পৃষ্ঠালৈ গৈ আছোঁ।',
          },
        );

      case VoiceIntentType.OPEN_GAMES:
      case VoiceIntentType.openGames:
        return VoiceAction.navigate(
          id: id,
          intent: intent,
          targetRoute: '/games',
          feedbackMessages: const {
            'en': 'Opening brain games.',
            'hi': 'दिमागी खेल खोले जा रहे हैं।',
            'as': 'মগজুৰ খেল খোলা হৈছে।',
          },
        );

      case VoiceIntentType.OPEN_MEMORY_GAME:
        return VoiceAction.navigate(
          id: id,
          intent: intent,
          targetRoute: '/games/memory-match',
          feedbackMessages: const {
            'en': 'Starting Memory Match game.',
            'hi': 'स्मरण खेल शुरू किया जा रहा है।',
            'as': 'স্মৰণ খেল আৰম্ভ কৰা হৈছে।',
          },
        );

      case VoiceIntentType.OPEN_WORD_RECALL:
        return VoiceAction.navigate(
          id: id,
          intent: intent,
          targetRoute: '/games/word-recall',
          feedbackMessages: const {
            'en': 'Starting Word Recall game.',
            'hi': 'शब्द स्मरण खेल शुरू किया जा रहा है।',
            'as': 'শব্দ মনত পেলোৱা খেল আৰম্ভ কৰা হৈছে।',
          },
        );

      case VoiceIntentType.OPEN_DIFFERENT_OBJECT:
        return VoiceAction.navigate(
          id: id,
          intent: intent,
          targetRoute: '/games/different-object',
          feedbackMessages: const {
            'en': 'Starting Different Object game.',
            'hi': 'अलग वस्तु खेल शुरू किया जा रहा है।',
            'as': 'পৃথক বস্তু খেল আৰম্ভ কৰা হৈছে।',
          },
        );

      case VoiceIntentType.playGame:
        final gameId = intent.gameId ?? 'memory-match';
        return VoiceAction.navigate(
          id: id,
          intent: intent,
          targetRoute: '/games/$gameId',
          feedbackMessages: {
            'en': 'Starting game.',
            'hi': 'खेल शुरू किया जा रहा है।',
            'as': 'খেল আৰম্ভ কৰা হৈছে।',
          },
        );

      case VoiceIntentType.OPEN_REMINDERS:
      case VoiceIntentType.READ_NEXT_REMINDER:
      case VoiceIntentType.checkReminders:
        return VoiceAction(
          id: id,
          intent: intent,
          type: VoiceActionType.readReminders,
          requiresConfirmation: false,
          payload: {'targetRoute': '/dashboard', 'tab': 2},
        );

      case VoiceIntentType.OPEN_DAILY_ROUTINE:
        return VoiceAction.navigate(
          id: id,
          intent: intent,
          targetRoute: '/games/routine',
          feedbackMessages: const {
            'en': 'Opening your daily routine.',
            'hi': 'आपकी दिनचर्या खोली जा रही है।',
            'as': 'আপোনাৰ দৈনন্দিন নিয়ম খোলা হৈছে।',
          },
        );

      case VoiceIntentType.CALL_CAREGIVER:
        if (intent.slots['targetRoute'] == '/take-me-home') {
          return VoiceAction.emergencySos(
            id: id,
            intent: intent,
          );
        }
        return VoiceAction.callCaregiver(
          id: id,
          intent: intent,
        );

      case VoiceIntentType.emergencySos:
        return VoiceAction.emergencySos(
          id: id,
          intent: intent,
        );

      case VoiceIntentType.takeMeHome:
        return VoiceAction.navigate(
          id: id,
          intent: intent,
          targetRoute: '/take-me-home',
          feedbackMessages: const {
            'en': 'Opening Take Me Home directions.',
            'hi': 'घर जाने का रास्ता खोला जा रहा है।',
            'as': 'ঘৰলৈ যোৱাৰ নিৰ্দেশনা খোলা হৈছে।',
          },
        );

      case VoiceIntentType.CHANGE_LANGUAGE:
      case VoiceIntentType.changeLanguage:
        final code = intent.languageCode ?? 'en';
        return VoiceAction.changeLanguage(
          id: id,
          intent: intent,
          languageCode: code,
        );

      case VoiceIntentType.GO_BACK:
        return VoiceAction.navigate(
          id: id,
          intent: intent,
          targetRoute: '..',
          feedbackMessages: const {
            'en': 'Going back.',
            'hi': 'पीछे जा रहे हैं।',
            'as': 'উভতি গৈ আছোঁ।',
          },
        );

      case VoiceIntentType.openCaregiver:
        return VoiceAction.navigate(
          id: id,
          intent: intent,
          targetRoute: '/caregiver-login',
          feedbackMessages: const {
            'en': 'Opening Caregiver access.',
            'hi': 'देखभालकर्ता पोर्टल खोला जा रहा है।',
            'as': 'তত্ত্বাৱধায়ক প্ৰৱেশদ্বাৰ খোলা হৈছে।',
          },
        );

      case VoiceIntentType.checkStatus:
        return VoiceAction(
          id: id,
          intent: intent,
          type: VoiceActionType.speakStatus,
        );

      case VoiceIntentType.OPEN_HELP:
      case VoiceIntentType.help:
        return VoiceAction(
          id: id,
          intent: intent,
          type: VoiceActionType.speakHelp,
        );

      case VoiceIntentType.addReminder:
        return VoiceAction(
          id: id,
          intent: intent,
          type: VoiceActionType.addReminder,
          payload: intent.slots,
        );

      case VoiceIntentType.CANCEL:
      case VoiceIntentType.cancel:
        return VoiceAction(
          id: id,
          intent: intent,
          type: VoiceActionType.custom,
          feedbackMessages: const {
            'en': 'Action cancelled.',
            'hi': 'कार्य रद्द कर दिया गया है।',
            'as': 'কাৰ্য্য বাতিল কৰা হ’ল।',
          },
        );

      case VoiceIntentType.ADAPTIVE_DIFFICULTY:
        return VoiceAction(
          id: id,
          intent: intent,
          type: VoiceActionType.adaptiveDifficulty,
          payload: {
            'gameId': intent.slots['gameId'] ?? context.currentGame ?? 'memory-match',
            'mode': intent.slots['mode'] ?? 'easier',
          },
        );

      case VoiceIntentType.READ_NEXT_ROUTINE:
        return VoiceAction(
          id: id,
          intent: intent,
          type: VoiceActionType.readRoutine,
        );

      case VoiceIntentType.confirm:
        return VoiceAction(
          id: id,
          intent: intent,
          type: VoiceActionType.custom,
          feedbackMessages: const {
            'en': 'Confirmed.',
            'hi': 'पुष्टि की गई।',
            'as': 'নিশ্চিত কৰা হ’ল।',
          },
        );

      case VoiceIntentType.UNKNOWN:
      case VoiceIntentType.unknown:
        return VoiceAction(
          id: id,
          intent: intent,
          type: VoiceActionType.unknown,
          feedbackMessages: {
            'en': context.buildClarificationMessage('en'),
            'hi': context.buildClarificationMessage('hi'),
            'as': context.buildClarificationMessage('as'),
          },
        );
    }
  }
}
