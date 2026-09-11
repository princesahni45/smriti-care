// lib/core/ai/local_qwen_service.dart
//
// Qwen-ready abstraction for future real offline on-device inference.
//
// Architecture & Safety Constraints:
// - Operates strictly on-device without internet access.
// - Does not control navigation directly; outputs are mapped exclusively to VoiceIntent.
// - Does not modify medicines, patient records, caregiver settings, or delete data.
// - Returns a clear notInstalled/unavailable result when model weights or runtime are absent.
// - Does NOT generate fake Qwen responses or mock running inference.
// - Does NOT use cloud services, Gemini, or remote endpoints.
// - Ready for real on-device engine (e.g. ONNX / llama.cpp) integration in a future phase.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'ai_service.dart';
import 'ai_context_builder.dart';
import 'ai_response_validator.dart';

/// On-device Qwen SLM service implementation for SmritiCare.
class LocalQwenService implements AiService {
  /// Path to the offline Qwen model binary on device storage (e.g. .gguf or .onnx).
  final String? modelPath;

  /// Validator that parses and ensures safety of raw SLM tokens.
  final AiResponseValidator validator;

  AiServiceStatus _status = AiServiceStatus.uninitialized;
  String? _lastError;

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

    // In a future phase, the native on-device runtime (e.g. llama.cpp or ONNX)
    // will be loaded here. For now, without native JNI/C++ bindings in this phase,
    // the service marks ready only when valid model files exist.
    _status = AiServiceStatus.ready;
    return true;
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

    // 2. Verify ready status
    if (_status != AiServiceStatus.ready) {
      return AiInferenceResult.unavailable(
        message:
            'Local Qwen service is not in ready state (Current status: $_status).',
      );
    }

    // 3. Future Real On-Device Inference Pipeline:
    // Native runtime execution happens strictly on-device without internet.
    // Per requirements: No fake Qwen responses and no mock that pretends Qwen is running.
    // When the actual native runtime is linked, native inference will produce raw text.
    // Until native inference bindings are provided, the engine reports unavailable.
    return AiInferenceResult.unavailable(
      message:
          'Native on-device Qwen runtime engine is not linked in this build phase.',
    );
  }

  @override
  Future<void> dispose() async {
    _status = AiServiceStatus.uninitialized;
  }
}
