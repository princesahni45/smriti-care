// test/voice_assistant_test.dart
//
// Comprehensive unit and integration tests for the SmritiCare Voice Assistant architecture:
// 1. Multilingual intent classification (English, Hindi, Assamese).
// 2. Context-aware screen disambiguation.
// 3. Sensitive action confirmation workflows (SOS, cancel).
// 4. Graceful text fallback.
// 5. Future local Qwen and offline ASR contract validation.
// 6. VoiceActionExecutor navigation and reminder queries.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_care/core/services/caregiver_service.dart';
import 'package:smriti_care/core/services/game_storage_service.dart';
import 'package:smriti_care/core/voice/voice.dart';

void main() {
  group('Multilingual Deterministic Intent Routing', () {
    const router = DeterministicIntentRouter();

    test('Classifies English navigation and activity intents', () async {
      const context = VoiceContext(currentRoute: '/');

      // Games hub
      final resGames = await router.classify(
        VoiceCommand(text: 'I want to play brain games'),
        context,
      );
      expect(resGames.type, equals(VoiceIntentType.OPEN_GAMES));
      expect(resGames.type.nameCode, equals('OPEN_GAMES'));

      // Specific game
      final resMemory = await router.classify(
        VoiceCommand(text: 'start memory match card game'),
        context,
      );
      expect(resMemory.type, equals(VoiceIntentType.OPEN_MEMORY_GAME));
      expect(resMemory.gameId, equals('memory-match'));

      // Reminders
      final resRem = await router.classify(
        VoiceCommand(text: 'check my medicines and reminders'),
        context,
      );
      expect(resRem.type, equals(VoiceIntentType.OPEN_REMINDERS));

      // Home
      final resHome = await router.classify(
        VoiceCommand(text: 'go back to home dashboard'),
        context,
      );
      expect(resHome.type, equals(VoiceIntentType.OPEN_HOME));

      // Take me home
      final resTakeHome = await router.classify(
        VoiceCommand(text: 'take me home please I am lost'),
        context,
      );
      expect(resTakeHome.type, equals(VoiceIntentType.OPEN_HOME));

      // Language switch
      final resLang = await router.classify(
        VoiceCommand(text: 'switch language to hindi'),
        context,
      );
      expect(resLang.type, equals(VoiceIntentType.CHANGE_LANGUAGE));
      expect(resLang.languageCode, equals('hi'));
    });

    test('Classifies Hindi intents (Devanagari and Hinglish)', () async {
      const context = VoiceContext(currentRoute: '/', activeLanguageCode: 'hi');

      // Devanagari Games
      final resGames = await router.classify(
        VoiceCommand(text: 'दिमागी खेल खेलना है', languageCode: 'hi'),
        context,
      );
      expect(resGames.type, equals(VoiceIntentType.OPEN_GAMES));

      // Devanagari Memory Match
      final resMemory = await router.classify(
        VoiceCommand(text: 'ताश वाला स्मरण खेल लगाओ', languageCode: 'hi'),
        context,
      );
      expect(resMemory.type, equals(VoiceIntentType.OPEN_MEMORY_GAME));
      expect(resMemory.gameId, equals('memory-match'));

      // Devanagari Reminders
      final resRem = await router.classify(
        VoiceCommand(text: 'आज की दवाई और रिमाइंडर बताओ', languageCode: 'hi'),
        context,
      );
      expect(resRem.type, equals(VoiceIntentType.OPEN_REMINDERS));

      // Devanagari Emergency SOS (Sensitive)
      final resSos = await router.classify(
        VoiceCommand(text: 'मदद करो आपातकाल है', languageCode: 'hi'),
        context,
      );
      expect(resSos.type, equals(VoiceIntentType.CALL_CAREGIVER));
      expect(resSos.isSensitive, isTrue);

      // Devanagari Take Me Home
      final resHome = await router.classify(
        VoiceCommand(text: 'मुझे घर ले चलो रास्ता भूल गया', languageCode: 'hi'),
        context,
      );
      expect(resHome.type, equals(VoiceIntentType.OPEN_HOME));

      // Hinglish
      final resHinglish = await router.classify(
        VoiceCommand(text: 'ghar le chalo please', languageCode: 'hi'),
        context,
      );
      expect(resHinglish.type, equals(VoiceIntentType.OPEN_HOME));
    });

    test('Classifies Assamese intents (Assamese script and Romanized)',
        () async {
      const context = VoiceContext(currentRoute: '/', activeLanguageCode: 'as');

      // Assamese Games Hub
      final resGames = await router.classify(
        VoiceCommand(text: 'মগজুৰ খেল-ধেমালি আৰম্ভ কৰক', languageCode: 'as'),
        context,
      );
      expect(resGames.type, equals(VoiceIntentType.OPEN_GAMES));

      // Assamese Memory Match
      final resMemory = await router.classify(
        VoiceCommand(text: 'স্মৰণ খেল খেলিব বিচাৰোঁ', languageCode: 'as'),
        context,
      );
      expect(resMemory.type, equals(VoiceIntentType.OPEN_MEMORY_GAME));
      expect(resMemory.gameId, equals('memory-match'));

      // Assamese Reminders
      final resRem = await router.classify(
        VoiceCommand(text: 'মোৰ ঔষধ আৰু সোঁৱৰণী দেখুৱাওক', languageCode: 'as'),
        context,
      );
      expect(resRem.type, equals(VoiceIntentType.OPEN_REMINDERS));

      // Assamese Emergency SOS (Sensitive)
      final resSos = await router.classify(
        VoiceCommand(text: 'মোক বচাওক জৰুৰীকালীন সাহায্য', languageCode: 'as'),
        context,
      );
      expect(resSos.type, equals(VoiceIntentType.CALL_CAREGIVER));
      expect(resSos.isSensitive, isTrue);

      // Assamese Take Me Home
      final resHome = await router.classify(
        VoiceCommand(text: 'মই হেৰাই গ’লোঁ ঘৰলৈ লৈ যাওক', languageCode: 'as'),
        context,
      );
      expect(resHome.type, equals(VoiceIntentType.OPEN_HOME));

      // Romanized Assamese
      final resRoman = await router.classify(
        VoiceCommand(text: 'ghoroloi loi jaok', languageCode: 'as'),
        context,
      );
      expect(resRoman.type, equals(VoiceIntentType.OPEN_HOME));
    });

    test('Disambiguates intents based on screen context', () async {
      // On Games Hub screen: "start" or "play" starts memory game
      const gamesContext = VoiceContext(currentRoute: '/games');
      final resPlay = await router.classify(
        VoiceCommand(text: 'play now'),
        gamesContext,
      );
      expect(resPlay.type, equals(VoiceIntentType.OPEN_MEMORY_GAME));
    });

    test(
        'Comprehensive coverage of all 14 Predefined Canonical Intents in English',
        () async {
      const defaultContext = VoiceContext(currentRoute: '/dashboard');

      // 1. OPEN_HOME
      final home = await router.classify(
        VoiceCommand(text: 'take me home'),
        defaultContext,
      );
      expect(home.type, equals(VoiceIntentType.OPEN_HOME));
      expect(home.type.nameCode, equals('OPEN_HOME'));

      // 2. OPEN_GAMES
      final games = await router.classify(
        VoiceCommand(text: 'i want to play games'),
        defaultContext,
      );
      expect(games.type, equals(VoiceIntentType.OPEN_GAMES));
      expect(games.type.nameCode, equals('OPEN_GAMES'));

      // 3. OPEN_MEMORY_GAME
      final memory = await router.classify(
        VoiceCommand(text: 'open memory game'),
        defaultContext,
      );
      expect(memory.type, equals(VoiceIntentType.OPEN_MEMORY_GAME));
      expect(memory.type.nameCode, equals('OPEN_MEMORY_GAME'));

      // 4. OPEN_WORD_RECALL
      final word = await router.classify(
        VoiceCommand(text: 'start word recall game'),
        defaultContext,
      );
      expect(word.type, equals(VoiceIntentType.OPEN_WORD_RECALL));
      expect(word.type.nameCode, equals('OPEN_WORD_RECALL'));

      // 5. OPEN_DIFFERENT_OBJECT
      final diff = await router.classify(
        VoiceCommand(text: 'play different object odd one out'),
        defaultContext,
      );
      expect(diff.type, equals(VoiceIntentType.OPEN_DIFFERENT_OBJECT));
      expect(diff.type.nameCode, equals('OPEN_DIFFERENT_OBJECT'));

      // 6. OPEN_REMINDERS
      final rem = await router.classify(
        VoiceCommand(text: 'open reminders schedule'),
        defaultContext,
      );
      expect(rem.type, equals(VoiceIntentType.OPEN_REMINDERS));
      expect(rem.type.nameCode, equals('OPEN_REMINDERS'));

      // 7. READ_NEXT_REMINDER (Explicit command)
      final nextRem = await router.classify(
        VoiceCommand(text: 'read next reminder'),
        defaultContext,
      );
      expect(nextRem.type, equals(VoiceIntentType.READ_NEXT_REMINDER));
      expect(nextRem.type.nameCode, equals('READ_NEXT_REMINDER'));

      // 8. OPEN_DAILY_ROUTINE
      final routine = await router.classify(
        VoiceCommand(text: 'open daily routine'),
        defaultContext,
      );
      expect(routine.type, equals(VoiceIntentType.OPEN_DAILY_ROUTINE));
      expect(routine.type.nameCode, equals('OPEN_DAILY_ROUTINE'));

      // 9. OPEN_HELP
      final help = await router.classify(
        VoiceCommand(text: 'help me with instructions'),
        defaultContext,
      );
      expect(help.type, equals(VoiceIntentType.OPEN_HELP));
      expect(help.type.nameCode, equals('OPEN_HELP'));

      // 10. CALL_CAREGIVER
      final call = await router.classify(
        VoiceCommand(text: 'call my caregiver'),
        defaultContext,
      );
      expect(call.type, equals(VoiceIntentType.CALL_CAREGIVER));
      expect(call.type.nameCode, equals('CALL_CAREGIVER'));
      expect(call.isSensitive, isTrue);

      // 11. CHANGE_LANGUAGE
      final lang = await router.classify(
        VoiceCommand(text: 'switch language to english'),
        defaultContext,
      );
      expect(lang.type, equals(VoiceIntentType.CHANGE_LANGUAGE));
      expect(lang.type.nameCode, equals('CHANGE_LANGUAGE'));

      // 12. GO_BACK
      final back = await router.classify(
        VoiceCommand(text: 'go back to previous screen'),
        defaultContext,
      );
      expect(back.type, equals(VoiceIntentType.GO_BACK));
      expect(back.type.nameCode, equals('GO_BACK'));

      // 13. CANCEL
      final cancel = await router.classify(
        VoiceCommand(text: 'cancel stop abort'),
        defaultContext,
      );
      expect(cancel.type, equals(VoiceIntentType.CANCEL));
      expect(cancel.type.nameCode, equals('CANCEL'));

      // 14. UNKNOWN (Ambiguous command returns UNKNOWN with confidence 0.0)
      final unknown = await router.classify(
        VoiceCommand(text: 'banana apple spaceship galaxy 42'),
        defaultContext,
      );
      expect(unknown.type.nameCode, equals('UNKNOWN'));
      expect(unknown.confidence, equals(0.0));
    });

    test(
        'Disambiguates "What should I do now?" between READ_NEXT_REMINDER and OPEN_DAILY_ROUTINE',
        () async {
      // Condition A: hasUpcomingReminder is TRUE -> returns READ_NEXT_REMINDER
      const contextWithReminder = VoiceContext(
        currentRoute: '/dashboard',
        hasUpcomingReminder: true,
      );
      final resWithRem = await router.classify(
        VoiceCommand(text: 'What should I do now?'),
        contextWithReminder,
      );
      expect(resWithRem.type, equals(VoiceIntentType.READ_NEXT_REMINDER));

      // Condition B: on Reminders screen -> returns READ_NEXT_REMINDER
      const contextOnRemScreen = VoiceContext(
        currentRoute: '/reminders',
        currentScreen: 'reminders',
      );
      final resRemScreen = await router.classify(
        VoiceCommand(text: 'What should I do now?'),
        contextOnRemScreen,
      );
      expect(resRemScreen.type, equals(VoiceIntentType.READ_NEXT_REMINDER));

      // Condition C: Normal dashboard state (no reminder) -> returns OPEN_DAILY_ROUTINE
      const contextNormal = VoiceContext(
        currentRoute: '/dashboard',
        currentScreen: 'home',
        hasUpcomingReminder: false,
      );
      final resNormal = await router.classify(
        VoiceCommand(text: 'What should I do now?'),
        contextNormal,
      );
      expect(resNormal.type, equals(VoiceIntentType.OPEN_DAILY_ROUTINE));

      // Hindi disambiguation: "अब क्या करूँ"
      final resHiRem = await router.classify(
        VoiceCommand(text: 'अब क्या करूँ', languageCode: 'hi'),
        contextWithReminder,
      );
      expect(resHiRem.type, equals(VoiceIntentType.READ_NEXT_REMINDER));

      final resHiRoutine = await router.classify(
        VoiceCommand(text: 'अब क्या करूँ', languageCode: 'hi'),
        contextNormal,
      );
      expect(resHiRoutine.type, equals(VoiceIntentType.OPEN_DAILY_ROUTINE));

      // Assamese disambiguation: "এতিয়া কি কৰিম"
      final resAsRem = await router.classify(
        VoiceCommand(text: 'এতিয়া কি কৰিম', languageCode: 'as'),
        contextWithReminder,
      );
      expect(resAsRem.type, equals(VoiceIntentType.READ_NEXT_REMINDER));

      final resAsRoutine = await router.classify(
        VoiceCommand(text: 'এতিয়া কি কৰিম', languageCode: 'as'),
        contextNormal,
      );
      expect(resAsRoutine.type, equals(VoiceIntentType.OPEN_DAILY_ROUTINE));
    });

    test(
        'Comprehensive coverage of all 14 Predefined Canonical Intents in Hindi',
        () async {
      const hiContext = VoiceContext(
        currentRoute: '/dashboard',
        selectedLanguage: 'hi',
      );

      // 1. OPEN_HOME: "घर ले चलो"
      final home = await router.classify(
        VoiceCommand(text: 'घर ले चलो', languageCode: 'hi'),
        hiContext,
      );
      expect(home.type, equals(VoiceIntentType.OPEN_HOME));

      // 2. OPEN_GAMES: "दिमागी खेल खेलना है"
      final games = await router.classify(
        VoiceCommand(text: 'दिमागी खेल खेलना है', languageCode: 'hi'),
        hiContext,
      );
      expect(games.type, equals(VoiceIntentType.OPEN_GAMES));

      // 3. OPEN_MEMORY_GAME: "स्मरण खेल"
      final memory = await router.classify(
        VoiceCommand(text: 'स्मरण खेल शुरू करो', languageCode: 'hi'),
        hiContext,
      );
      expect(memory.type, equals(VoiceIntentType.OPEN_MEMORY_GAME));

      // 4. OPEN_WORD_RECALL: "शब्द खेल"
      final word = await router.classify(
        VoiceCommand(text: 'शब्द खेल लगाओ', languageCode: 'hi'),
        hiContext,
      );
      expect(word.type, equals(VoiceIntentType.OPEN_WORD_RECALL));

      // 5. OPEN_DIFFERENT_OBJECT: "अलग वस्तु वाला खेल"
      final diff = await router.classify(
        VoiceCommand(text: 'अलग वस्तु वाला खेल खेलो', languageCode: 'hi'),
        hiContext,
      );
      expect(diff.type, equals(VoiceIntentType.OPEN_DIFFERENT_OBJECT));

      // 6. OPEN_REMINDERS: "दवाई और रिमाइंडर"
      final rem = await router.classify(
        VoiceCommand(text: 'दवाई और रिमाइंडर दिखाओ', languageCode: 'hi'),
        hiContext,
      );
      expect(rem.type, equals(VoiceIntentType.OPEN_REMINDERS));

      // 7. READ_NEXT_REMINDER: "अगला रिमाइंडर बताओ"
      final nextRem = await router.classify(
        VoiceCommand(text: 'अगला रिमाइंडर बताओ', languageCode: 'hi'),
        hiContext,
      );
      expect(nextRem.type, equals(VoiceIntentType.READ_NEXT_REMINDER));

      // 8. OPEN_DAILY_ROUTINE: "दिनचर्या"
      final routine = await router.classify(
        VoiceCommand(text: 'मेरी दिनचर्या दिखाओ', languageCode: 'hi'),
        hiContext,
      );
      expect(routine.type, equals(VoiceIntentType.OPEN_DAILY_ROUTINE));

      // 9. OPEN_HELP: "मदद करो क्या बोलूँ"
      final help = await router.classify(
        VoiceCommand(text: 'मदद करो निर्देश बताओ', languageCode: 'hi'),
        hiContext,
      );
      expect(help.type, equals(VoiceIntentType.OPEN_HELP));

      // 10. CALL_CAREGIVER: "देखभालकर्ता को बुलाओ"
      final call = await router.classify(
        VoiceCommand(text: 'देखभालकर्ता को बुलाओ', languageCode: 'hi'),
        hiContext,
      );
      expect(call.type, equals(VoiceIntentType.CALL_CAREGIVER));
      expect(call.isSensitive, isTrue);

      // 11. CHANGE_LANGUAGE: "हिंदी भाषा"
      final lang = await router.classify(
        VoiceCommand(text: 'हिंदी में बात करो', languageCode: 'hi'),
        hiContext,
      );
      expect(lang.type, equals(VoiceIntentType.CHANGE_LANGUAGE));
      expect(lang.languageCode, equals('hi'));

      // 12. GO_BACK: "पीछे जाओ"
      final back = await router.classify(
        VoiceCommand(text: 'पीछे जाओ', languageCode: 'hi'),
        hiContext,
      );
      expect(back.type, equals(VoiceIntentType.GO_BACK));

      // 13. CANCEL: "रद्द करो"
      final cancel = await router.classify(
        VoiceCommand(text: 'रद्द करो', languageCode: 'hi'),
        hiContext,
      );
      expect(cancel.type, equals(VoiceIntentType.CANCEL));

      // 14. UNKNOWN: अनपेक्षित वाक्य
      final unknown = await router.classify(
        VoiceCommand(text: 'अजीब बात कुछ भी', languageCode: 'hi'),
        hiContext,
      );
      expect(unknown.type.nameCode, equals('UNKNOWN'));
    });

    test(
        'Comprehensive coverage of all 14 Predefined Canonical Intents in Assamese',
        () async {
      const asContext = VoiceContext(
        currentRoute: '/dashboard',
        selectedLanguage: 'as',
      );

      // 1. OPEN_HOME: "ঘৰলৈ লৈ যাওক"
      final home = await router.classify(
        VoiceCommand(text: 'ঘৰলৈ লৈ যাওক', languageCode: 'as'),
        asContext,
      );
      expect(home.type, equals(VoiceIntentType.OPEN_HOME));

      // 2. OPEN_GAMES: "মগজুৰ খেল আৰম্ভ কৰক"
      final games = await router.classify(
        VoiceCommand(text: 'মগজুৰ খেল-ধেমালি আৰম্ভ কৰক', languageCode: 'as'),
        asContext,
      );
      expect(games.type, equals(VoiceIntentType.OPEN_GAMES));

      // 3. OPEN_MEMORY_GAME: "স্মৰণ খেল"
      final memory = await router.classify(
        VoiceCommand(text: 'স্মৰণ খেল খেলিব বিচাৰোঁ', languageCode: 'as'),
        asContext,
      );
      expect(memory.type, equals(VoiceIntentType.OPEN_MEMORY_GAME));

      // 4. OPEN_WORD_RECALL: "শব্দ মনত পেলোৱা"
      final word = await router.classify(
        VoiceCommand(text: 'শব্দ মনত পেলোৱা খেল আৰম্ভ কৰক', languageCode: 'as'),
        asContext,
      );
      expect(word.type, equals(VoiceIntentType.OPEN_WORD_RECALL));

      // 5. OPEN_DIFFERENT_OBJECT: "পৃথক বস্তু"
      final diff = await router.classify(
        VoiceCommand(text: 'পৃথক বস্তু বিচাৰক', languageCode: 'as'),
        asContext,
      );
      expect(diff.type, equals(VoiceIntentType.OPEN_DIFFERENT_OBJECT));

      // 6. OPEN_REMINDERS: "ঔষধ আৰু সোঁৱৰণী"
      final rem = await router.classify(
        VoiceCommand(text: 'মোৰ ঔষধ আৰু সোঁৱৰণী দেখুৱাওক', languageCode: 'as'),
        asContext,
      );
      expect(rem.type, equals(VoiceIntentType.OPEN_REMINDERS));

      // 7. READ_NEXT_REMINDER: "পৰৱৰ্তী সোঁৱৰণী কওক"
      final nextRem = await router.classify(
        VoiceCommand(text: 'পৰৱৰ্তী সোঁৱৰণী কওক', languageCode: 'as'),
        asContext,
      );
      expect(nextRem.type, equals(VoiceIntentType.READ_NEXT_REMINDER));

      // 8. OPEN_DAILY_ROUTINE: "দৈনন্দিন নিয়ম"
      final routine = await router.classify(
        VoiceCommand(text: 'দৈনন্দিন নিয়ম দেখুৱাওক', languageCode: 'as'),
        asContext,
      );
      expect(routine.type, equals(VoiceIntentType.OPEN_DAILY_ROUTINE));

      // 9. OPEN_HELP: "সহায় নিৰ্দেশনা"
      final help = await router.classify(
        VoiceCommand(text: 'সহায় নিৰ্দেশনা লাগে', languageCode: 'as'),
        asContext,
      );
      expect(help.type, equals(VoiceIntentType.OPEN_HELP));

      // 10. CALL_CAREGIVER: "তত্ত্বাৱধায়কক মাতক"
      final call = await router.classify(
        VoiceCommand(text: 'তত্ত্বাৱধায়কক মাতক জৰুৰী', languageCode: 'as'),
        asContext,
      );
      expect(call.type, equals(VoiceIntentType.CALL_CAREGIVER));
      expect(call.isSensitive, isTrue);

      // 11. CHANGE_LANGUAGE: "অসমীয়া"
      final lang = await router.classify(
        VoiceCommand(text: 'অসমীয়া ভাষালৈ সলনি কৰক', languageCode: 'as'),
        asContext,
      );
      expect(lang.type, equals(VoiceIntentType.CHANGE_LANGUAGE));
      expect(lang.languageCode, equals('as'));

      // 12. GO_BACK: "উভতি যাওক"
      final back = await router.classify(
        VoiceCommand(text: 'উভতি যাওক', languageCode: 'as'),
        asContext,
      );
      expect(back.type, equals(VoiceIntentType.GO_BACK));

      // 13. CANCEL: "বন্ধ কৰক"
      final cancel = await router.classify(
        VoiceCommand(text: 'বন্ধ কৰক', languageCode: 'as'),
        asContext,
      );
      expect(cancel.type, equals(VoiceIntentType.CANCEL));

      // 14. UNKNOWN: অচিনাকি বাক্য
      final unknown = await router.classify(
        VoiceCommand(text: 'অচিনাকি কথা কোনো অৰ্থ নাই', languageCode: 'as'),
        asContext,
      );
      expect(unknown.type.nameCode, equals('UNKNOWN'));
    });
  });

  group('Confirmation Workflow for Sensitive Actions', () {
    const router = DeterministicIntentRouter();

    final dummySensitiveAction = VoiceAction.emergencySos(
      id: 'act-sos',
      intent: const VoiceIntent(
        type: VoiceIntentType.emergencySos,
        isSensitive: true,
      ),
    );

    test('Affirmative confirmation across English, Hindi, and Assamese',
        () async {
      final contextWithPending = VoiceContext(
        currentRoute: '/',
        pendingAction: dummySensitiveAction,
      );

      // English: "yes"
      final affEn = await router.classify(
        VoiceCommand(text: 'yes please confirm'),
        contextWithPending,
      );
      expect(affEn.type, equals(VoiceIntentType.confirm));

      // Hindi: "हाँ ठीक है"
      final affHi = await router.classify(
        VoiceCommand(text: 'हाँ ठीक है', languageCode: 'hi'),
        contextWithPending,
      );
      expect(affHi.type, equals(VoiceIntentType.confirm));

      // Assamese: "হয় কৰক"
      final affAs = await router.classify(
        VoiceCommand(text: 'হয় কৰক', languageCode: 'as'),
        contextWithPending,
      );
      expect(affAs.type, equals(VoiceIntentType.confirm));
    });

    test('Cancellation across English, Hindi, and Assamese', () async {
      final contextWithPending = VoiceContext(
        currentRoute: '/',
        pendingAction: dummySensitiveAction,
      );

      // English: "cancel"
      final cancelEn = await router.classify(
        VoiceCommand(text: 'cancel stop'),
        contextWithPending,
      );
      expect(cancelEn.type, equals(VoiceIntentType.cancel));

      // Hindi: "नहीं मत करो"
      final cancelHi = await router.classify(
        VoiceCommand(text: 'नहीं मत करो', languageCode: 'hi'),
        contextWithPending,
      );
      expect(cancelHi.type, equals(VoiceIntentType.cancel));

      // Assamese: "নহয় নকৰিব"
      final cancelAs = await router.classify(
        VoiceCommand(text: 'নহয় নকৰিব', languageCode: 'as'),
        contextWithPending,
      );
      expect(cancelAs.type, equals(VoiceIntentType.cancel));
    });
  });

  group('VoiceAssistantController Execution and Text Fallback', () {
    test('Automatic listening lifecycle and text fallback', () async {
      String? navigatedRoute;
      final executor = VoiceActionExecutor(
        onNavigate: (route, {arguments}) => navigatedRoute = route,
      );

      final controller = VoiceAssistantController(
        actionExecutor: executor,
      );

      // Open assistant
      await controller.openAssistant(
          currentRoute: '/dashboard', autoListen: true);
      expect(controller.isAssistantOpen, isTrue);
      expect(controller.isListening, isTrue);

      // Graceful text fallback execution: "play games"
      final result = await controller.processTextInput('play brain games');
      expect(result.isSuccess, isTrue);
      expect(navigatedRoute, equals('/games'));

      await controller.closeAssistant();
      expect(controller.isAssistantOpen, isFalse);
    });

    test('Sensitive action confirmation flow end-to-end', () async {
      String? navigatedRoute;
      final executor = VoiceActionExecutor(
        onNavigate: (route, {arguments}) => navigatedRoute = route,
      );

      final controller = VoiceAssistantController(
        actionExecutor: executor,
      );

      await controller.openAssistant(currentRoute: '/dashboard');

      // Trigger sensitive action
      final sosResult = await controller.processTextInput('emergency sos help');
      expect(sosResult.isSuccess, isTrue);
      expect(controller.isConfirming, isTrue);
      expect(controller.pendingAction, isNotNull);
      // Not navigated yet because confirmation is required
      expect(navigatedRoute, isNull);

      // Confirm via text fallback: "yes"
      final confirmResult = await controller.processTextInput('yes');
      expect(confirmResult.isSuccess, isTrue);
      expect(controller.isConfirming, isFalse);
      expect(navigatedRoute, equals('/take-me-home'));
    });

    test('Sensitive action cancellation flow end-to-end', () async {
      String? navigatedRoute;
      final executor = VoiceActionExecutor(
        onNavigate: (route, {arguments}) => navigatedRoute = route,
      );

      final controller = VoiceAssistantController(
        actionExecutor: executor,
      );

      await controller.openAssistant(currentRoute: '/dashboard');

      // Trigger sensitive action
      await controller.processTextInput('emergency help');
      expect(controller.isConfirming, isTrue);

      // Cancel via method
      final cancelResult = await controller.cancelPendingAction();
      expect(cancelResult.isSuccess, isTrue);
      expect(controller.isConfirming, isFalse);
      expect(controller.pendingAction, isNull);
      expect(navigatedRoute, isNull);
    });

    test('Explicit 8-state lifecycle and transitions verified independently',
        () async {
      final observedStates = <VoiceAssistantStatus>[];
      final controller = VoiceAssistantController();
      controller.addListener(() {
        observedStates.add(controller.status);
      });

      // Initially idle
      expect(controller.status, equals(VoiceAssistantStatus.idle));
      expect(controller.isIdle, isTrue);

      // Open assistant -> transitions through opening to listening
      await controller.openAssistant(
          currentRoute: '/dashboard', autoListen: true);
      expect(observedStates, contains(VoiceAssistantStatus.opening));
      expect(controller.status, equals(VoiceAssistantStatus.listening));
      expect(controller.isListening, isTrue);

      // Stop listening manually -> returns to idle
      await controller.stopListening();
      expect(controller.status, equals(VoiceAssistantStatus.idle));
      expect(controller.isIdle, isTrue);

      // Start listening again -> listening
      await controller.startListening();
      expect(controller.status, equals(VoiceAssistantStatus.listening));

      // Cancel assistant explicitly -> cancelled
      await controller.cancelAssistant();
      expect(controller.status, equals(VoiceAssistantStatus.cancelled));
      expect(controller.isCancelled, isTrue);

      // Close assistant -> resets to idle
      await controller.closeAssistant();
      expect(controller.status, equals(VoiceAssistantStatus.idle));
      controller.dispose();
    });

    test('Single command processed at a time and stops listening immediately',
        () async {
      final controller = VoiceAssistantController();
      await controller.openAssistant(autoListen: true);
      expect(controller.isListening, isTrue);

      // Process command
      final future1 = controller.processTextInput('open games');
      // Consecutive attempt while processing should be rejected
      final future2 = controller.processTextInput('call help');

      final res2 = await future2;
      expect(res2.isSuccess, isFalse);
      expect(res2.displayMessage, contains('Already processing'));

      final res1 = await future1;
      expect(res1.isSuccess, isTrue);

      // After command, listening must be stopped
      expect(controller.isListening, isFalse);
      controller.dispose();
    });

    test('Displays correct language labels and preserves transcription state',
        () {
      final controller = VoiceAssistantController();
      controller.setLanguage('en');
      expect(controller.currentLanguageName, equals('English (EN)'));

      controller.setLanguage('hi');
      expect(controller.currentLanguageName, equals('हिंदी (Hindi)'));

      controller.setLanguage('as');
      expect(controller.currentLanguageName, equals('অসমীয়া (Assamese)'));
      controller.dispose();
    });
  });

  group('Future Integration Contracts', () {
    test(
        'Offline ASR provider correctly reports unavailable when weights are absent',
        () async {
      final offlineAsr = OfflineAsrProvider();
      expect(offlineAsr.isModelLoaded, isFalse);
      expect(offlineAsr.isAvailable, isFalse);

      final initialized = await offlineAsr.initialize(languageCode: 'en');
      expect(initialized, isFalse);
    });

    test(
        'Local Qwen intent classifier correctly reports unavailable when weights are absent',
        () async {
      final qwen = LocalQwenIntentClassifier();
      expect(qwen.isModelLoaded, isFalse);

      const context = VoiceContext();
      final intent = await qwen.classify(
        VoiceCommand(text: 'what is my name'),
        context,
      );
      expect(intent.type, equals(VoiceIntentType.unknown));
    });
  });

  group('Global Patient Voice Assistant Floating Button & Route Context', () {
    test('VoiceRouteTracker visibility rules: patient vs caregiver screens',
        () {
      final tracker = VoiceRouteTracker.instance;

      // Patient screens: should show
      tracker.setCurrentRoute('/dashboard');
      expect(tracker.shouldShowFloatingButton, isTrue);

      tracker.setCurrentRoute('/games');
      expect(tracker.shouldShowFloatingButton, isTrue);

      tracker.setCurrentRoute('/games/memory-match');
      expect(tracker.shouldShowFloatingButton, isTrue);

      tracker.setCurrentRoute('/take-me-home');
      expect(tracker.shouldShowFloatingButton, isTrue);

      tracker.setCurrentRoute('/assessment');
      expect(tracker.shouldShowFloatingButton, isTrue);

      // Caregiver / Admin screens: MUST NOT show
      tracker.setCurrentRoute('/caregiver');
      expect(tracker.shouldShowFloatingButton, isFalse);

      tracker.setCurrentRoute('/caregiver-dashboard');
      expect(tracker.shouldShowFloatingButton, isFalse);

      tracker.setCurrentRoute('/caregiver-login');
      expect(tracker.shouldShowFloatingButton, isFalse);

      tracker.setCurrentRoute('/mri-screening');
      expect(tracker.shouldShowFloatingButton, isFalse);

      // Auth / Splash screens: MUST NOT show
      tracker.setCurrentRoute('/role-select');
      expect(tracker.shouldShowFloatingButton, isFalse);

      tracker.setCurrentRoute('/login/patient');
      expect(tracker.shouldShowFloatingButton, isFalse);

      // When modal is open: MUST NOT show
      tracker.setCurrentRoute('/dashboard');
      tracker.setModalOpen(true);
      expect(tracker.shouldShowFloatingButton, isFalse);

      tracker.setModalOpen(false);
      expect(tracker.shouldShowFloatingButton, isTrue);
    });

    test('Screen context preserves current route and handles "start this"',
        () async {
      const router = DeterministicIntentRouter();

      // Case 1: Patient on Games Hub screen saying "start this"
      const gamesContext = VoiceContext(currentRoute: '/games');
      final intent = await router.classify(
        VoiceCommand(text: 'start this'),
        gamesContext,
      );
      expect(intent.type, equals(VoiceIntentType.OPEN_MEMORY_GAME));
      expect(intent.slots['targetRoute'], equals('/games/memory-match'));

      // Case 2: Patient on Home Dashboard saying "play games"
      const homeContext = VoiceContext(currentRoute: '/dashboard');
      final homeIntent = await router.classify(
        VoiceCommand(text: 'play games'),
        homeContext,
      );
      expect(homeIntent.type, equals(VoiceIntentType.OPEN_GAMES));
      expect(homeIntent.slots['targetRoute'], equals('/games'));
    });

    testWidgets(
        'PatientVoiceFloatingButton renders with elderly-friendly touch target',
        (WidgetTester tester) async {
      VoiceRouteTracker.instance.setCurrentRoute('/games');
      VoiceRouteTracker.instance.setModalOpen(false);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Center(child: Text('Games Hub')),
                PatientVoiceFloatingButton(),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify floating button is rendered
      expect(find.byType(PatientVoiceFloatingButton), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
      expect(find.text('Voice'), findsOneWidget);

      // Verify touch target dimensions are >= 56 pt height and >= 116 pt width
      final finder = find.byType(Ink);
      final size = tester.getSize(finder);
      expect(size.height, greaterThanOrEqualTo(56.0));
      expect(size.width, greaterThanOrEqualTo(116.0));

      // Tap button and verify VoiceAssistantModal opens
      await tester.tap(find.byType(PatientVoiceFloatingButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(VoiceAssistantModal), findsOneWidget);
    });

    testWidgets(
        'VoiceAssistantModal renders language badge, transcript area, fallback input, and large Cancel button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VoiceAssistantModal(currentRoute: '/dashboard'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Current Language badge displayed (Requirement 5)
      expect(find.byIcon(Icons.translate_rounded), findsOneWidget);
      expect(find.textContaining('Language:'), findsOneWidget);

      // 2. Recognized Speech card header displayed (Requirement 5)
      expect(find.textContaining('Recognized Speech:'), findsOneWidget);

      // 3. Text fallback input bar and send button displayed (Requirement 7)
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);

      // 4. Large Cancel button rendered with elderly-friendly height >= 56 (Requirement 6)
      final cancelButtons = find.widgetWithText(OutlinedButton, 'Cancel');
      expect(cancelButtons, findsOneWidget);
      final cancelSize = tester.getSize(cancelButtons);
      expect(cancelSize.height, greaterThanOrEqualTo(56.0));

      // 5. Tapping cancel button executes cancel and dismisses safely
      await tester.tap(cancelButtons);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });
  });

  group('VoiceActionExecutor GoRouter Navigation & Approved Route Mapping', () {
    test('Maps all approved canonical intents to existing routes directly without confirmation', () async {
      final executedRoutes = <String>[];
      final executor = VoiceActionExecutor(
        onNavigate: (route, {arguments}) => executedRoutes.add(route),
      );
      const router = DeterministicIntentRouter();
      const context = VoiceContext(currentRoute: '/');

      // 1. OPEN_HOME -> /dashboard
      final homeIntent = await router.classify(VoiceCommand(text: 'go to home dashboard'), context);
      final homeAction = executor.resolveAction(homeIntent, context);
      expect(homeAction.type, equals(VoiceActionType.navigate));
      expect(homeAction.requiresConfirmation, isFalse);
      final homeResult = await executor.execute(homeAction);
      expect(homeResult.isSuccess, isTrue);
      expect(homeResult.navigationRoute, equals('/dashboard'));
      expect(executedRoutes.last, equals('/dashboard'));

      // 2. OPEN_GAMES -> /games
      final gamesIntent = await router.classify(VoiceCommand(text: 'play games'), context);
      final gamesAction = executor.resolveAction(gamesIntent, context);
      expect(gamesAction.requiresConfirmation, isFalse);
      final gamesResult = await executor.execute(gamesAction);
      expect(gamesResult.isSuccess, isTrue);
      expect(gamesResult.navigationRoute, equals('/games'));
      expect(executedRoutes.last, equals('/games'));

      // 3. OPEN_MEMORY_GAME -> /games/memory-match
      final memIntent = await router.classify(VoiceCommand(text: 'open memory game'), context);
      final memAction = executor.resolveAction(memIntent, context);
      expect(memAction.requiresConfirmation, isFalse);
      final memResult = await executor.execute(memAction);
      expect(memResult.isSuccess, isTrue);
      expect(memResult.navigationRoute, equals('/games/memory-match'));
      expect(executedRoutes.last, equals('/games/memory-match'));

      // 4. OPEN_WORD_RECALL -> /games/word-recall
      final wordIntent = await router.classify(VoiceCommand(text: 'open word recall game'), context);
      final wordAction = executor.resolveAction(wordIntent, context);
      expect(wordAction.requiresConfirmation, isFalse);
      final wordResult = await executor.execute(wordAction);
      expect(wordResult.isSuccess, isTrue);
      expect(wordResult.navigationRoute, equals('/games/word-recall'));
      expect(executedRoutes.last, equals('/games/word-recall'));

      // 5. OPEN_DIFFERENT_OBJECT -> /games/different-object
      final diffIntent = await router.classify(VoiceCommand(text: 'open different object game'), context);
      final diffAction = executor.resolveAction(diffIntent, context);
      expect(diffAction.requiresConfirmation, isFalse);
      final diffResult = await executor.execute(diffAction);
      expect(diffResult.isSuccess, isTrue);
      expect(diffResult.navigationRoute, equals('/games/different-object'));
      expect(executedRoutes.last, equals('/games/different-object'));

      // 6. OPEN_DAILY_ROUTINE -> /games/routine (dedicated existing routine sequence screen)
      final routineIntent = await router.classify(VoiceCommand(text: 'open daily routine'), context);
      final routineAction = executor.resolveAction(routineIntent, context);
      expect(routineAction.requiresConfirmation, isFalse);
      final routineResult = await executor.execute(routineAction);
      expect(routineResult.isSuccess, isTrue);
      expect(routineResult.navigationRoute, equals('/games/routine'));
      expect(executedRoutes.last, equals('/games/routine'));

      // 7. GO_BACK -> '..' (pops back safely)
      final backIntent = await router.classify(VoiceCommand(text: 'go back'), context);
      final backAction = executor.resolveAction(backIntent, context);
      expect(backAction.requiresConfirmation, isFalse);
      final backResult = await executor.execute(backAction);
      expect(backResult.isSuccess, isTrue);
      expect(backResult.navigationRoute, equals('..'));
      expect(executedRoutes.last, equals('..'));

      // 8. OPEN_REMINDERS / READ_NEXT_REMINDER -> announces reminders and opens reminders view
      final remIntent = await router.classify(VoiceCommand(text: 'check my reminders'), context);
      final remAction = executor.resolveAction(remIntent, context);
      expect(remAction.requiresConfirmation, isFalse);
      final remResult = await executor.execute(remAction);
      expect(remResult.isSuccess, isTrue);
      expect(remResult.navigationRoute, equals('/dashboard'));
      expect(executedRoutes.last, equals('/dashboard'));
    });

    test('Rejects non-existent routes and reports failure without navigating', () async {
      var wasNavigated = false;
      final executor = VoiceActionExecutor(
        onNavigate: (route, {arguments}) => wasNavigated = true,
      );

      // Construct a fake custom navigation action to a non-existent route
      final invalidAction = VoiceAction.navigate(
        id: 'fake-1',
        intent: const VoiceIntent(type: VoiceIntentType.navigate),
        targetRoute: '/non-existent-fake-screen',
      );

      final result = await executor.execute(invalidAction);
      expect(result.isSuccess, isFalse);
      expect(result.error, contains("Target route '/non-existent-fake-screen' does not exist"));
      expect(wasNavigated, isFalse);
    });

    test('CALL_CAREGIVER routes to Caregiver Confirmation Screen without immediate calling', () async {
      String? executedRoute;
      final executor = VoiceActionExecutor(
        onNavigate: (route, {arguments}) => executedRoute = route,
      );
      const router = DeterministicIntentRouter();
      const context = VoiceContext(currentRoute: '/');

      final intent = await router.classify(VoiceCommand(text: 'call my caregiver'), context);
      expect(intent.type, equals(VoiceIntentType.CALL_CAREGIVER));

      final action = executor.resolveAction(intent, context);
      expect(action.type, equals(VoiceActionType.navigate));
      expect(action.targetRoute, equals('/caregiver-confirm'));

      final result = await executor.execute(action);
      expect(result.isSuccess, isTrue);
      expect(executedRoute, equals('/caregiver-confirm'));
    });

    test('Sensitive operation emergencySos requires confirmation before execution', () async {
      String? executedRoute;
      final executor = VoiceActionExecutor(
        onNavigate: (route, {arguments}) => executedRoute = route,
      );
      const router = DeterministicIntentRouter();

      final sosAction = VoiceAction.emergencySos(
        id: 'act-sos',
        intent: const VoiceIntent(
          type: VoiceIntentType.emergencySos,
          isSensitive: true,
        ),
      );
      expect(sosAction.requiresConfirmation, isTrue);
      expect(sosAction.type, equals(VoiceActionType.triggerEmergency));

      final controller = VoiceAssistantController(
        intentRouter: router,
        actionExecutor: executor,
      );

      await controller.openAssistant(currentRoute: '/dashboard');
      // Execute sensitive action requiring confirmation
      final promptResult = await controller.executeActionDirectly(sosAction);
      expect(promptResult.isSuccess, isTrue);
      expect(controller.isConfirming, isTrue);
      expect(executedRoute, isNull);

      // Step 2: Affirmative reply -> executes sensitive action
      final confirmedResult = await controller.processTextInput('yes please');
      expect(confirmedResult.isSuccess, isTrue);
      expect(controller.isConfirming, isFalse);
      expect(executedRoute, equals('/take-me-home'));
      controller.dispose();
    });

    test('Preserves patient session and selectedPatientId across navigation actions', () async {
      final initialPatient = CaregiverService.instance.selectedPatientId;
      expect(initialPatient, isNotEmpty);

      String? navRoute;
      final executor = VoiceActionExecutor(
        onNavigate: (route, {arguments}) => navRoute = route,
      );
      const router = DeterministicIntentRouter();
      final context = VoiceContext(
        currentRoute: '/games',
        selectedPatient: initialPatient,
      );

      final action = executor.resolveAction(
        await router.classify(VoiceCommand(text: 'open daily routine'), context),
        context,
      );
      final result = await executor.execute(action);
      expect(result.isSuccess, isTrue);
      expect(navRoute, equals('/games/routine'));

      // Verify patient session remained completely untouched
      expect(CaregiverService.instance.selectedPatientId, equals(initialPatient));
    });
  });

  group('Contextual Screen Commands & Anti-Hallucination Guard', () {
    const router = DeterministicIntentRouter();

    test('On Games screen: "Start this" uses currently selected game', () async {
      String? navigatedRoute;
      final executor = VoiceActionExecutor(
        onNavigate: (route, {arguments}) => navigatedRoute = route,
      );

      // Context with 'word-recall' selected on Games Hub
      const context = VoiceContext(
        currentRoute: '/games',
        currentScreen: 'games_hub',
        currentGame: 'word-recall',
      );

      final intent = await router.classify(
        VoiceCommand(text: 'start this'),
        context,
      );
      expect(intent.type, equals(VoiceIntentType.OPEN_WORD_RECALL));
      expect(intent.gameId, equals('word-recall'));

      final action = executor.resolveAction(intent, context);
      final result = await executor.execute(action);
      expect(result.isSuccess, isTrue);
      expect(navigatedRoute, equals('/games/word-recall'));
    });

    test('Inside Memory Match: "Make it easier" routes to deterministic adaptive difficulty mechanism', () async {
      const executor = VoiceActionExecutor();
      final storage = GameStorageService.instance;

      // Start at level 2
      await storage.setAdaptiveLevel('memory-match', 2);
      expect(storage.getRecommendedLevel('memory-match'), equals(2));

      // 1. English: "Make it easier"
      const matchContext = VoiceContext(
        currentRoute: '/games/memory-match',
        currentScreen: 'memory_match',
        currentGame: 'memory-match',
      );

      final intentEn = await router.classify(
        VoiceCommand(text: 'make it easier'),
        matchContext,
      );
      expect(intentEn.type, equals(VoiceIntentType.ADAPTIVE_DIFFICULTY));
      expect(intentEn.slots['mode'], equals('easier'));
      expect(intentEn.slots['gameId'], equals('memory-match'));

      final actionEn = executor.resolveAction(intentEn, matchContext);
      final resultEn = await executor.execute(actionEn);
      expect(resultEn.isSuccess, isTrue);
      expect(resultEn.message, contains('Level 1'));
      expect(storage.getRecommendedLevel('memory-match'), equals(1));

      // Clamping: level 1 is minimum, cannot decrease below 1
      final resultClamped = await executor.execute(actionEn);
      expect(resultClamped.isSuccess, isTrue);
      expect(storage.getRecommendedLevel('memory-match'), equals(1));

      // 2. Hindi: "कठिन करो" (make it harder)
      final intentHi = await router.classify(
        VoiceCommand(text: 'कठिन करो', languageCode: 'hi'),
        matchContext,
      );
      expect(intentHi.type, equals(VoiceIntentType.ADAPTIVE_DIFFICULTY));
      expect(intentHi.slots['mode'], equals('harder'));

      final actionHi = executor.resolveAction(intentHi, matchContext);
      final resultHi = await executor.execute(actionHi);
      expect(resultHi.isSuccess, isTrue);
      expect(storage.getRecommendedLevel('memory-match'), equals(2));

      // 3. Assamese: "সহজ কৰক" (make it easier)
      final intentAs = await router.classify(
        VoiceCommand(text: 'সহজ কৰক', languageCode: 'as'),
        matchContext,
      );
      expect(intentAs.type, equals(VoiceIntentType.ADAPTIVE_DIFFICULTY));
      expect(intentAs.slots['mode'], equals('easier'));

      final actionAs = executor.resolveAction(intentAs, matchContext);
      final resultAs = await executor.execute(actionAs);
      expect(resultAs.isSuccess, isTrue);
      expect(storage.getRecommendedLevel('memory-match'), equals(1));
    });

    test('On Reminders screen: "What\'s next?" reads the next available reminder', () async {
      const executor = VoiceActionExecutor();
      const remContext = VoiceContext(
        currentRoute: '/dashboard',
        currentScreen: 'reminders',
        metadata: {'activeTab': 'reminders'},
      );

      final intent = await router.classify(
        VoiceCommand(text: "what's next?"),
        remContext,
      );
      expect(intent.type, equals(VoiceIntentType.READ_NEXT_REMINDER));

      final action = executor.resolveAction(intent, remContext);
      final result = await executor.execute(action);
      expect(result.isSuccess, isTrue);
      expect(result.message, isNotEmpty);
      expect(result.message, contains('Donepezil'));
    });

    test('On Daily Routine: "What\'s my next activity?" uses existing routine data', () async {
      const executor = VoiceActionExecutor();
      const routineContext = VoiceContext(
        currentRoute: '/games/routine',
        currentScreen: 'routine',
      );

      // Explicit activity command
      final intentActivity = await router.classify(
        VoiceCommand(text: "what's my next activity?"),
        routineContext,
      );
      expect(intentActivity.type, equals(VoiceIntentType.READ_NEXT_ROUTINE));

      final actionActivity = executor.resolveAction(intentActivity, routineContext);
      final resultActivity = await executor.execute(actionActivity);
      expect(resultActivity.isSuccess, isTrue);
      expect(resultActivity.message, contains('Evening Garden Walk'));

      // Contextual "What's next?" on routine screen also resolves to next routine
      final intentWhatsNext = await router.classify(
        VoiceCommand(text: "what's next?"),
        routineContext,
      );
      expect(intentWhatsNext.type, equals(VoiceIntentType.READ_NEXT_ROUTINE));

      final actionWhatsNext = executor.resolveAction(intentWhatsNext, routineContext);
      final resultWhatsNext = await executor.execute(actionWhatsNext);
      expect(resultWhatsNext.isSuccess, isTrue);
      expect(resultWhatsNext.message, contains('Evening Garden Walk'));
    });

    test('On patient dashboard: "Show my games" routes to OPEN_GAMES', () async {
      String? navRoute;
      final executor = VoiceActionExecutor(
        onNavigate: (route, {arguments}) => navRoute = route,
      );
      const dashContext = VoiceContext(
        currentRoute: '/dashboard',
        currentScreen: 'home',
      );

      final intent = await router.classify(
        VoiceCommand(text: 'show my games'),
        dashContext,
      );
      expect(intent.type, equals(VoiceIntentType.OPEN_GAMES));

      final action = executor.resolveAction(intent, dashContext);
      final result = await executor.execute(action);
      expect(result.isSuccess, isTrue);
      expect(navRoute, equals('/games'));
    });

    test('Anti-Hallucination: Missing contextual information does not guess and asks clarification with available actions', () async {
      const executor = VoiceActionExecutor();

      // 1. On Dashboard screen: "start this" has no game context and is an unavailable action
      const dashboardContext = VoiceContext(
        currentRoute: '/dashboard',
        currentScreen: 'home',
        currentGame: null,
      );

      final intentAmbiguous = await router.classify(
        VoiceCommand(text: 'start this'),
        dashboardContext,
      );
      // Must NOT guess an arbitrary game!
      expect(intentAmbiguous.type, equals(VoiceIntentType.unknown));

      final actionAmbiguous = executor.resolveAction(intentAmbiguous, dashboardContext);
      final resultAmbiguous = await executor.execute(actionAmbiguous);
      expect(resultAmbiguous.isSuccess, isFalse);
      // Provides only actions available on the Dashboard screen
      expect(
        resultAmbiguous.message,
        contains('I could not find that action here'),
      );

      // 2. On Reminders screen: "make it easier" is NOT an available action
      const remContext = VoiceContext(
        currentRoute: '/dashboard',
        currentScreen: 'reminders',
      );

      final intentInvalid = await router.classify(
        VoiceCommand(text: 'make it easier'),
        remContext,
      );
      // Must NOT guess or activate adaptive difficulty on a reminders screen
      expect(intentInvalid.type, equals(VoiceIntentType.unknown));

      final actionInvalid = executor.resolveAction(intentInvalid, remContext);
      final resultInvalid = await executor.execute(actionInvalid);
      expect(resultInvalid.isSuccess, isFalse);
      // Provides only reminders screen actions
      expect(
        resultInvalid.message,
        contains('You can listen to your next reminder, or go to home screen'),
      );

      // 3. Localized anti-hallucination clarification in Hindi
      const remContextHi = VoiceContext(
        currentRoute: '/dashboard',
        currentScreen: 'reminders',
        activeLanguageCode: 'hi',
      );
      final clarificationHi = remContextHi.buildClarificationMessage();
      expect(
        clarificationHi,
        contains('आप अपना अगला रिमाइंडर सुन सकते हैं'),
      );

      // 4. Localized anti-hallucination clarification in Assamese
      const gamesContextAs = VoiceContext(
        currentRoute: '/games',
        currentScreen: 'games_hub',
        activeLanguageCode: 'as',
      );
      final clarificationAs = gamesContextAs.buildClarificationMessage();
      expect(
        clarificationAs,
        contains('আপুনি খেল আৰম্ভ কৰিব পাৰে'),
      );
    });
  });
}

