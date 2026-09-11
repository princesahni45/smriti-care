// lib/services/voice/patterns/intent_patterns_en.dart
//
// English deterministic voice intent patterns for MindCare NER.

import '../voice_intent_router.dart';
import 'intent_pattern_config.dart';

final List<IntentPatternDefinition> englishIntentPatterns = [
  // 1. startMemoryGame (More specific than openGames)
  IntentPatternDefinition(
    type: VoiceIntentType.startMemoryGame,
    phrases: [
      'start a memory game',
      'start memory game',
      'memory match',
      'play memory game',
      'memory card game',
      'card matching',
      'start memory',
    ],
    patterns: [
      RegExp(
          r'\b(start|play|launch)\s+(the\s+|a\s+)?(memory\s+game|memory\s+match|memory\s+activity)\b',
          caseSensitive: false),
    ],
    confirmationPrompt: 'Would you like to start the Memory Match game?',
    executionFeedback: 'Starting Memory Match.',
    actionRoute: '/games/memory-match',
    requiresConfirmation: false,
  ),

  // 2. openGames
  IntentPatternDefinition(
    type: VoiceIntentType.openGames,
    phrases: [
      'open games',
      'show games',
      'brain games',
      'play games',
      'i want to play',
      'games screen',
      'game menu',
    ],
    patterns: [
      RegExp(r'\b(open|show|play)\s+(the\s+)?(games?|brain\s+games?)\b',
          caseSensitive: false),
    ],
    confirmationPrompt: 'Would you like to open Brain Games?',
    executionFeedback: 'Opening Brain Games.',
    actionRoute: '/games',
    requiresConfirmation: false,
  ),

  // 3. readNextReminder (More specific than showTodayReminders)
  IntentPatternDefinition(
    type: VoiceIntentType.readNextReminder,
    phrases: [
      'when is my medicine reminder',
      'when is my medicine',
      'next medicine reminder',
      'read next reminder',
      'what is my next reminder',
      'next medicine',
      'what should i do next',
      'read reminder',
      'tell me next reminder',
      'next task',
    ],
    patterns: [
      RegExp(
          r'\b(read|tell\s+me|what\s+is|when\s+is)\s+(my\s+|the\s+)?(next\s+)?(reminder|medicine|task|dose|medicine\s+reminder)\b',
          caseSensitive: false),
      RegExp(r'\bwhen\s+is\s+my\s+medicine\b', caseSensitive: false),
    ],
    confirmationPrompt: 'Would you like me to read your next reminder?',
    executionFeedback: 'Reading your next reminder.',
    requiresConfirmation: false,
  ),

  // 4. showTodayReminders
  IntentPatternDefinition(
    type: VoiceIntentType.showTodayReminders,
    phrases: [
      'what should i do today',
      'what to do today',
      'today routine',
      'today schedule',
      'show today reminders',
      'show reminders',
      'what are my reminders',
      'my schedule',
      'today reminders',
      'show my reminders',
      'show my medicine reminder',
      'medicine reminder',
      'view reminders',
      'medicine schedule',
    ],
    patterns: [
      RegExp(
          r'\b(show|view|open|see|check)\s+(my\s+|the\s+)?(today\s+|daily\s+|medicine\s+)?reminders?\b',
          caseSensitive: false),
      RegExp(r'\bwhat\s+are\s+my\s+reminders\b', caseSensitive: false),
      RegExp(r'\bwhat\s+(should\s+i|to)\s+do\s+today\b', caseSensitive: false),
      RegExp(r'\b(today\s+routine|today\s+schedule|daily\s+routine)\b',
          caseSensitive: false),
    ],
    confirmationPrompt: 'Would you like to view your reminders for today?',
    executionFeedback: 'Opening today reminders.',
    actionRoute: '/reminders',
    requiresConfirmation: false,
  ),

  // 5. repeatInstruction
  IntentPatternDefinition(
    type: VoiceIntentType.repeatInstruction,
    phrases: [
      'repeat instruction',
      'repeat',
      'say that again',
      'what did you say',
      'listen again',
      'repeat again',
      'pardon',
      'say again',
    ],
    patterns: [
      RegExp(
          r'\b(repeat|say\s+again|say\s+that\s+again|hear\s+again|listen\s+again)\b',
          caseSensitive: false),
    ],
    confirmationPrompt: 'Would you like me to repeat the last instruction?',
    executionFeedback: 'Repeating the last instruction.',
    requiresConfirmation: false,
  ),

  // 6. openCaregiverHelp
  IntentPatternDefinition(
    type: VoiceIntentType.openCaregiverHelp,
    phrases: [
      'open caregiver help',
      'call caregiver',
      'help me',
      'i need help',
      'caregiver help',
      'emergency help',
      'sos',
      'call doctor',
      'i am lost',
      'need assistance',
    ],
    patterns: [
      RegExp(
          r'\b(help|sos|emergency|call\s+caregiver|contact\s+caregiver|call\s+doctor|i\s+am\s+lost)\b',
          caseSensitive: false),
    ],
    confirmationPrompt:
        'Do you need immediate help or want to contact your caregiver?',
    executionFeedback: 'Connecting you with caregiver assistance.',
    actionRoute: '/caregiver-help',
    requiresConfirmation:
        true, // Dementia safety: requires explicit confirmation
  ),

  // 7. openSettings
  IntentPatternDefinition(
    type: VoiceIntentType.openSettings,
    phrases: [
      'open settings',
      'settings',
      'change language',
      'app settings',
      'preferences',
      'configuration',
    ],
    patterns: [
      RegExp(r'\b(open|show|go\s+to)\s+(app\s+)?(settings?|preferences?)\b',
          caseSensitive: false),
      RegExp(r'\b(change|switch)\s+language\b', caseSensitive: false),
    ],
    confirmationPrompt: 'Would you like to open Settings?',
    executionFeedback: 'Opening Settings.',
    actionRoute: '/settings',
    requiresConfirmation: false,
  ),

  // 8. goHome
  IntentPatternDefinition(
    type: VoiceIntentType.goHome,
    phrases: [
      'go home',
      'take me home',
      'main screen',
      'dashboard',
      'back to home',
      'home screen',
      'return home',
    ],
    patterns: [
      RegExp(
          r'\b(go\s+home|take\s+me\s+home|return\s+home|home\s+screen|main\s+screen|back\s+home)\b',
          caseSensitive: false),
    ],
    confirmationPrompt: 'Would you like to go back to the Home Dashboard?',
    executionFeedback: 'Returning to Home Dashboard.',
    actionRoute: '/patient/dashboard',
    requiresConfirmation: true, // Dementia safety: navigation confirm
  ),

  // 9. cancel
  IntentPatternDefinition(
    type: VoiceIntentType.cancel,
    phrases: [
      'cancel',
      'stop',
      'never mind',
      'close',
      'exit voice',
      'dismiss',
      'stop listening',
    ],
    patterns: [
      RegExp(
          r'\b(cancel|never\s+mind|close|dismiss|exit\s+voice|stop\s+listening)\b',
          caseSensitive: false),
    ],
    confirmationPrompt: 'Would you like to cancel this action?',
    executionFeedback: 'Voice assistant closed.',
    requiresConfirmation: true,
  ),
];
