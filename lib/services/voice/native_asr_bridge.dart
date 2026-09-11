// lib/services/voice/native_asr_bridge.dart
//
// Native Bridge Interface for AI4Bharat On-Device ASR.
// Connects Flutter to Android MethodChannel com.smriticare.smriti_care/asr_bridge.

import 'package:flutter/services.dart';

abstract class NativeASRBridge {
  Future<bool> checkModelInstalled({required String languageCode});
  Future<bool> loadModel({required String languageCode});
  Future<Map<String, dynamic>> recognizeAudio({
    required String languageCode,
    required List<int> audioBytes,
  });
  Future<Map<String, dynamic>> getModelStatus({required String languageCode});
  Future<void> unloadModel();
}

/// Production Android MethodChannel Bridge for AI4Bharat ASR.
class MethodChannelNativeASRBridge implements NativeASRBridge {
  static const MethodChannel _channel =
      MethodChannel('com.smriticare.smriti_care/asr_bridge');

  const MethodChannelNativeASRBridge();

  @override
  Future<bool> checkModelInstalled({required String languageCode}) async {
    try {
      final res = await _channel.invokeMethod<bool>('checkAsrModelInstalled', {
        'languageCode': languageCode,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> loadModel({required String languageCode}) async {
    try {
      final res = await _channel.invokeMethod<bool>('loadAsrModel', {
        'languageCode': languageCode,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> recognizeAudio({
    required String languageCode,
    required List<int> audioBytes,
  }) async {
    try {
      final res =
          await _channel.invokeMapMethod<String, dynamic>('recognizeAudio', {
        'languageCode': languageCode,
        'audioBytes': audioBytes,
      });
      return res ?? {};
    } catch (_) {
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> getModelStatus(
      {required String languageCode}) async {
    try {
      final res =
          await _channel.invokeMapMethod<String, dynamic>('getAsrModelStatus', {
        'languageCode': languageCode,
      });
      return res ?? {};
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> unloadModel() async {
    try {
      await _channel.invokeMethod<void>('unloadAsrModel');
    } catch (_) {}
  }
}

/// In-Memory Mock Bridge for Automated Testing of AI4Bharat ASR Subsystem.
class MockNativeASRBridge implements NativeASRBridge {
  final Map<String, bool> installedLanguages;
  final Map<String, bool> loadedLanguages;
  bool simulateLowMemory = false;
  bool simulateNoSpeech = false;
  bool simulateDecodeFailure = false;
  String? mockRecognizedText;
  double mockConfidence = 0.92;
  int mockLoadTimeMs = 280;
  int mockRecognitionTimeMs = 310;
  double mockRamUsageMb = 215.0;

  MockNativeASRBridge({
    Map<String, bool>? installed,
    Map<String, bool>? loaded,
  })  : installedLanguages = installed ?? {'en': true, 'hi': true, 'as': false},
        loadedLanguages = loaded ?? {};

  @override
  Future<bool> checkModelInstalled({required String languageCode}) async {
    return installedLanguages[languageCode] ?? false;
  }

  @override
  Future<bool> loadModel({required String languageCode}) async {
    if (simulateLowMemory) return false;
    final isInstalled = installedLanguages[languageCode] ?? false;
    if (!isInstalled) return false;

    loadedLanguages[languageCode] = true;
    return true;
  }

  @override
  Future<Map<String, dynamic>> recognizeAudio({
    required String languageCode,
    required List<int> audioBytes,
  }) async {
    if (simulateLowMemory) {
      return {
        'success': false,
        'error': 'Low memory condition detected',
        'isLowMemory': true,
      };
    }

    if (simulateDecodeFailure) {
      return {
        'success': false,
        'error': 'Acoustic decoding failure',
      };
    }

    if (simulateNoSpeech || audioBytes.isEmpty) {
      return {
        'success': true,
        'isSpeechDetected': false,
        'text': '',
        'confidence': 0.0,
        'recognitionTimeMs': mockRecognitionTimeMs,
      };
    }

    String defaultText;
    switch (languageCode) {
      case 'hi':
        defaultText = 'मुझे घर जाना है';
        break;
      case 'as':
        defaultText = 'মই ঘৰলৈ যাব বিচাৰোঁ';
        break;
      case 'en':
      default:
        defaultText = 'Help me go home';
        break;
    }

    return {
      'success': true,
      'isSpeechDetected': true,
      'text': mockRecognizedText ?? defaultText,
      'confidence': mockConfidence,
      'recognitionTimeMs': mockRecognitionTimeMs,
    };
  }

  @override
  Future<Map<String, dynamic>> getModelStatus(
      {required String languageCode}) async {
    final isLoaded = loadedLanguages[languageCode] ?? false;
    final isInstalled = installedLanguages[languageCode] ?? false;

    return {
      'isInstalled': isInstalled,
      'isLoaded': isLoaded,
      'ramUsageMb': isLoaded ? mockRamUsageMb : 0.0,
      'loadTimeMs': isLoaded ? mockLoadTimeMs : 0,
      'isLowMemory': simulateLowMemory,
      'isFullyOffline': true,
    };
  }

  @override
  Future<void> unloadModel() async {
    loadedLanguages.clear();
  }
}
