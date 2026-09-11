// test/tts_service_test.dart
//
// Comprehensive unit tests for TTSService / TtsService:
// 1. TTSService / TtsService API contract (speak, stop, isAvailable).
// 2. English, Hindi, and Assamese language support.
// 3. Synchronization with currently selected app language.
// 4. Keeping voice responses short and gentle.
// 5. Safe Assamese TTS fallback (fails safely, never crashes, response preserved for visual display).
// 6. Safe error recovery and stop playback.
// 7. VoiceAssistantController response flow integration.

import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_care/core/localization/app_localizations.dart';
import 'package:smriti_care/core/voice/voice.dart';

class _MockTtsProvider implements TtsProvider {
  bool available = true;
  bool speaking = false;
  String? lastSpokenText;
  String? lastSpokenLang;
  final Map<String, bool> langAvailability = {
    'en': true,
    'hi': true,
    'as': true,
  };
  void Function()? onDoneCallback;
  void Function(String error)? onErrorCallback;

  @override
  bool get isAvailable => available;

  @override
  Future<bool> initialize() async => available;

  @override
  Future<void> speak({
    required String text,
    required String languageCode,
    required double speechRate,
    required double pitch,
    required void Function() onDone,
    required void Function(String error) onError,
  }) async {
    if (!available) {
      onError('TTS provider unavailable');
      return;
    }
    final lang = languageCode.split('-').first.toLowerCase();
    if (langAvailability[lang] == false) {
      onError('TTS unavailable for language: $languageCode');
      return;
    }

    speaking = true;
    lastSpokenText = text;
    lastSpokenLang = languageCode;
    onDoneCallback = onDone;
    onErrorCallback = onError;
  }

  @override
  Future<void> stop() async {
    speaking = false;
    onDoneCallback = null;
    onErrorCallback = null;
  }

  @override
  Future<void> dispose() async {
    speaking = false;
  }

  void simulateDone() {
    if (speaking) {
      speaking = false;
      onDoneCallback?.call();
    }
  }

  void simulateError(String error) {
    if (speaking) {
      speaking = false;
      onErrorCallback?.call(error);
    }
  }
}

void main() {
  late _MockTtsProvider mockProvider;
  late TtsService ttsService;

  setUp(() {
    mockProvider = _MockTtsProvider();
    ttsService = TtsService.create(provider: mockProvider);
  });

  tearDown(() {
    ttsService.dispose();
  });

  group('TTSService / TtsService Contract & API Validation', () {
    test('TTSService typedef points to TtsService', () {
      expect(ttsService, isA<TTSService>());
      expect(ttsService, isA<TtsService>());
    });

    test('isAvailable() method reflects provider and language availability', () {
      mockProvider.available = true;
      expect(ttsService.isAvailable(), isTrue);
      expect(ttsService.isAvailable('en'), isTrue);
      expect(ttsService.isAvailable('hi'), isTrue);
      expect(ttsService.isAvailable('as'), isTrue);

      // Unsupported language returns false
      expect(ttsService.isAvailable('fr'), isFalse);
      expect(ttsService.isAvailable('es'), isFalse);

      // When provider is completely unavailable
      mockProvider.available = false;
      expect(ttsService.isAvailable(), isFalse);
      expect(ttsService.isAvailable('en'), isFalse);
    });

    test('speak(text, language) speaks in English, Hindi, and Assamese', () async {
      await ttsService.speak('Opening brain games.', 'en');
      expect(mockProvider.speaking, isTrue);
      expect(mockProvider.lastSpokenText, equals('Opening brain games.'));
      expect(mockProvider.lastSpokenLang, equals('en-IN'));
      mockProvider.simulateDone();
      expect(ttsService.isSpeaking, isFalse);

      await ttsService.speak('गेम खोले जा रहे हैं।', 'hi');
      expect(mockProvider.speaking, isTrue);
      expect(mockProvider.lastSpokenText, equals('गेम खोले जा रहे हैं।'));
      expect(mockProvider.lastSpokenLang, equals('hi-IN'));
      mockProvider.simulateDone();

      await ttsService.speak('খেল খোলা হৈছে।', 'as');
      expect(mockProvider.speaking, isTrue);
      expect(mockProvider.lastSpokenText, equals('খেল খোলা হৈছে।'));
      expect(mockProvider.lastSpokenLang, equals('as-IN'));
      mockProvider.simulateDone();
    });

    test('stop() immediately terminates speech playback', () async {
      await ttsService.speak('Going back.', 'en');
      expect(mockProvider.speaking, isTrue);
      expect(ttsService.isSpeaking, isTrue);

      await ttsService.stop();
      expect(mockProvider.speaking, isFalse);
      expect(ttsService.isSpeaking, isFalse);
      expect(ttsService.state, equals(TtsServiceState.idle));
    });
  });

  group('Currently Selected App Language Synchronization', () {
    test('speak(text) without language uses selected app language', () async {
      LocalizationService.instance.currentLocaleNotifier.value =
          const Locale('hi');

      expect(ttsService.activeLanguage, equals('hi'));
      await ttsService.speak('स्क्रीन खोली जा रही है।');

      expect(mockProvider.lastSpokenLang, equals('hi-IN'));
      expect(mockProvider.lastSpokenText, equals('स्क्रीन खोली जा रही है।'));

      // Switch language to Assamese
      LocalizationService.instance.currentLocaleNotifier.value =
          const Locale('as');
      expect(ttsService.activeLanguage, equals('as'));
      await ttsService.speak('স্ক্ৰীন খুলি থকা হৈছে।');

      expect(mockProvider.lastSpokenLang, equals('as-IN'));
      expect(mockProvider.lastSpokenText, equals('স্ক্ৰীন খুলি থকা হৈছে।'));

      // Reset to English
      LocalizationService.instance.currentLocaleNotifier.value =
          const Locale('en');
    });
  });

  group('Elderly Voice Response Conciseness', () {
    test('trimResponseForSpeech truncates excessively long sentences for elderly care', () {
      const shortText = 'Opening Memory Match.';
      expect(TtsService.trimResponseForSpeech(shortText), equals(shortText));

      const longPrompt =
          'This is an extremely long response that contains far too many words for an elderly patient '
          'with cognitive decline to process comfortably in a single voice breath and should definitely be kept concise.';
      final trimmed = TtsService.trimResponseForSpeech(longPrompt, maxWords: 15);
      final words = trimmed.split(' ');
      expect(words.length, equals(15));
      expect(trimmed.endsWith('...'), isTrue);
    });
  });

  group('Safe Assamese TTS Fallback & Crash Prevention', () {
    test('When Assamese TTS is unavailable, fails safely, preserves text visually, and never crashes', () async {
      // Simulate device where Assamese TTS is not installed
      ttsService.setAssameseAvailable(false);
      mockProvider.langAvailability['as'] = false;

      expect(ttsService.isAvailable('as'), isFalse);
      expect(ttsService.isAvailable('en'), isTrue);
      expect(ttsService.isAvailable('hi'), isTrue);

      const assameseResponse = 'আপোনাৰ কোনো সোঁৱৰণী নিৰ্ধাৰণ কৰা হোৱা নাই।';

      // Calling speak in Assamese must not throw, must not crash, and must preserve text
      await expectLater(
        ttsService.speak(assameseResponse, 'as'),
        completes,
      );

      // State remains safe idle
      expect(ttsService.state, equals(TtsServiceState.idle));
      expect(ttsService.isSpeaking, isFalse);
      // Spoken text preserved for visual UI rendering
      expect(ttsService.lastSpokenText, equals(assameseResponse));
      // Provider was not called with invalid audio synthesis
      expect(mockProvider.speaking, isFalse);
    });

    test('Provider error during speak fails safely without unhandled exception', () async {
      await ttsService.speak('Testing provider failure', 'en');
      expect(ttsService.isSpeaking, isTrue);

      // Simulate provider native error
      mockProvider.simulateError('Native audio track failure');
      expect(ttsService.state, equals(TtsServiceState.idle));
      expect(ttsService.isSpeaking, isFalse);
    });
  });

  group('VoiceAssistantController TTS Integration', () {
    test('Controller handles command and routes spoken response through TTSService', () async {
      String? navigatedRoute;
      final executor = VoiceActionExecutor(
        onNavigate: (r, {arguments}) => navigatedRoute = r,
      );

      final controller = VoiceAssistantController(
        ttsService: ttsService,
        actionExecutor: executor,
      );

      await controller.openAssistant(currentRoute: '/dashboard');

      final result = await controller.processTextInput('open games');
      expect(result.isSuccess, isTrue);
      expect(navigatedRoute, equals('/games'));

      // Verified speech dispatch
      expect(mockProvider.lastSpokenText, equals('Opening brain games.'));
      expect(mockProvider.lastSpokenLang, equals('en-IN'));

      controller.dispose();
    });
  });
}
