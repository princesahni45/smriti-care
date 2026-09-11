// lib/core/voice/voice_context.dart
//
// Represents the contextual state when a voice command is evaluated.

import 'voice_action.dart';
import '../localization/app_localizations.dart';

/// Encapsulates the active UI route, screen, patient profile, game state, and available actions.
class VoiceContext {
  /// The active route path (e.g., '/', '/dashboard', '/games', '/reminders').
  final String currentRoute;

  /// The active screen name (e.g., 'home', 'games_hub', 'reminders', 'memory_match').
  final String currentScreen;

  /// The active patient or profile identifier.
  final String? selectedPatient;

  /// The selected voice / interaction language ('en', 'hi', 'as', etc.).
  final String selectedLanguage;

  /// Current game where applicable (e.g., 'memory-match', 'word-recall', 'different-object').
  final String? currentGame;

  /// Current game state where applicable (e.g., 'idle', 'playing', 'paused', 'completed').
  final String? currentGameState;

  /// Available actions or intents supported on the current screen.
  final List<String> availableActions;

  /// Whether the patient has an upcoming or due reminder in the current session.
  final bool hasUpcomingReminder;

  /// A pending action awaiting user confirmation, if any.
  final VoiceAction? pendingAction;

  /// Arbitrary context metadata (e.g. visible reminders count, scores).
  final Map<String, dynamic> metadata;

  /// Computes default approved actions for a given screen/route context if not explicitly provided.
  static List<String> computeAvailableActions({
    required String currentRoute,
    String? currentScreen,
    String? currentGame,
  }) {
    final route = currentRoute.toLowerCase();
    final screen = (currentScreen ?? '').toLowerCase();

    // Memory match or specific games
    if (currentGame == 'memory-match' || route.contains('memory-match') || screen.contains('memory_match')) {
      return const [
        'ADAPTIVE_DIFFICULTY',
        'MAKE_EASIER',
        'MAKE_HARDER',
        'OPEN_GAMES',
        'OPEN_HOME',
        'GO_BACK',
        'CANCEL',
      ];
    }
    if (currentGame != null || route.startsWith('/games/')) {
      return const [
        'ADAPTIVE_DIFFICULTY',
        'OPEN_GAMES',
        'OPEN_HOME',
        'GO_BACK',
        'CANCEL',
      ];
    }
    // Games hub
    if (route == '/games' || screen == 'games' || screen == 'games_hub') {
      return const [
        'START_SELECTED_GAME',
        'OPEN_MEMORY_GAME',
        'OPEN_WORD_RECALL',
        'OPEN_DIFFERENT_OBJECT',
        'OPEN_DAILY_ROUTINE',
        'OPEN_HOME',
        'GO_BACK',
        'CANCEL',
      ];
    }
    // Reminders
    if (route.contains('reminder') || screen == 'reminders') {
      return const [
        'READ_NEXT_REMINDER',
        'OPEN_REMINDERS',
        'OPEN_DAILY_ROUTINE',
        'OPEN_GAMES',
        'OPEN_HOME',
        'GO_BACK',
        'CANCEL',
      ];
    }
    // Daily Routine
    if (route.contains('routine') || screen == 'routine' || screen == 'daily_routine') {
      return const [
        'READ_NEXT_ROUTINE',
        'OPEN_DAILY_ROUTINE',
        'READ_NEXT_REMINDER',
        'OPEN_GAMES',
        'OPEN_HOME',
        'GO_BACK',
        'CANCEL',
      ];
    }
    // Home / Patient Dashboard
    if (route == '/' || route == '/dashboard' || route == '/patient-dashboard' || screen == 'home') {
      return const [
        'OPEN_GAMES',
        'OPEN_REMINDERS',
        'READ_NEXT_REMINDER',
        'OPEN_DAILY_ROUTINE',
        'OPEN_HOME',
        'CALL_CAREGIVER',
        'CHANGE_LANGUAGE',
        'OPEN_HELP',
        'CANCEL',
      ];
    }

    // Default global safe actions
    return const [
      'OPEN_HOME',
      'OPEN_GAMES',
      'OPEN_REMINDERS',
      'CALL_CAREGIVER',
      'OPEN_HELP',
      'GO_BACK',
      'CANCEL',
    ];
  }

  const VoiceContext({
    this.currentRoute = '/',
    this.currentScreen = 'home',
    this.selectedPatient,
    String? activeLanguageCode,
    String? selectedLanguage,
    this.currentGame,
    this.currentGameState,
    List<String>? availableActions,
    this.hasUpcomingReminder = false,
    this.pendingAction,
    String? patientName,
    this.metadata = const {},
  })  : selectedLanguage = selectedLanguage ?? activeLanguageCode ?? 'en',
        availableActions = availableActions ??
            const [];

  /// Backward-compatible alias for [selectedLanguage].
  String get activeLanguageCode => selectedLanguage;

  /// Backward-compatible alias for [selectedPatient].
  String? get patientName => selectedPatient;

  /// Alias for profile lookup.
  String? get selectedProfile => selectedPatient;

  /// Returns effective available actions (computed from route if empty).
  List<String> get effectiveAvailableActions {
    if (availableActions.isNotEmpty) return availableActions;
    return computeAvailableActions(
      currentRoute: currentRoute,
      currentScreen: currentScreen,
      currentGame: currentGame,
    );
  }

  /// True if waiting for the user to confirm or cancel a sensitive action.
  bool get hasPendingConfirmation => pendingAction != null;

  /// True if user is inside Memory Match game.
  bool get isMemoryMatchScreen =>
      currentGame == 'memory-match' ||
      currentRoute.contains('memory-match') ||
      currentScreen.contains('memory_match');

  /// True if user is inside Daily Routine game or screen.
  bool get isDailyRoutineScreen =>
      currentGame == 'routine' ||
      currentRoute.contains('/games/routine') ||
      currentRoute.contains('routine') ||
      currentScreen == 'routine' ||
      currentScreen == 'daily_routine' ||
      (metadata['tab'] == 'routine');

  /// True if the user is currently on the Games hub or any game screen.
  bool get isGamesScreen =>
      currentScreen == 'games' ||
      currentScreen == 'games_hub' ||
      currentRoute == '/games' ||
      currentRoute.startsWith('/games') ||
      currentGame != null;

  /// True if user is specifically on the Games hub list (not inside a specific game).
  bool get isGamesHubScreen =>
      (currentRoute == '/games' ||
          currentScreen == 'games' ||
          currentScreen == 'games_hub') &&
      !currentRoute.startsWith('/games/') &&
      currentGame == null;

  /// True if user is on the Reminders screen or tab.
  bool get isRemindersScreen =>
      currentScreen == 'reminders' ||
      currentRoute.contains('reminder') ||
      (metadata['activeTab'] == 'reminders') ||
      (metadata['activeTab'] == 2);

  /// True if user is on the Emergency SOS or Take Me Home screen.
  bool get isEmergencyScreen =>
      currentScreen == 'emergency' ||
      currentRoute.contains('emergency') ||
      currentRoute.contains('take-me-home');

  /// True if user is on the Home / Dashboard screen.
  bool get isHomeScreen =>
      currentScreen == 'home' ||
      currentRoute == '/' ||
      currentRoute == '/dashboard' ||
      currentRoute == '/patient-dashboard';

  /// True if user is on the Caregiver portal.
  bool get isCaregiverScreen =>
      currentScreen == 'caregiver' || currentRoute.contains('caregiver');

  /// Generates a simple, non-hallucinated clarification question listing only actions
  /// available on the current screen.
  String buildClarificationMessage([String? langCode]) {
    final lang = langCode ?? selectedLanguage;
    final actions = effectiveAvailableActions;

    if (isGamesScreen) {
      return LocalizationService.instance.tr(
        'voice.clarification.gamesScreen',
        defaultText: lang == 'hi'
            ? 'आप खेल शुरू कर सकते हैं, या मुख्य पृष्ठ पर जा सकते हैं। आप क्या करना चाहेंगे?'
            : (lang == 'as'
                ? 'আপুনি খেল আৰম্ভ কৰিব পাৰে, বা মূল পৃষ্ঠালৈ যাব পাৰে। আপুনি কি কৰিব বিচাৰে?'
                : 'You can start a game, or go to home screen. What would you like to do?'),
      );
    }
    if (isRemindersScreen) {
      return LocalizationService.instance.tr(
        'voice.clarification.remindersScreen',
        defaultText: lang == 'hi'
            ? 'आप अपना अगला रिमाइंडर सुन सकते हैं, या मुख्य पृष्ठ पर जा सकते हैं। आप क्या करना चाहेंगे?'
            : (lang == 'as'
                ? 'আপুনি আপোনাৰ পৰৱৰ্তী সোঁৱৰণী শুনিব পাৰে, বা মূল পৃষ্ঠালৈ যাব পাৰে। আপুনি কি কৰিব বিচাৰে?'
                : 'You can listen to your next reminder, or go to home screen. What would you like to do?'),
      );
    }
    if (isDailyRoutineScreen) {
      return LocalizationService.instance.tr(
        'voice.clarification.routineScreen',
        defaultText: lang == 'hi'
            ? 'आप अपनी अगली गतिविधि जान सकते हैं, या मुख्य पृष्ठ पर जा सकते हैं। आप क्या करना चाहेंगे?'
            : (lang == 'as'
                ? 'আপুনি পৰৱৰ্তী কাৰ্য্যসূচী জানিব পাৰে, বা মূল পৃষ্ঠালৈ যাব পাৰে। আপুনি কি কৰিব বিচাৰে?'
                : 'You can check your next routine activity, or go to home screen. What would you like to do?'),
      );
    }

    switch (lang) {
      case 'hi':
        return 'माफ़ कीजिए, मैं समझ नहीं पाया। आप खेल, रिमाइंडर, या मुख्य पृष्ठ चुन सकते हैं।';
      case 'as':
        return 'ক্ষমা কৰিব, মই বুজি নাপালোঁ। আপুনি খেল, সোঁৱৰণী বা মূল পৃষ্ঠা বাছি ল’ব পাৰে।';
      case 'en':
      default:
        final prefix = LocalizationService.instance.tr(
          'voice.clarification.general',
          defaultText: 'I could not find that action here. On this screen you can:',
        );
        return '$prefix ${_formatActionsForPrompt(actions)}.';
    }
  }

  static String _formatActionsForPrompt(List<String> actions) {
    final readable = actions.map((a) {
      switch (a) {
        case 'START_SELECTED_GAME':
          return 'start game';
        case 'ADAPTIVE_DIFFICULTY':
        case 'MAKE_EASIER':
          return 'adjust difficulty';
        case 'READ_NEXT_REMINDER':
          return 'check next reminder';
        case 'READ_NEXT_ROUTINE':
          return 'check next routine activity';
        case 'OPEN_GAMES':
          return 'open games';
        case 'OPEN_HOME':
          return 'go home';
        case 'CALL_CAREGIVER':
          return 'call caregiver';
        default:
          return a.toLowerCase().replaceAll('_', ' ');
      }
    }).toSet().take(3).join(', ');
    return readable.isNotEmpty ? readable : 'go home or open games';
  }

  VoiceContext copyWith({
    String? currentRoute,
    String? currentScreen,
    String? selectedPatient,
    String? activeLanguageCode,
    String? selectedLanguage,
    String? currentGame,
    String? currentGameState,
    List<String>? availableActions,
    bool? hasUpcomingReminder,
    VoiceAction? pendingAction,
    bool clearPendingAction = false,
    String? patientName,
    Map<String, dynamic>? metadata,
  }) {
    return VoiceContext(
      currentRoute: currentRoute ?? this.currentRoute,
      currentScreen: currentScreen ?? this.currentScreen,
      selectedPatient: selectedPatient ?? patientName ?? this.selectedPatient,
      selectedLanguage: selectedLanguage ?? activeLanguageCode ?? this.selectedLanguage,
      currentGame: currentGame ?? this.currentGame,
      currentGameState: currentGameState ?? this.currentGameState,
      availableActions: availableActions ?? this.availableActions,
      hasUpcomingReminder: hasUpcomingReminder ?? this.hasUpcomingReminder,
      pendingAction:
          clearPendingAction ? null : (pendingAction ?? this.pendingAction),
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() =>
      'VoiceContext(route: $currentRoute, screen: $currentScreen, lang: $selectedLanguage, game: $currentGame)';
}
