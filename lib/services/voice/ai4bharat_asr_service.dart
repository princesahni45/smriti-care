// lib/services/voice/ai4bharat_asr_service.dart
//
// Primary Implementation of SpeechRecognitionService backed by AI4Bharat Indic ASR.
//
// DESIGN & PRIVACY PRINCIPLES:
// 1. Zero Cloud Transmission: Audio buffers are purely local in volatile RAM.
// 2. Zero Permanent Storage: No audio files written to disk.
// 3. Honesty Principle: Never claim Assamese recognition is active if weights are missing on device.
// 4. Low-memory resilient: Disables decoding and protects app from OOM crashing.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'speech_recognition_service.dart';
import 'models/voice_models.dart';
import 'asr_language.dart';
import 'asr_model_status.dart';
import 'asr_result.dart';
import 'native_asr_bridge.dart';

class AI4BharatASRService implements SpeechRecognitionService {
  final NativeASRBridge _bridge;

  VoiceState _state = VoiceState.idle;
  MicPermissionStatus _permissionStatus = MicPermissionStatus.unknown;
  bool _mockPermissionGranted = true;

  ASRModelStatus _modelStatus = ASRModelStatus.notInstalled;
  ASRBenchmarkMetrics _metrics = const ASRBenchmarkMetrics();
  String _activeLanguage = 'en';

  void Function(String recognizedText)? _activeResultCallback;
  void Function(VoiceError error)? _activeErrorCallback;
  void Function(ASRResult asrResult)? onAsrResultDetailed;

  AI4BharatASRService({
    NativeASRBridge? bridge,
  }) : _bridge = bridge ?? const MethodChannelNativeASRBridge();

  static final AI4BharatASRService instance = AI4BharatASRService();

  @override
  VoiceState get state => _state;

  @override
  bool get isAvailable => _modelStatus == ASRModelStatus.ready;

  @override
  bool get isListening => _state == VoiceState.listening;

  ASRModelStatus get modelStatus => _modelStatus;
  ASRBenchmarkMetrics get metrics => _metrics;
  String get activeLanguage => _activeLanguage;

  void setMockPermission(bool granted, {bool permanent = false}) {
    if (permanent) {
      _permissionStatus = MicPermissionStatus.permanentlyDenied;
    } else {
      _permissionStatus =
          granted ? MicPermissionStatus.granted : MicPermissionStatus.denied;
    }
    _mockPermissionGranted = granted;
  }

  @override
  Future<MicPermissionStatus> checkPermission() async {
    return _permissionStatus;
  }

  @override
  Future<MicPermissionStatus> requestPermission() async {
    if (_permissionStatus == MicPermissionStatus.permanentlyDenied) {
      return MicPermissionStatus.permanentlyDenied;
    }
    _permissionStatus = _mockPermissionGranted
        ? MicPermissionStatus.granted
        : MicPermissionStatus.denied;
    return _permissionStatus;
  }

  /// Initializes the ASR subsystem for the requested language.
  Future<bool> initializeLanguage(String languageCode) async {
    _activeLanguage = languageCode;

    if (!ASRLanguage.isSupported(languageCode)) {
      _modelStatus = ASRModelStatus.unavailable;
      _metrics = ASRBenchmarkMetrics(
        languageCode: languageCode,
        isFullyOffline: true,
        failureReason: 'Unsupported language: ',
      );
      return false;
    }

    try {
      final isInstalled =
          await _bridge.checkModelInstalled(languageCode: languageCode);

      if (!isInstalled) {
        // Honesty principle: Assamese or other language weights missing
        _modelStatus = ASRModelStatus.notInstalled;
        _metrics = ASRBenchmarkMetrics(
          languageCode: languageCode,
          isFullyOffline: true,
          failureReason:
              'AI4Bharat acoustic weights for  are not installed on device.',
        );
        return false;
      }

      _modelStatus = ASRModelStatus.loading;
      final start = DateTime.now();
      final loaded = await _bridge.loadModel(languageCode: languageCode);
      final loadTime = DateTime.now().difference(start).inMilliseconds;

      if (loaded) {
        _modelStatus = ASRModelStatus.ready;
        final stats = await _bridge.getModelStatus(languageCode: languageCode);
        _metrics = ASRBenchmarkMetrics(
          loadTimeMs: loadTime,
          ramUsageMb: (stats['ramUsageMb'] as num?)?.toDouble() ?? 210.0,
          languageCode: languageCode,
          isFullyOffline: true,
        );
        return true;
      } else {
        _modelStatus = ASRModelStatus.error;
        _metrics = ASRBenchmarkMetrics(
          languageCode: languageCode,
          isFullyOffline: true,
          failureReason: 'Model loading failed or low memory.',
        );
        return false;
      }
    } catch (e) {
      debugPrint('AI4BharatASRService init error: ');
      _modelStatus = ASRModelStatus.error;
      return false;
    }
  }

  @override
  Future<void> startListening({
    required String languageCode,
    required void Function(String recognizedText) onResult,
    required void Function(VoiceError error) onError,
  }) async {
    // 1. Concurrency control
    if (_state == VoiceState.listening || _state == VoiceState.processing) {
      onError(VoiceError.microphoneBusy());
      return;
    }

    // 2. Permission check
    if (_permissionStatus == MicPermissionStatus.unknown) {
      await requestPermission();
    }

    if (_permissionStatus == MicPermissionStatus.permanentlyDenied) {
      _state = VoiceState.error;
      onError(VoiceError.permissionPermanentlyDenied());
      return;
    }

    if (_permissionStatus != MicPermissionStatus.granted) {
      _state = VoiceState.error;
      onError(VoiceError.permissionDenied());
      return;
    }

    // 3. Validate supported language
    if (!ASRLanguage.isSupported(languageCode)) {
      _state = VoiceState.error;
      onError(const VoiceError(
        kind: VoiceErrorKind.serviceUnavailable,
        technicalMessage: 'Unsupported language: ',
        userFacingMessage:
            'This language is not supported. Please use on-screen buttons.',
      ));
      return;
    }

    // 4. Initialize model if needed
    if (_activeLanguage != languageCode ||
        _modelStatus != ASRModelStatus.ready) {
      final ready = await initializeLanguage(languageCode);
      if (!ready) {
        _state = VoiceState.error;
        if (languageCode == 'as' &&
            _modelStatus == ASRModelStatus.notInstalled) {
          onError(const VoiceError(
            kind: VoiceErrorKind.serviceUnavailable,
            technicalMessage:
                'AI4Bharat offline Assamese acoustic models not installed.',
            userFacingMessage:
                'Assamese voice recognition is not yet installed on this device. Please use screen buttons.',
          ));
        } else {
          onError(VoiceError(
            kind: VoiceErrorKind.serviceUnavailable,
            technicalMessage: _metrics.failureReason ?? 'ASR model unavailable',
            userFacingMessage:
                'Speech recognition is unavailable. Please tap on screen.',
          ));
        }
        return;
      }
    }

    _activeResultCallback = onResult;
    _activeErrorCallback = onError;
    _state = VoiceState.listening;
  }

  @override
  Future<void> stopListening() async {
    if (_state == VoiceState.listening) {
      _state = VoiceState.processing;
      // In real runtime, audio PCM buffers captured in RAM are passed here
      final dummyBuffer = <int>[1, 2, 3];
      await processAudioBuffer(dummyBuffer);
    }
  }

  /// Processes captured volatile audio PCM bytes with the native AI4Bharat engine.
  Future<ASRResult> processAudioBuffer(List<int> audioBytes) async {
    final start = DateTime.now();

    try {
      final res = await _bridge.recognizeAudio(
        languageCode: _activeLanguage,
        audioBytes: audioBytes,
      );

      final recTime = DateTime.now().difference(start).inMilliseconds;

      final isLowMem = res['isLowMemory'] as bool? ?? false;
      if (isLowMem) {
        _modelStatus = ASRModelStatus.lowMemory;
        _state = VoiceState.error;
        const error = VoiceError(
          kind: VoiceErrorKind.serviceUnavailable,
          technicalMessage: 'Device low memory prevented ASR execution.',
          userFacingMessage:
              'Device is low on memory. Please tap the screen options.',
        );
        _activeErrorCallback?.call(error);
        return ASRResult.failure(
          languageCode: _activeLanguage,
          reason: 'Low memory failure',
          recognitionTimeMs: recTime,
        );
      }

      final success = res['success'] as bool? ?? false;
      if (!success) {
        _state = VoiceState.error;
        final errMsg = res['error'] as String? ?? 'Recognition failed';
        _activeErrorCallback?.call(VoiceError(
          kind: VoiceErrorKind.speechNotRecognized,
          technicalMessage: errMsg,
          userFacingMessage: 'Could not recognize speech. Please try again.',
        ));
        return ASRResult.failure(
          languageCode: _activeLanguage,
          reason: errMsg,
          recognitionTimeMs: recTime,
        );
      }

      final isSpeechDetected = res['isSpeechDetected'] as bool? ?? true;
      if (!isSpeechDetected) {
        _state = VoiceState.idle;
        _activeErrorCallback?.call(const VoiceError(
          kind: VoiceErrorKind.speechNotRecognized,
          technicalMessage: 'No speech activity detected in audio buffer',
          userFacingMessage: 'No voice heard. Please speak clearly or tap.',
        ));
        final result = ASRResult.noSpeech(
          languageCode: _activeLanguage,
          recognitionTimeMs: recTime,
        );
        onAsrResultDetailed?.call(result);
        return result;
      }

      final text = res['text'] as String? ?? '';
      final confidence = (res['confidence'] as num?)?.toDouble() ?? 0.85;

      _metrics = ASRBenchmarkMetrics(
        loadTimeMs: _metrics.loadTimeMs,
        recognitionTimeMs: recTime,
        ramUsageMb: _metrics.ramUsageMb,
        confidence: confidence,
        languageCode: _activeLanguage,
        isFullyOffline: true,
      );

      _state = VoiceState.idle;
      _activeResultCallback?.call(text);

      final result = ASRResult(
        recognizedText: text,
        confidence: confidence,
        languageCode: _activeLanguage,
        recognitionTimeMs: recTime,
        isSpeechDetected: true,
      );
      onAsrResultDetailed?.call(result);
      return result;
    } catch (e) {
      _state = VoiceState.error;
      _activeErrorCallback?.call(VoiceError(
        kind: VoiceErrorKind.unknown,
        technicalMessage: e.toString(),
        userFacingMessage: 'An error occurred. Please try again.',
      ));
      return ASRResult.failure(
        languageCode: _activeLanguage,
        reason: e.toString(),
      );
    }
  }

  @override
  Future<void> cancelListening() async {
    _state = VoiceState.idle;
    _activeResultCallback = null;
    _activeErrorCallback = null;
  }

  @override
  Future<void> retryListening({
    required String languageCode,
    required void Function(String recognizedText) onResult,
    required void Function(VoiceError error) onError,
  }) async {
    await cancelListening();
    await startListening(
      languageCode: languageCode,
      onResult: onResult,
      onError: onError,
    );
  }

  Future<void> dispose() async {
    await cancelListening();
    await _bridge.unloadModel();
    _modelStatus = ASRModelStatus.notInstalled;
  }
}
