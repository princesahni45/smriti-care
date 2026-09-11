// test/speech_service_test.dart
//
// Comprehensive unit tests for SpeechService abstraction:
// 1. initialize(language) supporting English ('en'), Hindi ('hi'), and Assamese ('as').
// 2. startListening(), stopListening(), cancelListening().
// 3. isAvailable() method and isAvailable getter.
// 4. Stream and return recognized text (textStream, resultStream, onCommand).
// 5. Explicit failure states:
//    - permissionDenied
//    - serviceUnavailable
//    - languageUnavailable
//    - networkRequired
//    - recognitionFailed
//    - cancelled
// 6. No hard-coding of speech engines (pluggable provider contract).
// 7. Voice Assistant Controller communicates only through SpeechService.
// 8. Fallback text input path (submitTextFallback).
// 9. Offline ASR provider contract: does not claim offline recognition without actual weights.

import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_care/core/voice/voice.dart';

/// Test provider implementing [SpeechRecognitionProvider] with programmatic control.
class _MockSpeechProvider implements SpeechRecognitionProvider {
  bool available = true;
  bool listening = false;
  String currentLang = 'en';
  void Function(String transcript, bool isFinal)? onResultCallback;
  void Function(String error)? onErrorCallback;

  @override
  bool get isAvailable => available;

  @override
  bool get isListening => listening;

  @override
  Future<bool> initialize({String languageCode = 'en'}) async {
    currentLang = languageCode;
    return available;
  }

  @override
  Future<void> startListening({
    required String languageCode,
    required void Function(String transcript, bool isFinal) onResult,
    required void Function(String error) onError,
  }) async {
    if (!available) {
      onError('Service unavailable on this host');
      return;
    }
    listening = true;
    currentLang = languageCode;
    onResultCallback = onResult;
    onErrorCallback = onError;
  }

  @override
  Future<void> stopListening() async {
    listening = false;
    onResultCallback = null;
    onErrorCallback = null;
  }

  @override
  Future<void> cancel() async {
    listening = false;
    onResultCallback = null;
    onErrorCallback = null;
  }

  @override
  Future<void> dispose() async {
    listening = false;
  }

  void emitTranscript(String transcript, {bool isFinal = true}) {
    if (listening && onResultCallback != null) {
      onResultCallback!(transcript, isFinal);
    }
  }

  void emitError(String error) {
    if (listening && onErrorCallback != null) {
      onErrorCallback!(error);
    }
  }
}

void main() {
  late _MockSpeechProvider mockProvider;
  late SpeechService speechService;

  setUp(() {
    mockProvider = _MockSpeechProvider();
    mockProvider.available = true;
    speechService = SpeechService.create(provider: mockProvider);
  });

  tearDown(() {
    speechService.dispose();
  });

  group('SpeechService Initialization & Supported Languages', () {
    test('Initializes successfully with English (en / en-IN)', () async {
      final success = await speechService.initialize(languageCode: 'en');
      expect(success, isTrue);
      expect(speechService.currentLanguage, equals('en-IN'));
      expect(speechService.state, equals(SpeechServiceState.ready));
      expect(speechService.lastFailure, isNull);
    });

    test('Initializes successfully with Hindi (hi / hi-IN)', () async {
      final success = await speechService.initialize(languageCode: 'hi');
      expect(success, isTrue);
      expect(speechService.currentLanguage, equals('hi-IN'));
      expect(speechService.state, equals(SpeechServiceState.ready));
      expect(speechService.lastFailure, isNull);
    });

    test('Initializes successfully with Assamese (as / as-IN)', () async {
      final success = await speechService.initialize(languageCode: 'as');
      expect(success, isTrue);
      expect(speechService.currentLanguage, equals('as-IN'));
      expect(speechService.state, equals(SpeechServiceState.ready));
      expect(speechService.lastFailure, isNull);
    });

    test('Rejects unsupported language and emits languageUnavailable failure', () async {
      SpeechFailureState? capturedFailure;
      final sub = speechService.failureStream.listen((f) => capturedFailure = f);

      final success = await speechService.initialize(languageCode: 'fr');
      expect(success, isFalse);
      expect(speechService.lastFailure, equals(SpeechFailureState.languageUnavailable));
      expect(speechService.state, equals(SpeechServiceState.error));
      expect(capturedFailure, equals(SpeechFailureState.languageUnavailable));

      await sub.cancel();
    });
  });

  group('SpeechService Availability & Inspection', () {
    test('isAvailable getter and isAvailableSync method reflect provider state', () {
      mockProvider.available = true;
      expect(speechService.isAvailable, isTrue);
      expect(speechService.isAvailableSync(), isTrue);

      mockProvider.available = false;
      expect(speechService.isAvailable, isFalse);
      expect(speechService.isAvailableSync(), isFalse);

      mockProvider.available = true;
    });
  });

  group('Listening Lifecycle: startListening, stopListening, cancelListening', () {
    test('startListening initiates listening state', () async {
      await speechService.initialize(languageCode: 'en');
      await speechService.startListening();

      expect(speechService.isListening, isTrue);
      expect(speechService.state, equals(SpeechServiceState.listening));
      expect(mockProvider.listening, isTrue);
    });

    test('stopListening transitions back to ready', () async {
      await speechService.initialize(languageCode: 'en');
      await speechService.startListening();
      expect(speechService.isListening, isTrue);

      await speechService.stopListening();
      expect(speechService.isListening, isFalse);
      expect(speechService.state, equals(SpeechServiceState.ready));
      expect(mockProvider.listening, isFalse);
    });

    test('cancelListening transitions to ready and emits cancelled failure', () async {
      await speechService.initialize(languageCode: 'en');
      await speechService.startListening();

      SpeechFailureState? failureEmitted;
      final sub = speechService.failureStream.listen((f) => failureEmitted = f);

      await speechService.cancelListening();
      await Future<void>.delayed(Duration.zero);
      expect(speechService.isListening, isFalse);
      expect(speechService.state, equals(SpeechServiceState.ready));
      expect(speechService.lastFailure, equals(SpeechFailureState.cancelled));
      expect(failureEmitted, equals(SpeechFailureState.cancelled));

      await sub.cancel();
    });
  });

  group('Reactive Streams & Recognized Text Emitted', () {
    test('Streams recognized transcripts via textStream and resultStream', () async {
      await speechService.initialize(languageCode: 'en');

      final textEvents = <String>[];
      final resultEvents = <SpeechRecognitionResult>[];
      VoiceCommand? receivedCommand;

      final textSub = speechService.textStream.listen(textEvents.add);
      final resultSub = speechService.resultStream.listen(resultEvents.add);

      await speechService.startListening(
        onCommand: (cmd) => receivedCommand = cmd,
      );

      // 1. Partial result
      mockProvider.emitTranscript('open', isFinal: false);
      // 2. Final result
      mockProvider.emitTranscript('open games', isFinal: true);
      await Future<void>.delayed(Duration.zero);

      expect(textEvents, equals(['open', 'open games']));
      expect(resultEvents.length, equals(2));
      expect(resultEvents[0].text, equals('open'));
      expect(resultEvents[0].isFinal, isFalse);
      expect(resultEvents[1].text, equals('open games'));
      expect(resultEvents[1].isFinal, isTrue);
      expect(resultEvents[1].isVoiceInput, isTrue);

      expect(receivedCommand, isNotNull);
      expect(receivedCommand!.text, equals('open games'));
      expect(receivedCommand!.isFinal, isTrue);
      expect(receivedCommand!.isVoiceInput, isTrue);

      await textSub.cancel();
      await resultSub.cancel();
    });
  });

  group('Clear Failure States', () {
    test('Maps "permission denied" error to permissionDenied failure state', () async {
      await speechService.initialize(languageCode: 'en');

      SpeechFailureState? failureCallback;
      await speechService.startListening(
        onFailure: (failure) => failureCallback = failure,
      );

      mockProvider.emitError('Microphone permission was denied by user');
      expect(speechService.lastFailure, equals(SpeechFailureState.permissionDenied));
      expect(speechService.state, equals(SpeechServiceState.error));
      expect(failureCallback, equals(SpeechFailureState.permissionDenied));
    });

    test('Maps network error to networkRequired failure state', () async {
      await speechService.initialize(languageCode: 'en');

      SpeechFailureState? failureCallback;
      await speechService.startListening(
        onFailure: (failure) => failureCallback = failure,
      );

      mockProvider.emitError('No internet connection found for cloud recognition');
      expect(speechService.lastFailure, equals(SpeechFailureState.networkRequired));
      expect(failureCallback, equals(SpeechFailureState.networkRequired));
    });

    test('Maps service unavailable error to serviceUnavailable failure state', () async {
      mockProvider.available = false;

      SpeechFailureState? failureCallback;
      await speechService.startListening(
        onFailure: (failure) => failureCallback = failure,
      );

      expect(speechService.lastFailure, equals(SpeechFailureState.serviceUnavailable));
      expect(failureCallback, equals(SpeechFailureState.serviceUnavailable));
    });

    test('Maps generic audio decode error to recognitionFailed failure state', () async {
      await speechService.initialize(languageCode: 'en');

      SpeechFailureState? failureCallback;
      await speechService.startListening(
        onFailure: (failure) => failureCallback = failure,
      );

      mockProvider.emitError('Audio buffer overflow in native recorder');
      expect(speechService.lastFailure, equals(SpeechFailureState.recognitionFailed));
      expect(failureCallback, equals(SpeechFailureState.recognitionFailed));
    });
  });

  group('Fallback Text Input Path (submitTextFallback)', () {
    test('Routes typed text through textStream, resultStream, and onCommand', () async {
      await speechService.initialize(languageCode: 'en');

      final textEvents = <String>[];
      final resultEvents = <SpeechRecognitionResult>[];
      VoiceCommand? receivedCommand;

      final textSub = speechService.textStream.listen(textEvents.add);
      final resultSub = speechService.resultStream.listen(resultEvents.add);

      speechService.submitTextFallback(
        'take me home',
        onCommand: (cmd) => receivedCommand = cmd,
      );
      await Future<void>.delayed(Duration.zero);

      expect(textEvents, contains('take me home'));
      expect(resultEvents.isNotEmpty, isTrue);
      expect(resultEvents.last.text, equals('take me home'));
      expect(resultEvents.last.isVoiceInput, isFalse);
      expect(resultEvents.last.isFinal, isTrue);

      expect(receivedCommand, isNotNull);
      expect(receivedCommand!.text, equals('take me home'));
      expect(receivedCommand!.isVoiceInput, isFalse);

      await textSub.cancel();
      await resultSub.cancel();
    });
  });

  group('Offline ASR Provider Contract Integrity', () {
    test('OfflineAsrProvider does NOT claim offline recognition when weights are absent', () async {
      final offlineProvider = OfflineAsrProvider();
      expect(offlineProvider.isAvailable, isFalse);
      expect(offlineProvider.isModelLoaded, isFalse);

      final initSuccess = await offlineProvider.initialize(languageCode: 'en');
      expect(initSuccess, isFalse);

      String? errorMessage;
      await offlineProvider.startListening(
        languageCode: 'en',
        onResult: (_, __) {},
        onError: (err) => errorMessage = err,
      );

      expect(errorMessage, contains('not loaded'));
    });
  });

  group('VoiceAssistantController Exclusive SpeechService Integration', () {
    test('Controller handles command emitted by SpeechService through cancelListening and text fallback', () async {
      String? routeNavigated;
      final executor = VoiceActionExecutor(
        onNavigate: (r, {arguments}) => routeNavigated = r,
      );

      final controller = VoiceAssistantController(
        speechService: speechService,
        actionExecutor: executor,
      );

      await controller.openAssistant(currentRoute: '/dashboard');
      expect(controller.isAssistantOpen, isTrue);

      // Text input fallback through controller submits to SpeechService
      final result = await controller.processTextInput('open games');
      expect(result.isSuccess, isTrue);
      expect(routeNavigated, equals('/games'));

      // Cancel assistant calls speechService.cancelListening()
      await controller.cancelAssistant();
      expect(controller.isCancelled, isTrue);
      expect(speechService.lastFailure, equals(SpeechFailureState.cancelled));

      controller.dispose();
    });
  });
}
