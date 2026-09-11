// lib/services/tts/native_tts_bridge.dart
//
// Native Android TextToSpeech Bridge Interface and In-Memory Mock.
//
// Binds Flutter to Android's android.speech.tts.TextToSpeech via MethodChannel
// com.smriticare.smriti_care/tts_bridge.

import 'package:flutter/services.dart';
import 'tts_models.dart';

abstract class NativeTTSBridge {
  Future<bool> initTts();
  Future<List<TTSVoice>> getAvailableVoices();
  Future<Map<String, dynamic>> checkLanguageAvailable(
      {required String languageCode});
  Future<bool> speak({
    required String text,
    required String languageCode,
    required double rate,
    required double pitch,
  });
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> setSpeechRate(double rate);
}

class MethodChannelNativeTTSBridge implements NativeTTSBridge {
  static const MethodChannel _channel =
      MethodChannel('com.smriticare.smriti_care/tts_bridge');

  const MethodChannelNativeTTSBridge();

  @override
  Future<bool> initTts() async {
    try {
      final res = await _channel.invokeMethod<bool>('initTts');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<TTSVoice>> getAvailableVoices() async {
    try {
      final res = await _channel
          .invokeListMethod<Map<dynamic, dynamic>>('getAvailableVoices');
      if (res == null) return [];
      return res.map((m) => TTSVoice.fromMap(m)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> checkLanguageAvailable(
      {required String languageCode}) async {
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>(
        'checkLanguageAvailable',
        {'languageCode': languageCode},
      );
      return res ?? {'isAvailable': false, 'status': 'notSupported'};
    } catch (_) {
      return {'isAvailable': false, 'status': 'error'};
    }
  }

  @override
  Future<bool> speak({
    required String text,
    required String languageCode,
    required double rate,
    required double pitch,
  }) async {
    try {
      final res = await _channel.invokeMethod<bool>('speak', {
        'text': text,
        'languageCode': languageCode,
        'rate': rate,
        'pitch': pitch,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _channel.invokeMethod<void>('pause');
    } catch (_) {}
  }

  @override
  Future<void> resume() async {
    try {
      await _channel.invokeMethod<void>('resume');
    } catch (_) {}
  }

  @override
  Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } catch (_) {}
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    try {
      await _channel.invokeMethod<void>('setSpeechRate', {'rate': rate});
    } catch (_) {}
  }
}

/// In-Memory Mock Bridge for Automated Unit and Widget Testing.
class MockNativeTTSBridge implements NativeTTSBridge {
  final Map<String, bool> supportedLanguages;
  final List<TTSVoice> mockVoices;
  bool isSpeaking = false;
  bool isPaused = false;
  double activeRate = 0.75;
  String? lastSpokenUtterance;
  String? lastSpokenLang;

  MockNativeTTSBridge({
    Map<String, bool>? supported,
    List<TTSVoice>? voices,
  })  : supportedLanguages = supported ?? {'en': true, 'hi': true, 'as': false},
        mockVoices = voices ??
            const [
              TTSVoice(
                name: 'en-us-x-sfg-local',
                locale: 'en-US',
                isNetworkConnectionRequired: false,
                quality: 'very_high',
              ),
              TTSVoice(
                name: 'hi-in-x-hie-local',
                locale: 'hi-IN',
                isNetworkConnectionRequired: false,
                quality: 'high',
              ),
            ];

  @override
  Future<bool> initTts() async => true;

  @override
  Future<List<TTSVoice>> getAvailableVoices() async {
    return mockVoices.where((v) => !v.isNetworkConnectionRequired).toList();
  }

  @override
  Future<Map<String, dynamic>> checkLanguageAvailable(
      {required String languageCode}) async {
    final available = supportedLanguages[languageCode] ?? false;
    return {
      'isAvailable': available,
      'status': available ? 'LANG_AVAILABLE' : 'LANG_NOT_SUPPORTED',
      'languageCode': languageCode,
    };
  }

  @override
  Future<bool> speak({
    required String text,
    required String languageCode,
    required double rate,
    required double pitch,
  }) async {
    final available = supportedLanguages[languageCode] ?? false;
    if (!available) return false;

    isSpeaking = true;
    isPaused = false;
    activeRate = rate;
    lastSpokenUtterance = text;
    lastSpokenLang = languageCode;
    return true;
  }

  @override
  Future<void> pause() async {
    if (isSpeaking) {
      isSpeaking = false;
      isPaused = true;
    }
  }

  @override
  Future<void> resume() async {
    if (isPaused) {
      isPaused = false;
      isSpeaking = true;
    }
  }

  @override
  Future<void> stop() async {
    isSpeaking = false;
    isPaused = false;
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    activeRate = rate;
  }
}
