// lib/services/voice/placeholder_speech_recognition_service.dart
//
// Baseline implementation of SpeechRecognitionService.
//
// STATUS:
// - Micro-permission and session safety state machines implemented.
// - Concurrency prevention (single active session enforcement).
// - Start, stop, cancel, and retry lifecycle implemented.
// - Offline Assamese speech recognition is explicitly NOT claimed to be active.
// - Audio is NEVER sent to an external server or stored permanently.

import 'dart:async';
import 'models/voice_models.dart';
import 'speech_recognition_service.dart';

class PlaceholderSpeechRecognitionService implements SpeechRecognitionService {
  VoiceState _state = VoiceState.idle;
  MicPermissionStatus _permissionStatus = MicPermissionStatus.unknown;
  bool _mockPermissionGranted = true;

  void Function(String)? _activeResultCallback;

  @override
  VoiceState get state => _state;

  @override
  bool get isAvailable => true;

  @override
  bool get isListening => _state == VoiceState.listening;

  /// Test helper to simulate permission revocation in tests.
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

  @override
  Future<void> startListening({
    required String languageCode,
    required void Function(String recognizedText) onResult,
    required void Function(VoiceError error) onError,
  }) async {
    // 1. Concurrency control: prevent multiple simultaneous recordings
    if (_state == VoiceState.listening || _state == VoiceState.processing) {
      onError(VoiceError.microphoneBusy());
      return;
    }

    // 2. Permission verification
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

    // 3. Cache session parameters
    _activeResultCallback = onResult;
    _state = VoiceState.listening;

    // 4. Note on offline Assamese recognition:
    // Native on-device STT for Assamese is planned for AI4Bharat integration
    // and is not yet connected.
    if (languageCode == 'as') {
      // Transition gracefully without claiming active live Assamese transcription
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_state == VoiceState.listening) {
          _state = VoiceState.idle;
          onError(const VoiceError(
            kind: VoiceErrorKind.serviceUnavailable,
            technicalMessage:
                'AI4Bharat offline Assamese acoustic models are not yet connected.',
            userFacingMessage:
                'Assamese voice recognition is planned. Please tap on the screen buttons.',
          ));
        }
      });
      return;
    }
  }

  @override
  Future<void> stopListening() async {
    if (_state == VoiceState.listening) {
      _state = VoiceState.processing;
      // Discard any audio buffers; no files written
      await Future.delayed(const Duration(milliseconds: 50));
      _state = VoiceState.idle;
    }
  }

  @override
  Future<void> cancelListening() async {
    _state = VoiceState.idle;
    _activeResultCallback = null;
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

  /// Test hook to simulate a recognized voice utterance
  void simulateSpeechRecognized(String text) {
    if (_state == VoiceState.listening) {
      _state = VoiceState.processing;
      _activeResultCallback?.call(text);
      _state = VoiceState.idle;
    }
  }
}
