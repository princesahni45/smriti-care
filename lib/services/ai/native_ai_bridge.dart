// lib/services/ai/native_ai_bridge.dart
//
// Native Platform Bridge Interface for On-Device Qwen Execution.
// Communicates across MethodChannel to Kotlin/C++ engine on Android.

import 'package:flutter/services.dart';

abstract class NativeAIBridge {
  Future<bool> checkModelInstalled({required String modelFileName});
  Future<Map<String, dynamic>> getModelStatus();
  Future<bool> loadModel(
      {required String modelPath, required String modelVersion});
  Future<Map<String, dynamic>> infer(
      {required String prompt, int maxTokens = 64});
  Future<void> cancelInference();
  Future<void> unloadModel();
}

/// Production Android MethodChannel Bridge.
class MethodChannelNativeAIBridge implements NativeAIBridge {
  static const MethodChannel _channel =
      MethodChannel('com.smriticare.smriti_care/ai_bridge');

  const MethodChannelNativeAIBridge();

  @override
  Future<bool> checkModelInstalled({required String modelFileName}) async {
    try {
      final res = await _channel.invokeMethod<bool>('checkModelInstalled', {
        'modelFileName': modelFileName,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getModelStatus() async {
    try {
      final res =
          await _channel.invokeMapMethod<String, dynamic>('getModelStatus');
      return res ?? {};
    } catch (_) {
      return {};
    }
  }

  @override
  Future<bool> loadModel({
    required String modelPath,
    required String modelVersion,
  }) async {
    try {
      final res = await _channel.invokeMethod<bool>('loadModel', {
        'modelPath': modelPath,
        'modelVersion': modelVersion,
      });
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> infer({
    required String prompt,
    int maxTokens = 64,
  }) async {
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('infer', {
        'prompt': prompt,
        'maxTokens': maxTokens,
      });
      return res ?? {};
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> cancelInference() async {
    try {
      await _channel.invokeMethod<void>('cancelInference');
    } catch (_) {}
  }

  @override
  Future<void> unloadModel() async {
    try {
      await _channel.invokeMethod<void>('unloadModel');
    } catch (_) {}
  }
}

/// In-Memory Mock Bridge for Automated Unit and Widget Testing.
class MockNativeAIBridge implements NativeAIBridge {
  bool isInstalled = false;
  bool isLoaded = false;
  double simulatedRamMb = 480.0;
  int simulatedLoadTimeMs = 1250;
  int simulatedLatencyMs = 380;
  double simulatedTokensPerSecond = 14.2;
  String? nextInferenceText;
  bool shouldFailInference = false;

  bool useDelays = true;

  @override
  Future<bool> checkModelInstalled({required String modelFileName}) async {
    return isInstalled;
  }

  @override
  Future<Map<String, dynamic>> getModelStatus() async {
    return {
      'isInstalled': isInstalled,
      'isLoaded': isLoaded,
      'ramUsageMb': isLoaded ? simulatedRamMb : 0.0,
      'loadTimeMs': isLoaded ? simulatedLoadTimeMs : 0,
      'tokensPerSecond': isLoaded ? simulatedTokensPerSecond : 0.0,
      'modelSizeMb': isInstalled ? 392.5 : 0.0,
    };
  }

  @override
  Future<bool> loadModel({
    required String modelPath,
    required String modelVersion,
  }) async {
    if (!isInstalled) return false;
    if (useDelays) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    isLoaded = true;
    return true;
  }

  @override
  Future<Map<String, dynamic>> infer({
    required String prompt,
    int maxTokens = 64,
  }) async {
    if (!isLoaded || shouldFailInference) {
      return {
        'success': false,
        'error': 'Model not loaded or inference failed'
      };
    }
    if (useDelays) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    final text = nextInferenceText ??
        'Hello friend. I am glad you are here with us today in peace.';
    return {
      'success': true,
      'text': text,
      'latencyMs': simulatedLatencyMs,
      'tokensGenerated': text.split(' ').length,
      'tokensPerSecond': simulatedTokensPerSecond,
    };
  }

  @override
  Future<void> cancelInference() async {}

  @override
  Future<void> unloadModel() async {
    isLoaded = false;
  }
}
