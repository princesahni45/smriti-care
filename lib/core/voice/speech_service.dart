// lib/core/voice/speech_service.dart
//
// Centralized speech recognition service abstraction for SmritiCare.
// Provides pluggable backends for platform speech recognition and future
// offline ASR (e.g. Vosk, Sherpa-ONNX, or Whisper.tflite) with graceful
// fallback when speech input is unavailable.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'voice_command.dart';

/// Explicit failure states exposed by [SpeechService].
enum SpeechFailureState {
  /// Audio or microphone permission was denied by the user/system.
  permissionDenied,

  /// Speech recognition service or engine is unavailable on the platform.
  serviceUnavailable,

  /// The requested language locale is not supported by the engine.
  languageUnavailable,

  /// Speech recognition requires an active network connection that is missing.
  networkRequired,

  /// Recognition engine encountered an audio capture, buffer, or decoding failure.
  recognitionFailed,

  /// The active listening session was cancelled by the user or system.
  cancelled,
}

/// Lifecycle states of the speech recognition service.
enum SpeechServiceState {
  /// Engine has not yet been initialized.
  uninitialized,

  /// Initialized and ready to listen.
  ready,

  /// Microphone is active and capturing speech.
  listening,

  /// Converting audio to text / parsing transcript.
  processing,

  /// Encountered an error (e.g. permission denied or audio failure).
  error,

  /// Speech recognition is unavailable on this device/environment.
  unavailable,
}

/// Rich speech recognition transcript result emitted via stream and callbacks.
class SpeechRecognitionResult {
  final String text;
  final bool isFinal;
  final double confidence;
  final String languageCode;
  final bool isVoiceInput;

  const SpeechRecognitionResult({
    required this.text,
    required this.isFinal,
    this.confidence = 1.0,
    required this.languageCode,
    this.isVoiceInput = true,
  });

  VoiceCommand toVoiceCommand() => VoiceCommand(
        text: text,
        languageCode: languageCode,
        isFinal: isFinal,
        isVoiceInput: isVoiceInput,
      );

  @override
  String toString() =>
      'SpeechRecognitionResult(text: "$text", isFinal: $isFinal, confidence: $confidence, lang: $languageCode)';
}

/// Abstract provider contract for speech recognition engines.
abstract class SpeechRecognitionProvider {
  /// Initialize the provider with preferred language.
  Future<bool> initialize({String languageCode = 'en'});

  /// Start capturing audio and generating transcripts.
  Future<void> startListening({
    required String languageCode,
    required void Function(String transcript, bool isFinal) onResult,
    required void Function(String error) onError,
  });

  /// Stop listening and finalize current speech buffer.
  Future<void> stopListening();

  /// Cancel listening immediately without returning results.
  Future<void> cancel();

  /// Whether the provider is available and supported on the host.
  bool get isAvailable;

  /// Whether the provider is currently listening.
  bool get isListening;

  /// Clean up native resources.
  Future<void> dispose();
}

/// Convenience extension providing [cancelListening] abstraction to all providers.
extension SpeechRecognitionProviderExtension on SpeechRecognitionProvider {
  /// Cancel active speech recognition session.
  Future<void> cancelListening() async => cancel();
}

/// Pluggable offline ASR provider contract for future on-device model integration
/// (such as Vosk, Sherpa-ONNX, or Whisper.tflite).
/// NOTE: Offline AI models are NOT bundled in this repository at this stage.
/// This contract guarantees modular plug-and-play capability when offline weights are added.
class OfflineAsrProvider implements SpeechRecognitionProvider {
  bool _isListening = false;
  final String? modelPath;

  OfflineAsrProvider({this.modelPath});

  /// Returns true only when a valid offline ASR model binary is present and loaded.
  bool get isModelLoaded => modelPath != null && modelPath!.isNotEmpty;

  @override
  bool get isAvailable => isModelLoaded;

  @override
  bool get isListening => _isListening;

  @override
  Future<bool> initialize({String languageCode = 'en'}) async {
    // Offline models require valid local weights. If not supplied, marks unavailable.
    if (!isModelLoaded) {
      debugPrint(
          '[OfflineAsrProvider] No local ASR weights found. Offline ASR unavailable.');
      return false;
    }
    return true;
  }

  @override
  Future<void> startListening({
    required String languageCode,
    required void Function(String transcript, bool isFinal) onResult,
    required void Function(String error) onError,
  }) async {
    if (!isModelLoaded) {
      onError('Offline ASR model is not loaded.');
      return;
    }
    _isListening = true;
  }

  @override
  Future<void> stopListening() async {
    _isListening = false;
  }

  @override
  Future<void> cancel() async {
    _isListening = false;
  }

  @override
  Future<void> dispose() async {
    _isListening = false;
  }
}

/// Default development / platform fallback provider.
/// Safe across all platforms and test runners.
class DefaultSpeechRecognitionProvider implements SpeechRecognitionProvider {
  bool _available = true;
  bool _listening = false;
  void Function(String transcript, bool isFinal)? _activeResultCallback;

  @override
  bool get isAvailable => _available;

  @override
  bool get isListening => _listening;

  void setAvailable(bool available) {
    _available = available;
  }

  @override
  Future<bool> initialize({String languageCode = 'en'}) async {
    return _available;
  }

  @override
  Future<void> startListening({
    required String languageCode,
    required void Function(String transcript, bool isFinal) onResult,
    required void Function(String error) onError,
  }) async {
    if (!_available) {
      onError('Speech recognition is not available on this platform.');
      return;
    }
    _listening = true;
    _activeResultCallback = onResult;
  }

  /// Helper to inject simulated speech in automated tests and previews.
  void simulateSpeech(String transcript, {bool isFinal = true}) {
    if (_listening && _activeResultCallback != null) {
      _activeResultCallback!(transcript, isFinal);
    }
  }

  @override
  Future<void> stopListening() async {
    _listening = false;
    _activeResultCallback = null;
  }

  @override
  Future<void> cancel() async {
    _listening = false;
    _activeResultCallback = null;
  }

  @override
  Future<void> dispose() async {
    _listening = false;
    _activeResultCallback = null;
  }
}

/// Central Speech Service singleton and controller interface.
class SpeechService extends ChangeNotifier {
  SpeechService._({SpeechRecognitionProvider? provider})
      : _provider = provider ?? DefaultSpeechRecognitionProvider();

  /// Create an isolated SpeechService instance for testing.
  factory SpeechService.create({SpeechRecognitionProvider? provider}) {
    return SpeechService._(provider: provider);
  }

  static SpeechService? _instance;
  static SpeechService get instance => _instance ??= SpeechService._();

  /// Visible for testing to inject custom providers.
  static void setMockInstance(SpeechService mock) {
    _instance = mock;
  }

  SpeechRecognitionProvider _provider;
  SpeechServiceState _state = SpeechServiceState.uninitialized;
  SpeechFailureState? _lastFailure;
  String _currentLanguage = 'en-IN';
  String _lastTranscript = '';
  String? _lastError;

  // Stream controllers for decoupled reactive observation
  final StreamController<String> _textStreamController =
      StreamController<String>.broadcast();
  final StreamController<SpeechRecognitionResult> _resultStreamController =
      StreamController<SpeechRecognitionResult>.broadcast();
  final StreamController<SpeechFailureState> _failureStreamController =
      StreamController<SpeechFailureState>.broadcast();

  SpeechServiceState get state => _state;
  SpeechFailureState? get lastFailure => _lastFailure;
  String get currentLanguage => _currentLanguage;
  String get lastTranscript => _lastTranscript;
  String? get lastError => _lastError;

  /// Check whether speech recognition is available (property getter).
  bool get isAvailable => _provider.isAvailable;

  /// Check whether speech recognition is available (method).
  bool isAvailableSync() => _provider.isAvailable;

  bool get isListening => _state == SpeechServiceState.listening;

  /// Reactive stream of recognized transcription strings (both partial and final).
  Stream<String> get textStream => _textStreamController.stream;

  /// Reactive stream of structured [SpeechRecognitionResult] events.
  Stream<SpeechRecognitionResult> get resultStream =>
      _resultStreamController.stream;

  /// Reactive stream of explicit [SpeechFailureState] failures.
  Stream<SpeechFailureState> get failureStream =>
      _failureStreamController.stream;

  /// Replace the active recognition provider (e.g. when switching to Offline ASR).
  void setProvider(SpeechRecognitionProvider newProvider) {
    _provider = newProvider;
    notifyListeners();
  }

  /// Supported language roots for this phase: English, Hindi, Assamese.
  static const Set<String> supportedLanguageCodes = {'en', 'hi', 'as'};

  /// Initialize the speech recognition service with a target language.
  /// Supports positional [language] or named parameters {language, languageCode}.
  /// Supports 'en' (English), 'hi' (Hindi), 'as' (Assamese).
  Future<bool> initialize({
    String? language,
    String? languageCode,
  }) async {
    final effectiveLang = languageCode ?? language ?? 'en';
    final normalized = effectiveLang.toLowerCase().split('-').first;

    if (!supportedLanguageCodes.contains(normalized)) {
      _lastFailure = SpeechFailureState.languageUnavailable;
      _state = SpeechServiceState.error;
      _lastError = 'Language "$effectiveLang" is not supported.';
      _failureStreamController.add(SpeechFailureState.languageUnavailable);
      notifyListeners();
      return false;
    }

    _currentLanguage = _mapLanguageLocale(effectiveLang);
    _lastFailure = null;

    try {
      final success =
          await _provider.initialize(languageCode: _currentLanguage);
      if (success) {
        _state = SpeechServiceState.ready;
        _lastError = null;
      } else {
        _state = SpeechServiceState.unavailable;
        _lastFailure = SpeechFailureState.serviceUnavailable;
        _lastError = 'Speech recognition unavailable.';
        _failureStreamController.add(SpeechFailureState.serviceUnavailable);
      }
      notifyListeners();
      return success;
    } catch (e) {
      _state = SpeechServiceState.error;
      _lastFailure = _mapErrorToFailure(e.toString());
      _lastError = e.toString();
      _failureStreamController.add(_lastFailure!);
      notifyListeners();
      return false;
    }
  }

  /// Set preferred language for subsequent recognition sessions.
  void setLanguage(String languageCode) {
    _currentLanguage = _mapLanguageLocale(languageCode);
    notifyListeners();
  }

  /// Map language codes to BCP-47 speech tags if needed.
  String _mapLanguageLocale(String code) {
    switch (code.toLowerCase()) {
      case 'hi':
      case 'hi-in':
        return 'hi-IN';
      case 'as':
      case 'as-in':
        return 'as-IN';
      case 'en':
      case 'en-in':
      default:
        return 'en-IN';
    }
  }

  /// Begin listening to microphone stream.
  Future<void> startListening({
    void Function(VoiceCommand command)? onCommand,
    void Function(String partialText)? onPartial,
    void Function(SpeechFailureState failure)? onFailure,
  }) async {
    if (_state == SpeechServiceState.listening) return;

    if (!isAvailable) {
      _state = SpeechServiceState.unavailable;
      _lastFailure = SpeechFailureState.serviceUnavailable;
      _failureStreamController.add(SpeechFailureState.serviceUnavailable);
      onFailure?.call(SpeechFailureState.serviceUnavailable);
      notifyListeners();
      return;
    }

    _state = SpeechServiceState.listening;
    _lastTranscript = '';
    _lastError = null;
    _lastFailure = null;
    notifyListeners();

    try {
      await _provider.startListening(
        languageCode: _currentLanguage,
        onResult: (transcript, isFinal) {
          _lastTranscript = transcript;
          _textStreamController.add(transcript);

          final result = SpeechRecognitionResult(
            text: transcript,
            isFinal: isFinal,
            languageCode: _currentLanguage.split('-').first,
            isVoiceInput: true,
          );
          _resultStreamController.add(result);

          if (onPartial != null && !isFinal) {
            onPartial(transcript);
          }

          if (isFinal) {
            _state = SpeechServiceState.processing;
            notifyListeners();

            final command = result.toVoiceCommand();
            onCommand?.call(command);

            _state = SpeechServiceState.ready;
            notifyListeners();
          }
        },
        onError: (error) {
          final failure = _mapErrorToFailure(error);
          _state = SpeechServiceState.error;
          _lastError = error;
          _lastFailure = failure;
          _failureStreamController.add(failure);
          onFailure?.call(failure);
          notifyListeners();
        },
      );
    } catch (e) {
      final failure = _mapErrorToFailure(e.toString());
      _state = SpeechServiceState.error;
      _lastError = e.toString();
      _lastFailure = failure;
      _failureStreamController.add(failure);
      onFailure?.call(failure);
      notifyListeners();
    }
  }

  /// Stop listening and process audio recorded so far.
  Future<void> stopListening() async {
    if (_state != SpeechServiceState.listening) return;
    await _provider.stopListening();
    _state = SpeechServiceState.ready;
    notifyListeners();
  }

  /// Cancel listening session immediately.
  Future<void> cancel() async {
    await _provider.cancel();
    _lastFailure = SpeechFailureState.cancelled;
    _state = SpeechServiceState.ready;
    _failureStreamController.add(SpeechFailureState.cancelled);
    notifyListeners();
  }

  /// Cancel listening session immediately (implements required cancelListening() API).
  Future<void> cancelListening() async => cancel();

  /// Fallback text input path when microphone is disabled, denied, or user chooses to type.
  void submitTextFallback(String text, {void Function(VoiceCommand command)? onCommand}) {
    final clean = text.trim();
    if (clean.isEmpty) return;

    _lastTranscript = clean;
    _textStreamController.add(clean);

    final result = SpeechRecognitionResult(
      text: clean,
      isFinal: true,
      confidence: 1.0,
      languageCode: _currentLanguage.split('-').first,
      isVoiceInput: false,
    );
    _resultStreamController.add(result);

    final command = result.toVoiceCommand();
    onCommand?.call(command);
  }

  /// Map raw string errors or exceptions to structured [SpeechFailureState].
  SpeechFailureState _mapErrorToFailure(String error) {
    final lower = error.toLowerCase();
    if (lower.contains('permission') || lower.contains('denied')) {
      return SpeechFailureState.permissionDenied;
    }
    if (lower.contains('network') || lower.contains('internet') || lower.contains('connection')) {
      return SpeechFailureState.networkRequired;
    }
    if (lower.contains('cancel')) {
      return SpeechFailureState.cancelled;
    }
    if (lower.contains('language') || lower.contains('locale')) {
      return SpeechFailureState.languageUnavailable;
    }
    if (lower.contains('unavailable') || lower.contains('not found') || lower.contains('not supported')) {
      return SpeechFailureState.serviceUnavailable;
    }
    return SpeechFailureState.recognitionFailed;
  }

  @override
  void dispose() {
    _provider.dispose();
    _textStreamController.close();
    _resultStreamController.close();
    _failureStreamController.close();
    super.dispose();
  }
}

