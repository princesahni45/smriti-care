// lib/services/voice/patterns/intent_patterns_as.dart
//
// Assamese deterministic voice intent patterns (Assamese script + transliteration) for MindCare NER.

import '../voice_intent_router.dart';
import 'intent_pattern_config.dart';

final List<IntentPatternDefinition> assameseIntentPatterns = [
  // 1. startMemoryGame (More specific than openGames)
  IntentPatternDefinition(
    type: VoiceIntentType.startMemoryGame,
    phrases: [
      'মেমৰি খেল আৰম্ভ কৰক',
      'স্মৃতি খেল',
      'কাৰ্ড মেচ',
      'memory khel arombho korok',
      'smriti khel',
    ],
    patterns: [
      RegExp(r'(মেমৰি|স্মৃতি|কাৰ্ড)\s*(খেল|মেচ|আৰম্ভ)', caseSensitive: false),
      RegExp(r'(memory|smriti)\s*(khel)', caseSensitive: false),
    ],
    confirmationPrompt: 'আপুনি স্মৃতি খেল আৰম্ভ কৰিব বিচাৰে নেকি?',
    executionFeedback: 'স্মৃতি খেল আৰম্ভ কৰা হৈছে।',
    actionRoute: '/games/memory-match',
    requiresConfirmation: false,
  ),

  // 2. openGames
  IntentPatternDefinition(
    type: VoiceIntentType.openGames,
    phrases: [
      'খেল খোলক',
      'খেল দেখুৱাওক',
      'খেল খেলিম',
      'গেম খোলক',
      'khel kholok',
      'khel dekhuwaok',
      'khel khelim',
    ],
    patterns: [
      RegExp(r'(খেল|গেম)\s*(খোলক|দেখুৱাওক|খেলিম|আৰম্ভ)', caseSensitive: false),
      RegExp(r'(khel|game)\s*(kholok|dekhuwaok)', caseSensitive: false),
    ],
    confirmationPrompt: 'আপুনি খেল খোলিব বিচাৰে নেকি?',
    executionFeedback: 'খেল খোলি থকা হৈছে।',
    actionRoute: '/games',
    requiresConfirmation: false,
  ),

  // 3. readNextReminder (More specific than showTodayReminders)
  IntentPatternDefinition(
    type: VoiceIntentType.readNextReminder,
    phrases: [
      'মোৰ ঔষধৰ সময় কেতিয়া',
      'ঔষধ কেতিয়া খাব লাগে',
      'পৰৱৰ্তী ৰিমাইণ্ডাৰ পঢ়ক',
      'পৰৱৰ্তী ঔষধ কি',
      'পৰৱৰ্তী কাম কি',
      'পৰৱৰ্তী ৰিমাইণ্ডাৰ',
      'poroborti reminder porhok',
      'poroborti osodh ki',
      'osodhor xomoy ketiya',
    ],
    patterns: [
      RegExp(r'(পৰৱৰ্তী|কেতিয়া|সময়)\s*(ৰিমাইণ্ডাৰ|ঔষধ|কাম|দৰব)',
          caseSensitive: false),
      RegExp(r'(poroborti|next|ketiya)\s*(reminder|osodh)',
          caseSensitive: false),
    ],
    confirmationPrompt: 'আপুনি পৰৱৰ্তী ৰিমাইণ্ডাৰ শুনিব বিচাৰে নেকি?',
    executionFeedback: 'পৰৱৰ্তী ৰিমাইণ্ডাৰ পঢ়ি থকা হৈছে।',
    requiresConfirmation: false,
  ),

  // 4. showTodayReminders
  IntentPatternDefinition(
    type: VoiceIntentType.showTodayReminders,
    phrases: [
      'আজি মই কি কৰিম',
      'আজি কি কৰিব লাগে',
      'আজিৰ দিনলিপি',
      'আজিৰ ৰিমাইণ্ডাৰ দেখুৱাওক',
      'ৰিমাইণ্ডাৰ দেখুৱাওক',
      'ঔষধৰ সময়',
      'আজিৰ কাম',
      'aji moi ki korim',
      'ajir reminder dekhuwaok',
      'reminder dekhuwaok',
      'osodhor xomoy',
    ],
    patterns: [
      RegExp(r'(আজি|দিনলিপি)\s*(কি\s*কৰিম|দেখুৱাওক|কাম|ৰিমাইণ্ডাৰ)',
          caseSensitive: false),
      RegExp(r'(ৰিমাইণ্ডাৰ|ঔষধৰ\s*সময়|আজিৰ\s*কাম)\s*(দেখুৱাওক|খোলক)?',
          caseSensitive: false),
      RegExp(r'\b(aji|reminder|osodh)\s*(korim|dekhuwaok)\b',
          caseSensitive: false),
    ],
    confirmationPrompt: 'আপুনি আজিৰ ৰিমাইণ্ডাৰ চাব বিচাৰে নেকি?',
    executionFeedback: 'আজিৰ ৰিমাইণ্ডাৰ দেখুওৱা হৈছে।',
    actionRoute: '/reminders',
    requiresConfirmation: false,
  ),

  // 5. repeatInstruction
  IntentPatternDefinition(
    type: VoiceIntentType.repeatInstruction,
    phrases: [
      'আকৌ কওক',
      'পুনৰ কওক',
      'কি ক’লে',
      'আকৌ শুনাওক',
      'akou kouk',
      'punor kouk',
      'ki kole',
    ],
    patterns: [
      RegExp(r'(আকৌ|পুনৰ)\s*(কওক|শুনাওক|ক’লে)', caseSensitive: false),
      RegExp(r'(akou|punor)\s*(kouk|sunauk)', caseSensitive: false),
    ],
    confirmationPrompt: 'আপুনি শেষৰ কথাষাৰ আকৌ শুনিব বিচাৰে নেকি?',
    executionFeedback: 'শেষৰ কথাষাৰ পুনৰ কোৱা হৈছে।',
    requiresConfirmation: false,
  ),

  // 6. openCaregiverHelp
  IntentPatternDefinition(
    type: VoiceIntentType.openCaregiverHelp,
    phrases: [
      'কেয়াৰগিভাৰক মাটক',
      'সহায় লাগে',
      'সহায় কৰক',
      'মোক সহায় কৰক',
      'ডাক্তৰক মাটক',
      'caregiverok matok',
      'xohay lage',
      'xohay korok',
      'mok sahay korok',
    ],
    patterns: [
      RegExp(r'(সহায়|কেয়াৰগিভাৰক?|ডাক্তৰক?)\s*(লাগে|কৰক|মাটক)?',
          caseSensitive: false),
      RegExp(r'(sahay|xohay|caregiver|doctor)', caseSensitive: false),
    ],
    confirmationPrompt:
        'আপোনাক তৎক্ষণাৎ সহায় লাগে নে কেয়াৰগিভাৰৰ লগত যোগাযোগ কৰিব বিচাৰে?',
    executionFeedback: 'কেয়াৰগিভাৰৰ সৈতে সংযোগ কৰা হৈছে।',
    actionRoute: '/caregiver-help',
    requiresConfirmation: true, // Dementia safety: confirmation required
  ),

  // 7. openSettings
  IntentPatternDefinition(
    type: VoiceIntentType.openSettings,
    phrases: [
      'ছেটিংছ খোলক',
      'ভাষা সলনি কৰক',
      'ছেটিংছ',
      'settings kholok',
      'bhasa xoloni korok',
    ],
    patterns: [
      RegExp(r'(ছেটিংছ|ভাষা)\s*(খোলক|সলনি\s*কৰক)?', caseSensitive: false),
      RegExp(r'(settings?|bhasa)\s*(kholok|xoloni)', caseSensitive: false),
    ],
    confirmationPrompt: 'আপুনি ছেটিংছ খোলিব বিচাৰে নেকি?',
    executionFeedback: 'ছেটিংছ খোলি থকা হৈছে।',
    actionRoute: '/settings',
    requiresConfirmation: false,
  ),

  // 8. goHome
  IntentPatternDefinition(
    type: VoiceIntentType.goHome,
    phrases: [
      'ঘৰলৈ যাওক',
      'হোম স্ক্ৰীন',
      'মূল পৃষ্ঠা',
      'ডেশ্ববৰ্ড',
      'ghoroloi jaok',
      'home screen',
      'dashboard',
    ],
    patterns: [
      RegExp(r'(ঘৰলৈ\s*যাওক|হোম\s*স্ক্ৰীন|মূল\s*পৃষ্ঠা|ডেশ্ববৰ্ড)',
          caseSensitive: false),
      RegExp(r'(ghoroloi\s*jaok|home\s*screen)', caseSensitive: false),
    ],
    confirmationPrompt: 'আপুনি মূল পৃষ্ঠালৈ উভতি যাব বিচাৰে নেকি?',
    executionFeedback: 'মূল পৃষ্ঠালৈ উভতি যোৱা হৈছে।',
    actionRoute: '/patient/dashboard',
    requiresConfirmation: true, // Dementia safety: confirmation required
  ),

  // 9. cancel
  IntentPatternDefinition(
    type: VoiceIntentType.cancel,
    phrases: [
      'বাতিল কৰক',
      'বন্ধ কৰক',
      'নালাগে',
      'batil korok',
      'bondho korok',
      'nalage',
    ],
    patterns: [
      RegExp(r'(বাতিল\s*কৰক|বন্ধ\s*কৰক|নালাগে)', caseSensitive: false),
      RegExp(r'(batil\s*korok|bondho\s*korok|nalage)', caseSensitive: false),
    ],
    confirmationPrompt: 'আপুনি এইটো বাতিল কৰিব বিচাৰে নেকি?',
    executionFeedback: 'সহায়ক বন্ধ কৰা হ’ল।',
    requiresConfirmation: true,
  ),
];
