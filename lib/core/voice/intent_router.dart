// lib/core/voice/intent_router.dart
//
// Multilingual Intent Router for SmritiCare Voice Assistant.
// Supports:
// - English, Hindi (Devanagari + Hinglish), and Assamese (Assamese script + Romanized).
// - Screen-aware context disambiguation.
// - Sensitive action confirmation token classification.
// - Pluggable future local Qwen SLM integration with zero fake AI.

import 'voice_command.dart';
import 'voice_intent.dart';
import 'voice_context.dart';
import '../ai/ai.dart';

/// Abstract contract for intent classification engines.
abstract class IntentClassifier {
  /// Classify a user command in the context of the active screen and conversation.
  Future<VoiceIntent> classify(VoiceCommand command, VoiceContext context);
}

/// Pluggable interface for future on-device Qwen (e.g. Qwen-2.5-0.5B / 1.5B via GGUF/ONNX).
///
/// NOTE: The repository does NOT currently bundle local Qwen weights.
/// This implementation integrates with [LocalQwenService] and returns
/// [isModelLoaded] = false until physical local SLM weights are installed on disk.
class LocalQwenIntentClassifier implements IntentClassifier {
  final LocalQwenService _qwenService;

  LocalQwenIntentClassifier({
    String? modelPath,
    LocalQwenService? qwenService,
  }) : _qwenService = qwenService ?? LocalQwenService(modelPath: modelPath);

  /// Path to model weights if configured.
  String? get modelPath => _qwenService.modelPath;

  /// Returns true only when a local Qwen model binary has been validated on disk.
  bool get isModelLoaded => _qwenService.isModelInstalled;

  @override
  Future<VoiceIntent> classify(
      VoiceCommand command, VoiceContext context) async {
    if (!_qwenService.isModelInstalled) {
      // Graceful pass-through when local Qwen is not bundled.
      return VoiceIntent.unknown(command.text);
    }

    final aiContext = AiContextBuilder.buildContext(context);
    final result = await _qwenService.inferIntent(
      prompt: command.text,
      context: aiContext,
    );

    if (result.isSuccess && result.mappedIntent != null) {
      return result.mappedIntent!;
    }
    return VoiceIntent.unknown(command.text);
  }
}

/// Deterministic, multilingual rule-based intent router.
/// Handles natural variations across English, Hindi, and Assamese.
/// Supports optional fallback to an on-device [AiService] for complex/unknown commands.
class DeterministicIntentRouter implements IntentClassifier {
  final AiService? fallbackAiService;

  const DeterministicIntentRouter({this.fallbackAiService});

  @override
  Future<VoiceIntent> classify(
      VoiceCommand command, VoiceContext context) async {
    final text = command.normalizedText;

    if (text.isEmpty) {
      return VoiceIntent.unknown('');
    }

    // ── 1. CONFIRMATION WORKFLOW HANDLING ─────────────────────────────────
    // When the assistant is waiting for user confirmation on a sensitive action
    if (context.hasPendingConfirmation) {
      if (_matchesCancellation(text)) {
        return VoiceIntent.cancel(text);
      }
      if (_matchesAffirmation(text)) {
        return VoiceIntent.confirm(text);
      }
    }

    // ── 2. CANCELLATION DIRECT COMMAND ────────────────────────────────────
    if (_matchesCancellation(text)) {
      return VoiceIntent(
        type: VoiceIntentType.CANCEL,
        confidence: 0.95,
        matchedPhrase: text,
        isSensitive: false,
      );
    }

    // ── 3. GO BACK NAVIGATION ─────────────────────────────────────────────
    if (_matchesGoBack(text)) {
      return VoiceIntent(
        type: VoiceIntentType.GO_BACK,
        confidence: 0.95,
        matchedPhrase: text,
        isSensitive: false,
      );
    }

    // ── 4. EMERGENCY SOS (High Severity Emergency) ───────────────────────
    if (_matchesEmergency(text)) {
      return VoiceIntent(
        type: VoiceIntentType.CALL_CAREGIVER,
        confidence: 0.98,
        matchedPhrase: text,
        isSensitive: true,
        slots: const {'targetRoute': '/take-me-home'},
      );
    }

    // ── 5. HELP & ASSISTANT CAPABILITIES ─────────────────────────────────
    if (_matchesHelp(text)) {
      return VoiceIntent(
        type: VoiceIntentType.OPEN_HELP,
        confidence: 0.90,
        matchedPhrase: text,
        isSensitive: false,
      );
    }

    // ── 6. CAREGIVER CALL / ASSISTANCE ───────────────────────────────────
    if (_matchesEmergencyOrCaregiver(text)) {
      return VoiceIntent(
        type: VoiceIntentType.CALL_CAREGIVER,
        confidence: 0.95,
        matchedPhrase: text,
        isSensitive: true,
        slots: const {'targetRoute': '/caregiver-confirm'},
      );
    }

    // ── 5. TAKE ME HOME / RETURN HOME ─────────────────────────────────────
    if (_matchesTakeMeHome(text)) {
      return VoiceIntent(
        type: VoiceIntentType.OPEN_HOME,
        confidence: 0.95,
        matchedPhrase: text,
        isSensitive: false,
        slots: const {'targetRoute': '/take-me-home'},
      );
    }

    // ── 6. WHAT SHOULD I DO / WHAT'S NEXT / NEXT ACTIVITY ─────────────────
    if (_matchesNextActivity(text)) {
      return VoiceIntent(
        type: VoiceIntentType.READ_NEXT_ROUTINE,
        confidence: 0.95,
        matchedPhrase: text,
        slots: const {'targetRoute': '/dashboard', 'tab': 'routine'},
      );
    }

    if (_matchesWhatShouldIDo(text) || _matchesWhatsNext(text)) {
      // If user is on daily routine screen:
      if (context.isDailyRoutineScreen) {
        return VoiceIntent(
          type: VoiceIntentType.READ_NEXT_ROUTINE,
          confidence: 0.95,
          matchedPhrase: text,
          slots: const {'targetRoute': '/dashboard', 'tab': 'routine'},
        );
      }
      // If patient has an upcoming reminder, or is on reminders screen, or availableActions contains reminder:
      if (context.isRemindersScreen ||
          context.hasUpcomingReminder ||
          context.availableActions.contains('READ_NEXT_REMINDER')) {
        return VoiceIntent(
          type: VoiceIntentType.READ_NEXT_REMINDER,
          confidence: 0.94,
          matchedPhrase: text,
          slots: const {'targetRoute': '/dashboard', 'tab': 'reminders'},
        );
      } else {
        return VoiceIntent(
          type: VoiceIntentType.OPEN_DAILY_ROUTINE,
          confidence: 0.92,
          matchedPhrase: text,
          slots: const {'targetRoute': '/dashboard', 'tab': 'routine'},
        );
      }
    }

    // ── 7. ADAPTIVE DIFFICULTY ("Make it easier", "Make it harder") ─────────
    if (_matchesMakeEasier(text)) {
      if (context.isGamesScreen ||
          context.currentGame != null ||
          context.currentRoute.contains('games/')) {
        final gameId = context.currentGame ??
            (context.isMemoryMatchScreen ? 'memory-match' : 'memory-match');
        return VoiceIntent(
          type: VoiceIntentType.ADAPTIVE_DIFFICULTY,
          confidence: 0.95,
          matchedPhrase: text,
          isSensitive: false,
          slots: {
            'mode': 'easier',
            'gameId': gameId,
          },
        );
      } else {
        // Unavailable on non-game screens; do not guess or hallucinate
        return VoiceIntent.unknown(text);
      }
    }

    if (_matchesMakeHarder(text)) {
      if (context.isGamesScreen ||
          context.currentGame != null ||
          context.currentRoute.contains('games/')) {
        final gameId = context.currentGame ??
            (context.isMemoryMatchScreen ? 'memory-match' : 'memory-match');
        return VoiceIntent(
          type: VoiceIntentType.ADAPTIVE_DIFFICULTY,
          confidence: 0.95,
          matchedPhrase: text,
          isSensitive: false,
          slots: {
            'mode': 'harder',
            'gameId': gameId,
          },
        );
      } else {
        return VoiceIntent.unknown(text);
      }
    }

    // ── 8. LANGUAGE SWITCHING ─────────────────────────────────────────────
    final langSlot = _detectLanguageSwitch(text);
    if (langSlot != null) {
      return VoiceIntent(
        type: VoiceIntentType.CHANGE_LANGUAGE,
        confidence: 0.95,
        matchedPhrase: text,
        isSensitive: false,
        slots: {'languageCode': langSlot},
      );
    }

    // ── 9. SPECIFIC COGNITIVE GAMES ───────────────────────────────────────
    final gameType = _detectSpecificGameType(text);
    if (gameType != null) {
      return VoiceIntent(
        type: gameType,
        confidence: 0.94,
        matchedPhrase: text,
        isSensitive: false,
        slots: {
          'gameId': _gameIdForType(gameType),
          'targetRoute': '/games/${_gameIdForType(gameType)}',
        },
      );
    }

    // ── 10. CONTEXT-DRIVEN SCREEN HEURISTICS ("Start this" / "Play") ───────
    // If user is already on Games screen:
    if (context.isGamesScreen) {
      if (text.contains('start') ||
          text.contains('play') ||
          text.contains('this') ||
          text.contains('ise') ||
          text.contains('isko') ||
          text.contains('shuru') ||
          text.contains('khelo') ||
          text.contains('arombho')) {
        final activeGame = context.currentGame ?? 'memory-match';
        VoiceIntentType targetType = VoiceIntentType.OPEN_MEMORY_GAME;
        if (activeGame == 'word-recall') {
          targetType = VoiceIntentType.OPEN_WORD_RECALL;
        } else if (activeGame == 'different-object') {
          targetType = VoiceIntentType.OPEN_DIFFERENT_OBJECT;
        }
        return VoiceIntent(
          type: targetType,
          confidence: 0.92,
          matchedPhrase: text,
          slots: {
            'gameId': activeGame,
            'targetRoute': '/games/$activeGame',
          },
        );
      }
    }

    // ── 10. DAILY ROUTINE ─────────────────────────────────────────────────
    if (_matchesDailyRoutine(text)) {
      return VoiceIntent(
        type: VoiceIntentType.OPEN_DAILY_ROUTINE,
        confidence: 0.92,
        matchedPhrase: text,
        isSensitive: false,
        slots: const {'targetRoute': '/dashboard', 'tab': 'routine'},
      );
    }

    // ── 11. READ NEXT REMINDER SPECIFIC COMMAND ───────────────────────────
    if (_matchesReadNextReminder(text)) {
      return VoiceIntent(
        type: VoiceIntentType.READ_NEXT_REMINDER,
        confidence: 0.94,
        matchedPhrase: text,
        isSensitive: false,
        slots: const {'targetRoute': '/dashboard', 'tab': 'reminders'},
      );
    }

    // ── 12. REMINDERS SCREEN ──────────────────────────────────────────────
    if (_matchesReminders(text)) {
      return VoiceIntent(
        type: VoiceIntentType.OPEN_REMINDERS,
        confidence: 0.92,
        matchedPhrase: text,
        isSensitive: false,
        slots: const {'targetRoute': '/dashboard', 'tab': 'reminders'},
      );
    }

    // ── 13. GAMES HUB NAVIGATION ──────────────────────────────────────────
    if (_matchesGamesHub(text)) {
      return VoiceIntent(
        type: VoiceIntentType.OPEN_GAMES,
        confidence: 0.92,
        matchedPhrase: text,
        isSensitive: false,
        slots: const {'targetRoute': '/games'},
      );
    }

    // ── 14. HOME / DASHBOARD ──────────────────────────────────────────────
    if (_matchesHome(text)) {
      return VoiceIntent(
        type: VoiceIntentType.OPEN_HOME,
        confidence: 0.95,
        matchedPhrase: text,
        isSensitive: false,
        slots: const {'targetRoute': '/dashboard'},
      );
    }

    // ── 15. CAREGIVER ACCESS ──────────────────────────────────────────────
    if (_matchesCaregiver(text)) {
      return VoiceIntent(
        type: VoiceIntentType.CALL_CAREGIVER,
        confidence: 0.90,
        matchedPhrase: text,
        isSensitive: true,
        slots: const {'targetRoute': '/caregiver-login'},
      );
    }

    // ── 16. TIME / DATE / STATUS CHECK ────────────────────────────────────
    if (_matchesStatus(text)) {
      return VoiceIntent(
        type: VoiceIntentType.checkStatus,
        confidence: 0.90,
        matchedPhrase: text,
        isSensitive: false,
      );
    }

    // ── 17. HELP & ASSISTANT CAPABILITIES ─────────────────────────────────
    if (_matchesHelp(text)) {
      return VoiceIntent(
        type: VoiceIntentType.OPEN_HELP,
        confidence: 0.90,
        matchedPhrase: text,
        isSensitive: false,
      );
    }

    // Ambiguous commands produce UNKNOWN, or optionally attempt local fallback SLM if available
    if (fallbackAiService != null && fallbackAiService!.isAvailable) {
      final aiContext = AiContextBuilder.buildContext(context);
      final aiResult = await fallbackAiService!.inferIntent(
        prompt: command.text,
        context: aiContext,
      );
      if (aiResult.isSuccess && aiResult.mappedIntent != null) {
        return aiResult.mappedIntent!;
      }
    }

    return VoiceIntent.unknown(text);
  }

  // ── KEYWORD & PATTERN MATCHERS (EN, HI, AS) ─────────────────────────────

  bool _matchesAffirmation(String t) {
    const tokens = [
      // English
      'yes', 'yeah', 'yep', 'sure', 'ok', 'okay', 'confirm', 'proceed',
      'correct', 'right',
      // Hindi
      'हाँ', 'हां', 'सही', 'ठीक', 'पक्का', 'हाँ करो', 'हाँ जी', 'haan', 'ha',
      'sahi', 'thik', 'pakka', 'karo', 'kar do',
      // Assamese
      'হয়', 'হ’ব', 'বাৰু', 'ঠিক আছে', 'কৰক', 'নিশ্চয়', 'hoy', 'hobo', 'baru',
      'thik ase', 'thik asey', 'korok',
    ];
    return tokens
        .any((k) => t == k || t.startsWith('$k ') || t.endsWith(' $k'));
  }

  bool _matchesCancellation(String t) {
    const tokens = [
      // English
      'no', 'nope', 'cancel', 'stop', 'don\'t', 'never', 'abort', 'dismiss',
      // Hindi
      'नहीं', 'ना', 'मत', 'रोको', 'रद्द', 'रद्द करो', 'रुक', 'nahi', 'nahin',
      'na', 'mat karo', 'roko', 'radd',
      // Assamese
      'নহয়', 'নালাগে', 'বন্ধ কৰক', 'নকৰিব', 'ৰওক', 'nahoi', 'nalage',
      'bondho korok', 'nakoribo', 'ro-ok',
    ];
    return tokens
        .any((k) => t == k || t.startsWith('$k ') || t.endsWith(' $k'));
  }

  bool _matchesGoBack(String t) {
    if (t.contains('home') ||
        t.contains('dashboard') ||
        t.contains('games') ||
        t.contains('reminder') ||
        t.contains('routine')) {
      return false;
    }
    const tokens = [
      // English
      'go back', 'back', 'previous', 'return', 'previous screen',
      // Hindi
      'वापस जाओ', 'पीछे जाओ', 'पीछे चलो', 'वापस चलो', 'वापस', 'पीछे',
      'wapas jao', 'wapas', 'peeche jao', 'piche',
      // Assamese
      'উভতি যাওক', 'পিছলৈ যাওক', 'পিচলৈ', 'উভতি',
      'ubhoti jaok', 'pisot jaok', 'pisoloi',
    ];
    return tokens.any((k) => t == k || t.contains(k));
  }

  bool _matchesEmergencyOrCaregiver(String t) {
    const tokens = [
      // English
      'sos', 'emergency', 'help me', 'save me', 'call doctor', 'call ambulance',
      'call emergency', 'call caregiver', 'call my caregiver', 'alert caregiver',
      'contact caregiver', 'call guardian',
      // Hindi
      'मदद', 'सहायता', 'बचाओ', 'आपातकाल', 'डॉक्टर को बुलाओ', 'एम्बुलेंस',
      'केयरगिवर को बुलाओ', 'देखभालकर्ता को बुलाओ', 'देखभालकर्ता', 'फोन करो',
      'madad', 'bachao', 'sahayata', 'aapatkal', 'caregiver ko bulao',
      'call caregiver',
      // Assamese
      'সাহায্য', 'বাঁচাও', 'জৰুৰীকালীন', 'সহায়', 'মোক বচাওক', 'ডাক্তৰক মাতক',
      'তত্ত্বাৱধায়কক মাতক', 'কেয়াৰগিভাৰক ফোন কৰক', 'অভিভাৱকক মাতক',
      'sahajyo', 'bochao', 'jorurikalin', 'tattwabadhayakok matok',
    ];
    return tokens.any((k) => t.contains(k));
  }

  bool _matchesWhatShouldIDo(String t) {
    const tokens = [
      // English
      'what should i do now', 'what do i do now', 'what should i do',
      'what next', 'what to do next', 'what is next', 'what am i doing now',
      'what do i do',
      // Hindi
      'अब क्या करूँ', 'अब क्या करना है', 'अब मैं क्या करूँ', 'आगे क्या है',
      'मुझे क्या करना चाहिए', 'ab kya karu', 'ab kya karna hai', 'kya karu ab',
      // Assamese
      'এতিয়া কি কৰিম', 'এতিয়া কি কৰিম', 'এতিয়া কি কৰিব লাগে', 'পৰৱৰ্তী কি',
      'মই এতিয়া কি কৰিম', 'etia ki korim', 'etia ki koribo lage',
    ];
    return tokens.any((k) => t.contains(k));
  }

  bool _matchesWhatsNext(String t) {
    const tokens = [
      // English
      "what's next", 'what is next', 'what next', 'whats next', 'next please',
      // Hindi
      'आगे क्या है', 'अगला क्या है', 'अगला बताओ', 'aage kya hai', 'agla kya hai',
      // Assamese
      'পৰৱৰ্তী কি', 'ইয়াৰ পিছত কি', 'পিছৰটো কি', 'poroborti ki', 'pisor ki',
    ];
    return tokens.any((k) => t == k || t.contains(k));
  }

  bool _matchesNextActivity(String t) {
    const tokens = [
      // English
      "what's my next activity", 'what is my next activity', 'next activity',
      'whats my next activity', 'next routine activity', 'upcoming activity',
      'my next activity',
      // Hindi
      'अगली गतिविधि', 'अगला काम', 'मेरी अगली गतिविधि', 'अगली गतिविधि क्या है',
      'agli gatividhi', 'agli gatividhi kya hai', 'mera agla kaam',
      // Assamese
      'পৰৱৰ্তী কাৰ্য্যসূচী', 'পৰৱৰ্তী কাৰ্য', 'পৰৱৰ্তী কাম', 'মোৰ পৰৱৰ্তী কাম',
      'poroborti karjyoxusi', 'poroborti kaam',
    ];
    return tokens.any((k) => t.contains(k));
  }

  bool _matchesMakeEasier(String t) {
    const tokens = [
      // English
      'make it easier', 'easier', 'decrease difficulty', 'too hard',
      'make it gentler', 'level down', 'lower difficulty', 'easy mode',
      'make easier', 'easy please',
      // Hindi
      'आसान करो', 'सरल करो', 'मुश्किल है', 'बहुत कठिन है', 'कठिनाई कम करो',
      'aasan karo', 'saral karo', 'mushkil hai', 'kam karo', 'aasan kar do',
      // Assamese
      'সহজ কৰক', 'টান হৈছে', 'অসুবিধা কম কৰক', 'sohoj korok', 'tan hoise',
      'kom korok', 'সহজ কৰি দিয়ক',
    ];
    return tokens.any((k) => t.contains(k));
  }

  bool _matchesMakeHarder(String t) {
    const tokens = [
      // English
      'make it harder', 'harder', 'increase difficulty', 'too easy',
      'level up', 'higher difficulty', 'make harder',
      // Hindi
      'कठिन करो', 'मुश्किल करो', 'बहुत आसान है', 'कठिनाई बढ़ाओ',
      'kathin karo', 'mushkil karo', 'badhao',
      // Assamese
      'টান কৰক', 'কঠিন কৰক', 'বেছি সহজ', 'tan korok',
    ];
    return tokens.any((k) => t.contains(k));
  }

  VoiceIntentType? _detectSpecificGameType(String t) {
    // Memory Match
    if (t.contains('memory') ||
        t.contains('match') ||
        t.contains('card') ||
        t.contains('ताश') ||
        t.contains('स्मरण') ||
        t.contains('smaran') ||
        t.contains('স্মৰণ') ||
        t.contains('জোৰা মিলোৱা')) {
      return VoiceIntentType.OPEN_MEMORY_GAME;
    }
    // Word Recall
    if (t.contains('word') ||
        t.contains('recall') ||
        t.contains('शब्द') ||
        t.contains('shabd') ||
        t.contains('শব্দ') ||
        t.contains('শব্দ মনত পেলোৱা')) {
      return VoiceIntentType.OPEN_WORD_RECALL;
    }
    // Different Object / Odd One Out
    if (t.contains('different') ||
        t.contains('odd') ||
        t.contains('अलग') ||
        t.contains('alag') ||
        t.contains('আছুতীয়া') ||
        t.contains('পৃথক বস্তু')) {
      return VoiceIntentType.OPEN_DIFFERENT_OBJECT;
    }
    return null;
  }

  String _gameIdForType(VoiceIntentType type) {
    switch (type) {
      case VoiceIntentType.OPEN_MEMORY_GAME:
        return 'memory-match';
      case VoiceIntentType.OPEN_WORD_RECALL:
        return 'word-recall';
      case VoiceIntentType.OPEN_DIFFERENT_OBJECT:
        return 'different-object';
      default:
        return 'memory-match';
    }
  }

  bool _matchesDailyRoutine(String t) {
    const tokens = [
      // English
      'daily routine', 'my routine', 'open routine', 'today routine',
      'routine schedule', 'view routine',
      // Hindi
      'दिनचर्या', 'मेरी दिनचर्या', 'आज की दिनचर्या', 'नियम', 'dincharya',
      'meri dincharya',
      // Assamese
      'দৈনন্দিন নিয়ম', 'দৈনন্দিন ক্ৰম', 'মোৰ নিয়ম', 'দুটিন', 'doynondin',
    ];
    return tokens.any((k) => t.contains(k));
  }

  bool _matchesReadNextReminder(String t) {
    const tokens = [
      // English
      'read next reminder', 'next reminder', 'upcoming reminder',
      'next medicine', 'next pill', 'what is my next reminder',
      'read my reminder', 'read reminder',
      // Hindi
      'अगला रिमाइंडर बताओ', 'अगली दवाई कब है', 'अगला रिमाइंडर',
      'अगली दवाई', 'agla reminder', 'agli dawai',
      // Assamese
      'পৰৱৰ্তী সোঁৱৰণী কওক', 'পৰৱৰ্তী ঔষধ', 'পৰৱৰ্তী সোঁৱৰণী',
      'poroborti xuworoni', 'poroborti dorob',
    ];
    return tokens.any((k) => t.contains(k));
  }

  bool _matchesEmergency(String t) {
    // If the user explicitly asks for instructions, guide, or what to say, it's Help, not Emergency
    if (t.contains('instruction') ||
        t.contains('निर्देश') ||
        t.contains('নিৰ্দেশ') ||
        t.contains('what can i say') ||
        t.contains('what to say') ||
        t.contains('how to use') ||
        t.contains('क्या बोलूँ') ||
        t.contains('কি ক’ব')) {
      return false;
    }
    const tokens = [
      // English
      'sos', 'emergency', 'help me', 'save me', 'call doctor', 'call ambulance',
      'call emergency',
      // Hindi
      'मदद', 'सहायता', 'बचाओ', 'आपातकाल', 'डॉक्टर को बुलाओ', 'एम्बुलेंस',
      'madad', 'bachao', 'sahayata', 'aapatkal',
      // Assamese
      'সাহায্য', 'বাঁচাও', 'জৰুৰীকালীন', 'সহায়', 'মোক বচাওক', 'ডাক্তৰক মাতক',
      'sahajyo', 'bochao', 'jorurikalin',
    ];
    return tokens.any((k) => t.contains(k));
  }

  bool _matchesTakeMeHome(String t) {
    const tokens = [
      // English
      'take me home', 'go home', 'lost', 'where am i', 'find home',
      'directions home', 'way home',
      // Hindi
      'घर ले चलो', 'घर जाना है', 'रास्ता बताओ', 'खो गया हूँ', 'खो गई हूँ', 'घर',
      'ghar le chalo', 'ghar jana hai', 'kho gaya',
      // Assamese
      'ঘৰলৈ লৈ যাওক', 'ঘৰলৈ যাব লাগে', 'মই হেৰাই গ’লোঁ', 'ঘৰৰ ঠিকনা',
      'ghoroloi loi jaok', 'ghoroloi jabo lage', 'herai golo',
    ];
    return tokens.any((k) => t.contains(k));
  }

  String? _detectLanguageSwitch(String t) {
    // Assamese
    if (t.contains('assamese') ||
        t.contains('অসমীয়া') ||
        t.contains('oxomiya') ||
        t.contains('asomiya')) {
      return 'as';
    }
    // Hindi
    if (t.contains('hindi') || t.contains('हिन्दी') || t.contains('हिंदी')) {
      return 'hi';
    }
    // English
    if (t.contains('english') ||
        t.contains('अंग्रेजी') ||
        t.contains('इंग्लिश') ||
        t.contains('ইংৰাজী')) {
      return 'en';
    }
    return null;
  }



  bool _matchesGamesHub(String t) {
    const tokens = [
      // English
      'game', 'games', 'play', 'play game', 'brain game', 'exercises',
      'show my games', 'show games', 'view games', 'my games', 'open games',
      // Hindi
      'खेल', 'खेलना', 'दिमागी खेल', 'गेम', 'khel', 'khelna', 'games',
      'मेरे खेल दिखाओ', 'खेल दिखाओ', 'गेम दिखाओ',
      // Assamese
      'খেল', 'খেল-ধেমালি', 'মগজুৰ খেল', 'khel', 'khel dhemali',
      'মোৰ খেল দেখুৱাওক', 'খেল দেখুৱাওক',
    ];
    return tokens.any((k) => t.contains(k));
  }

  bool _matchesReminders(String t) {
    const tokens = [
      // English
      'reminder', 'reminders', 'medicine', 'medicines', 'pill', 'pills',
      'water', 'hydration', 'schedule',
      // Hindi
      'दवाई', 'दवा', 'गोली', 'रिमाइंडर', 'पानी', 'समय', 'dawai', 'goli', 'pani',
      'reminder',
      // Assamese
      'ঔষধ', 'দৰব', 'সোঁৱৰণী', 'পানী', 'oukhodh', 'dorob', 'pani', 'xuworoni',
    ];
    return tokens.any((k) => t.contains(k));
  }

  bool _matchesHome(String t) {
    const tokens = [
      // English
      'home', 'main menu', 'dashboard', 'start screen',
      // Hindi
      'होम', 'मुख्य पृष्ठ', 'डैशबोर्ड', 'ghar', 'mukhya',
      // Assamese
      'মূল পৃষ্ঠা', 'মেইন স্ক্ৰীন', 'ঘৰ', 'ghor',
    ];
    return tokens.any((k) => t.contains(k));
  }

  bool _matchesCaregiver(String t) {
    const tokens = [
      // English
      'caregiver', 'doctor', 'nurse', 'guardian', 'care portal',
      // Hindi
      'देखभालकर्ता', 'केयरगिवर', 'तत्ववेत्ता', 'डॉक्टर', 'caregiver',
      // Assamese
      'তত্ত্বাৱধায়ক', 'অভিভাৱক', 'কেয়াৰগিভাৰ', 'tattwabadhayak',
    ];
    return tokens.any((k) => t.contains(k));
  }

  bool _matchesStatus(String t) {
    const tokens = [
      // English
      'what time', 'what date', 'what day', 'today date', 'my score', 'streak',
      // Hindi
      'समय क्या है', 'आज क्या तारीख है', 'आज क्या दिन है', 'स्कोर',
      'kya time hai', 'aaj kya din hai',
      // Assamese
      'কিমান বাজিছে', 'আজি কি দিন', 'আজি কি তাৰিখ', 'মোৰ স্ক’ৰ', 'kiman bajise',
      'aaji ki din',
    ];
    return tokens.any((k) => t.contains(k));
  }

  bool _matchesHelp(String t) {
    const tokens = [
      // English
      'help', 'what can i say', 'how to use', 'commands', 'instructions',
      // Hindi
      'मदद करो', 'क्या बोलूँ', 'निर्देश', 'kya bol sakte hain',
      // Assamese
      'সহায়', 'কি ক’ব পাৰি', 'নিৰ্দেশনা', 'ki kobo pari',
    ];
    return tokens.any((k) => t.contains(k));
  }
}

/// Hybrid router combining Local Qwen SLM (if model file loaded) with deterministic fallback.
class HybridIntentRouter implements IntentClassifier {
  final LocalQwenIntentClassifier qwenClassifier;
  final DeterministicIntentRouter deterministicRouter;

  HybridIntentRouter({
    LocalQwenIntentClassifier? qwenClassifier,
    DeterministicIntentRouter? deterministicRouter,
  })  : qwenClassifier = qwenClassifier ?? LocalQwenIntentClassifier(),
        deterministicRouter =
            deterministicRouter ?? const DeterministicIntentRouter();

  @override
  Future<VoiceIntent> classify(
      VoiceCommand command, VoiceContext context) async {
    // 1. If local Qwen model is bundled and active, consult it first
    if (qwenClassifier.isModelLoaded) {
      try {
        final qwenIntent = await qwenClassifier.classify(command, context);
        if (qwenIntent.type != VoiceIntentType.unknown &&
            qwenIntent.confidence >= 0.75) {
          return qwenIntent;
        }
      } catch (e) {
        // Fall back gracefully to deterministic rule-based router
      }
    }

    // 2. Reliable deterministic multilingual fallback
    return deterministicRouter.classify(command, context);
  }
}
