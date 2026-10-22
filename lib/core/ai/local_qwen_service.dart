// lib/core/ai/local_qwen_service.dart
//
// Qwen-ready abstraction for real offline on-device inference on Android.
//
// Architecture & Safety Constraints:
// - Operates strictly on-device without internet access.
// - Does not control navigation directly; outputs are mapped exclusively to VoiceIntent.
// - Does not modify medicines, patient records, caregiver settings, or delete data.
// - Returns a clear notInstalled/unavailable result when model weights or runtime are absent.
// - Does NOT generate fake Qwen responses or mock running inference.
// - Does NOT use cloud services, Gemini, or remote endpoints.

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';
import 'ai_service.dart';
import 'ai_context_builder.dart';
import 'ai_response_validator.dart';

/// On-device Qwen SLM service implementation for SmritiCare.
class LocalQwenService implements AiService {
  /// Default GGUF model filename for offline inference.
  /// Configurable between Qwen3.5-0.8B (unverified) and Qwen2.5-0.5B (verified fallback).
  static const String defaultModelFileName =
    'qwen2.5-0.5b-instruct-q4_k_m.gguf';

  static const String fallbackModelFileName =
    'qwen2.5-0.5b-instruct-q4_k_m.gguf';

  /// Path to the offline Qwen model binary on device storage (e.g. .gguf).
  final String? modelPath;

  /// Validator that parses and ensures safety of raw SLM tokens.
  final AiResponseValidator validator;

  AiServiceStatus _status = AiServiceStatus.uninitialized;
  String? _lastError;
  LlamaController? _llamaController;

  LocalQwenService({
    this.modelPath,
    AiResponseValidator? validator,
  }) : validator = validator ?? const AiResponseValidator();

  /// Verifies whether an actual local Qwen model binary exists on the file system.
  bool get isModelInstalled {
    if (modelPath == null || modelPath!.trim().isEmpty) {
      return false;
    }
    try {
      final file = File(modelPath!);
      return file.existsSync();
    } catch (_) {
      return false;
    }
  }

  @override
  AiServiceStatus get status => _status;

  @override
  bool get isAvailable => _status == AiServiceStatus.ready;

  String? get lastError => _lastError;

  @override
  Future<bool> initialize() async {
    _lastError = null;

    if (!isModelInstalled) {
      _status = AiServiceStatus.notInstalled;
      _lastError =
          'Local Qwen model weights are not installed at path: $modelPath';
      debugPrint('[LocalQwenService] $_lastError');
      return false;
    }

    // On non-Android platforms (e.g. Web or desktop unit tests), mark ready without native JNI
if (kIsWeb || !Platform.isAndroid) {
  _status = AiServiceStatus.unavailable;
  _lastError = 'Local Qwen inference is supported only on Android.';
  return false;
}

    try {
      _llamaController = LlamaController();
      await _llamaController!.loadModel(
        modelPath: modelPath!,
        threads: 4,
        contextSize: 1024,
      );
      _status = AiServiceStatus.ready;
      return true;
    } catch (e) {
      _status = AiServiceStatus.unavailable;
      _lastError = 'Native engine initialization error: $e';
      debugPrint('[LocalQwenService] $_lastError');
      return false;
    }
  }

  @override
  Future<AiInferenceResult> inferIntent({
    required String prompt,
    required AiContext context,
  }) async {
    // 1. Verify model installation
    if (!isModelInstalled) {
      _status = AiServiceStatus.notInstalled;
      return AiInferenceResult.notInstalled(
        message:
            'Local Qwen model weights are not installed. Offline inference unavailable.',
      );
    }

    // 2. Non-Android host / test fallback: do not fake AI responses
    if (kIsWeb || !Platform.isAndroid) {
      return AiInferenceResult.unavailable(
        message:
            'Native on-device Qwen runtime engine is not linked in this build phase.',
      );
    }

    // 3. Verify ready status
    if (_status != AiServiceStatus.ready || _llamaController == null) {
      return AiInferenceResult.unavailable(
        message:
            'Local Qwen service is not in ready state (Current status: $_status).',
      );
    }

    // 4. Real on-device ChatML inference
    try {
      final chatMlPrompt =
          '<|im_start|>system\n${context.formattedPromptContext}<|im_end|>\n'
          '<|im_start|>user\n$prompt<|im_end|>\n'
          '<|im_start|>assistant\n';

      final buffer = StringBuffer();
      final completer = Completer<String>();

      final subscription = _llamaController!.generate(
        prompt: chatMlPrompt,
        maxTokens: 32,
        temperature: 0.1,
      ).listen(
        (token) => buffer.write(token),
        onError: (e) {
          if (!completer.isCompleted) completer.completeError(e);
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete(buffer.toString());
        },
        cancelOnError: true,
      );

      final rawOutput = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          subscription.cancel();
          return buffer.toString();
        },
      );

      final mappedIntent = validator.validateAndMap(
        rawOutput: rawOutput,
        context: context,
        originalUserPrompt: prompt,
      );

      return AiInferenceResult.success(
        rawOutput: rawOutput,
        mappedIntent: mappedIntent,
      );
    } catch (e) {
      return AiInferenceResult.failure(
        errorMessage: 'Local inference error: $e',
      );
    }
  }

  @override
Future<void> dispose() async {
  await _llamaController?.dispose();
  _llamaController = null;
  _status = AiServiceStatus.uninitialized;
}
}

