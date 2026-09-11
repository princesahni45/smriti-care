// lib/services/voice/patterns/intent_patterns_hi.dart
//
// Hindi deterministic voice intent patterns (Devanagari + transliteration) for MindCare NER.

import '../voice_intent_router.dart';
import 'intent_pattern_config.dart';

final List<IntentPatternDefinition> hindiIntentPatterns = [
  // 1. startMemoryGame (More specific than openGames)
  IntentPatternDefinition(
    type: VoiceIntentType.startMemoryGame,
    phrases: [
      'मेमोरी गेम शुरू करो',
      'मेमोरी खेल',
      'याददाश्त वाला खेल',
      'मेमोरी मैच',
      'memory game shuru karo',
      'memory khel',
      'yaddasht khel',
    ],
    patterns: [
      RegExp(r'(मेमोरी|याददाश्त)\s*(गेम|खेल|मैच)', caseSensitive: false),
      RegExp(r'(memory|yaddasht)\s*(game|khel)', caseSensitive: false),
    ],
    confirmationPrompt: 'क्या आप मेमोरी मैच खेल शुरू करना चाहते हैं?',
    executionFeedback: 'मेमोरी मैच खेल शुरू कर रहे हैं।',
    actionRoute: '/games/memory-match',
    requiresConfirmation: false,
  ),

  // 2. openGames
  IntentPatternDefinition(
    type: VoiceIntentType.openGames,
    phrases: [
      'खेल खोलो',
      'गेम दिखाओ',
      'दिमागी खेल',
      'खेलना है',
      'गेम खोलो',
      'khel kholo',
      'game dikhao',
      'dimagi khel',
      'game kholo',
    ],
    patterns: [
      RegExp(r'(खेल|गेम)\s*(खोलो|दिखाओ|शुरू|खोलिए)', caseSensitive: false),
      RegExp(r'(khel|game)\s*(kholo|dikhao)', caseSensitive: false),
    ],
    confirmationPrompt: 'क्या आप दिमागी खेल खोलना चाहते हैं?',
    executionFeedback: 'दिमागी खेल खोल रहे हैं।',
    actionRoute: '/games',
    requiresConfirmation: false,
  ),

  // 3. readNextReminder (More specific than showTodayReminders)
  IntentPatternDefinition(
    type: VoiceIntentType.readNextReminder,
    phrases: [
      'मेरी दवाई कब है',
      'दवाई कब है',
      'दवाई का रिमाइंडर कब है',
      'अगला रिमाइंडर पढ़ो',
      'अगली दवाई कौन सी है',
      'अगला काम क्या है',
      'रिमाइंडर सुनाओ',
      'अगली दवाई',
      'meri dawai kab hai',
      'agla reminder padho',
      'agli dawai',
      'reminder sunao',
    ],
    patterns: [
      RegExp(r'(अगला|अगली|कब\s*है)\s*(रिमाइंडर|दवाई|काम|दवा)',
          caseSensitive: false),
      RegExp(r'(दवाई|दवा)\s*कब\s*है', caseSensitive: false),
      RegExp(r'(agla|agli)\s*(reminder|dawai|kam)', caseSensitive: false),
    ],
    confirmationPrompt: 'क्या आप अगला रिमाइंडर सुनना चाहते हैं?',
    executionFeedback: 'अगला रिमाइंडर सुना रहे हैं।',
    requiresConfirmation: false,
  ),

  // 4. showTodayReminders
  IntentPatternDefinition(
    type: VoiceIntentType.showTodayReminders,
    phrases: [
      'आज मुझे क्या करना है',
      'आज क्या करना है',
      'आज की दिनचर्या',
      'आज के रिमाइंडर दिखाओ',
      'रिमाइंडर दिखाओ',
      'दवाई का समय',
      'आज के रिमाइंडर',
      'aaj mujhe kya karna hai',
      'aaj ke reminder dikhao',
      'reminder dikhao',
      'dawai ka samay',
    ],
    patterns: [
      RegExp(r'(आज|दिनचर्या)\s*(क्या\s*करना|दिखाओ|बताओ|शेड्यूल)',
          caseSensitive: false),
      RegExp(r'(रिमाइंडर|दवाई|दवा)\s*(दिखाओ|बताओ|खोलो)', caseSensitive: false),
      RegExp(r'\b(aaj|reminder|dawai)\s*(karna|dikhao|batao)\b',
          caseSensitive: false),
    ],
    confirmationPrompt: 'क्या आप आज के रिमाइंडर देखना चाहते हैं?',
    executionFeedback: 'आज के रिमाइंडर खोल रहे हैं।',
    actionRoute: '/reminders',
    requiresConfirmation: false,
  ),

  // 5. repeatInstruction
  IntentPatternDefinition(
    type: VoiceIntentType.repeatInstruction,
    phrases: [
      'फिर से बोलो',
      'दोहराओ',
      'क्या कहा आपने',
      'फिर से सुनाओ',
      'पुनः बताओ',
      'phir se bolo',
      'dohrao',
      'kya kaha aapne',
      'phir se sunao',
    ],
    patterns: [
      RegExp(r'(फिर\s*से|दोबारा|पुनः)\s*(बोलो|सुनाओ|बताओ)',
          caseSensitive: false),
      RegExp(r'(phir\s*se|dobara)\s*(bolo|sunao)', caseSensitive: false),
    ],
    confirmationPrompt: 'क्या आप पिछली बात फिर से सुनना चाहते हैं?',
    executionFeedback: 'पिछली बात दोहरा रहे हैं।',
    requiresConfirmation: false,
  ),

  // 6. openCaregiverHelp
  IntentPatternDefinition(
    type: VoiceIntentType.openCaregiverHelp,
    phrases: [
      'देखभालकर्ता को बुलाओ',
      'मदद चाहिए',
      'सहायता',
      'केयरगिवर को फोन करो',
      'मदद करो',
      'डॉक्टर को बुलाओ',
      'madad chahiye',
      'sahayata',
      'caregiver ko phone karo',
      'madad karo',
    ],
    patterns: [
      RegExp(r'(मदद|सहायता|केयरगिवर|डॉक्टर)\s*(चाहिए|करो|बुलाओ|फोन)?',
          caseSensitive: false),
      RegExp(r'(madad|sahayata|caregiver|doctor)', caseSensitive: false),
    ],
    confirmationPrompt:
        'क्या आपको तत्काल सहायता चाहिए या देखभालकर्ता से संपर्क करना है?',
    executionFeedback: 'देखभालकर्ता सहायता से जोड़ रहे हैं।',
    actionRoute: '/caregiver-help',
    requiresConfirmation: true, // Dementia safety: confirmation required
  ),

  // 7. openSettings
  IntentPatternDefinition(
    type: VoiceIntentType.openSettings,
    phrases: [
      'सेटिंग्स खोलो',
      'भाषा बदलो',
      'सेटिंग दिखाओ',
      'settings kholo',
      'bhasha badlo',
      'setting dikhao',
    ],
    patterns: [
      RegExp(r'(सेटिंग्स?|भाषा)\s*(खोलो|बदलो|दिखाओ)', caseSensitive: false),
      RegExp(r'(settings?|bhasha)\s*(kholo|badlo)', caseSensitive: false),
    ],
    confirmationPrompt: 'क्या आप सेटिंग्स खोलना चाहते हैं?',
    executionFeedback: 'सेटिंग्स खोल रहे हैं।',
    actionRoute: '/settings',
    requiresConfirmation: false,
  ),

  // 8. goHome
  IntentPatternDefinition(
    type: VoiceIntentType.goHome,
    phrases: [
      'घर जाओ',
      'होम स्क्रीन',
      'मुख्य पृष्ठ',
      'डैशबोर्ड',
      'घर चलो',
      'ghar jao',
      'home screen',
      'dashboard',
      'ghar chalo',
    ],
    patterns: [
      RegExp(r'(घर\s*जाओ|घर\s*चलो|मुख्य\s*पृष्ठ|होम\s*स्क्रीन)',
          caseSensitive: false),
      RegExp(r'(ghar\s*jao|ghar\s*chalo|home\s*screen)', caseSensitive: false),
    ],
    confirmationPrompt: 'क्या आप मुख्य पृष्ठ पर वापस जाना चाहते हैं?',
    executionFeedback: 'मुख्य पृष्ठ पर वापस जा रहे हैं।',
    actionRoute: '/patient/dashboard',
    requiresConfirmation: true, // Dementia safety: confirmation required
  ),

  // 9. cancel
  IntentPatternDefinition(
    type: VoiceIntentType.cancel,
    phrases: [
      'रद्द करो',
      'बंद करो',
      'कैंसिल',
      'छोड़ो',
      'radd karo',
      'band karo',
      'cancel',
      'chhodo',
    ],
    patterns: [
      RegExp(r'(रद्द\s*करो|बंद\s*करो|कैंसिल|छोड़ो)', caseSensitive: false),
      RegExp(r'(radd\s*karo|band\s*karo|cancel|chhodo)', caseSensitive: false),
    ],
    confirmationPrompt: 'क्या आप इसे रद्द करना चाहते हैं?',
    executionFeedback: 'सहायक बंद कर दिया गया।',
    requiresConfirmation: true,
  ),
];
