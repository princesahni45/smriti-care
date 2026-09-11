// lib/services/voice/speech_recognition_service.dart
//
// Asynchronous interface for Speech-to-Text / Speech Recognition foundation.
//
// REQUIREMENTS:
// 1. Asynchronous contracts.
// 2. Microphone permission handling (granted, denied, permanently denied).
// 3. Elderly-friendly permission messaging.
// 4. Start, stop, cancel, and retry operations.
// 5. Concurrency control: prevents multiple simultaneous recordings.
// 6. Zero server transmission of raw audio.
// 7. Zero permanent storage of microphone recordings.

import 'models/voice_models.dart';

enum MicPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  unknown,
}

abstract class SpeechRecognitionService {
  /// Current state of the voice engine.
  VoiceState get state;

  /// Whether speech recognition is currently available on device.
  bool get isAvailable;

  /// Whether currently actively listening to the microphone.
  bool get isListening;

  /// Checks the current microphone permission status without prompting.
  Future<MicPermissionStatus> checkPermission();

  /// Requests microphone permission from the user or OS.
  Future<MicPermissionStatus> requestPermission();

  /// Starts listening for voice commands in the given language.
  ///
  /// Guarantees that only one session can record at any given time.
  Future<void> startListening({
    required String languageCode,
    required void Function(String recognizedText) onResult,
    required void Function(VoiceError error) onError,
  });

  /// Stops listening and processes any captured audio.
  Future<void> stopListening();

  /// Cancels the current session immediately and discards any buffers.
  Future<void> cancelListening();

  /// Retries a failed or timed-out session with the same parameters.
  Future<void> retryListening({
    required String languageCode,
    required void Function(String recognizedText) onResult,
    required void Function(VoiceError error) onError,
  });
}
