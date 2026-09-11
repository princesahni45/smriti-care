// lib/core/voice/voice_assistant_controller.dart
//
// Central coordinator for the SmritiCare Multilingual Voice Assistant.
// Connects Speech Recognition, Multilingual Intent Routing, Text-To-Speech,
// Confirmation workflows, and Graceful Text Fallbacks.

import 'dart:async';
import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';
import 'voice_command.dart';
import 'voice_intent.dart';
import 'voice_context.dart';
import 'voice_action.dart';
import 'voice_action_executor.dart';
import 'speech_service.dart';
import 'tts_service.dart';
import 'intent_router.dart';

/// Operational states of the voice assistant lifecycle.
enum VoiceAssistantStatus {
  /// Assistant is closed or dormant.
  idle,

  /// Assistant is opening and initializing services.
  opening,

  /// Actively capturing user speech.
  listening,

  /// Classifying intent and resolving action. Exactly one command processed at a time.
  processing,

  /// Carrying out the resolved voice action.
  executing,

  /// Synthesizing and speaking voice response.
  speaking,

  /// An error occurred during speech, routing, or execution.
  error,

  /// Interaction or action was cancelled by the user.
  cancelled,
}

/// Central controller managing assistant interactions, listening cycles,
/// confirmations, and navigation executions.
class VoiceAssistantController extends ChangeNotifier {
  final SpeechService _speechService;
  final TtsService _ttsService;
  final IntentClassifier _intentRouter;
  final VoiceActionExecutor _actionExecutor;

  VoiceAssistantStatus _status = VoiceAssistantStatus.idle;
  VoiceContext _context = const VoiceContext();
  String _activeTranscript = '';
  String _lastFeedback = '';
  String? _errorMessage;
  bool _isAssistantOpen = false;
  bool _isDisposed = false;
  bool _isProcessingCommand = false;

  bool get isDisposed => _isDisposed;
  bool get isProcessingCommand => _isProcessingCommand;

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  VoiceAssistantController({
    SpeechService? speechService,
    TtsService? ttsService,
    IntentClassifier? intentRouter,
    VoiceActionExecutor? actionExecutor,
  })  : _speechService = speechService ?? SpeechService.instance,
        _ttsService = ttsService ?? TtsService.instance,
        _intentRouter = intentRouter ?? const DeterministicIntentRouter(),
        _actionExecutor = actionExecutor ?? const VoiceActionExecutor() {
    _initLocaleSync();
  }

  // ── GETTERS ─────────────────────────────────────────────────────────────

  VoiceAssistantStatus get status => _status;
  VoiceContext get context => _context;
  String get activeTranscript => _activeTranscript;
  String get lastFeedback => _lastFeedback;
  String? get errorMessage => _errorMessage;
  bool get isAssistantOpen => _isAssistantOpen;
  bool get isIdle => _status == VoiceAssistantStatus.idle;
  bool get isOpening => _status == VoiceAssistantStatus.opening;
  bool get isListening => _status == VoiceAssistantStatus.listening;
  bool get isProcessing => _status == VoiceAssistantStatus.processing;
  bool get isExecuting => _status == VoiceAssistantStatus.executing;
  bool get isSpeaking => _status == VoiceAssistantStatus.speaking;
  bool get isError => _status == VoiceAssistantStatus.error;
  bool get isCancelled => _status == VoiceAssistantStatus.cancelled;
  bool get isConfirming => _context.hasPendingConfirmation;
  bool get isTextFallback => !_speechService.isAvailable;
  VoiceAction? get pendingAction => _context.pendingAction;
  String get activeLanguageCode => _context.activeLanguageCode;

  /// Localized language label for elderly display.
  String get currentLanguageName {
    switch (_context.activeLanguageCode) {
      case 'hi':
        return 'हिंदी (Hindi)';
      case 'as':
        return 'অসমীয়া (Assamese)';
      case 'en':
      default:
        return 'English (EN)';
    }
  }

  void _initLocaleSync() {
    try {
      final current = LocalizationService.instance.currentLocaleNotifier.value;
      _context = _context.copyWith(activeLanguageCode: current.languageCode);
      _speechService.setLanguage(current.languageCode);
      _ttsService.setLanguage(current.languageCode);
    } catch (_) {
      // Fallback in tests where LocalizationService may not have initialized
    }
  }

  /// Update the active screen route for context-sensitive disambiguation.
  void updateCurrentRoute(String route, {Map<String, dynamic>? metadata}) {
    _context = _context.copyWith(
      currentRoute: route,
      metadata: metadata,
    );
    notifyListeners();
  }

  /// Update the active language ('en', 'hi', 'as').
  void setLanguage(String langCode) {
    _context = _context.copyWith(activeLanguageCode: langCode);
    _speechService.setLanguage(langCode);
    _ttsService.setLanguage(langCode);
    notifyListeners();
  }

  // ── ASSISTANT LIFECYCLE ──────────────────────────────────────────────────

  /// Open the assistant modal / sheet.
  /// Automatically initiates listening if speech service is available.
  Future<void> openAssistant({
    String? currentRoute,
    bool autoListen = true,
  }) async {
    _initLocaleSync();
    _isAssistantOpen = true;
    _activeTranscript = '';
    _errorMessage = null;
    _status = VoiceAssistantStatus.opening;
    notifyListeners();

    if (currentRoute != null) {
      _context = _context.copyWith(currentRoute: currentRoute);
    }

    if (autoListen && _speechService.isAvailable) {
      await startListening();
    } else if (!_speechService.isAvailable) {
      _status = VoiceAssistantStatus.idle;
      _lastFeedback =
          _getLocalizedTextFallbackNotice(_context.activeLanguageCode);
      notifyListeners();
    } else {
      _status = VoiceAssistantStatus.idle;
      notifyListeners();
    }
  }

  /// Close the assistant and reset transient confirmation states.
  Future<void> closeAssistant() async {
    _isAssistantOpen = false;
    await _speechService.stopListening();
    await _ttsService.stop();
    if (_isDisposed) return;
    _context = _context.copyWith(clearPendingAction: true);
    _status = VoiceAssistantStatus.idle;
    notifyListeners();
  }

  /// Manually activate microphone listening.
  Future<void> startListening() async {
    if (_isProcessingCommand || _isDisposed) return;
    if (!_speechService.isAvailable) {
      _status = VoiceAssistantStatus.idle;
      _lastFeedback =
          _getLocalizedTextFallbackNotice(_context.activeLanguageCode);
      notifyListeners();
      return;
    }

    _status = VoiceAssistantStatus.listening;
    _activeTranscript = '';
    _errorMessage = null;
    notifyListeners();

    await _speechService.startListening(
      onCommand: (command) => handleCommand(command),
      onPartial: (partial) {
        if (_status == VoiceAssistantStatus.listening) {
          _activeTranscript = partial;
          notifyListeners();
        }
      },
    );
  }

  /// Stop active microphone listening.
  Future<void> stopListening() async {
    await _speechService.stopListening();
    if (_status == VoiceAssistantStatus.listening) {
      _status = VoiceAssistantStatus.idle;
      notifyListeners();
    }
  }

  /// Explicitly cancels any active listening, speaking, or pending action.
  /// Transitions to explicit [VoiceAssistantStatus.cancelled] state.
  Future<void> cancelAssistant() async {
    await _speechService.cancelListening();
    await _ttsService.stop();
    _context = _context.copyWith(clearPendingAction: true);
    _status = VoiceAssistantStatus.cancelled;
    _lastFeedback = _getLocalizedCancelNotice(_context.activeLanguageCode);
    notifyListeners();
  }

  // ── COMMAND PROCESSING ───────────────────────────────────────────────────

  /// Primary command dispatcher. Accepts speech or text fallback commands.
  ///
  /// Guarantees:
  /// 1. Listening is stopped immediately upon capturing the command.
  /// 2. Exactly one command is processed at a time.
  Future<VoiceExecutionResult> handleCommand(VoiceCommand command) async {
    // Stop listening immediately after command is captured (Requirement 9)
    await _speechService.stopListening();

    // Process exactly one command at a time (Requirement 10)
    if (_isProcessingCommand || _isDisposed) {
      return VoiceExecutionResult.failure('Already processing a command.');
    }
    _isProcessingCommand = true;
    _activeTranscript = command.text;
    _status = VoiceAssistantStatus.processing;
    notifyListeners();

    try {
      final intent = await _intentRouter.classify(command, _context);

      // 1. Handle confirmation workflow response
      if (_context.hasPendingConfirmation) {
        return await _handleConfirmationReply(intent);
      }

      // 2. Resolve executable action
      final action = _actionExecutor.resolveAction(intent, _context);

      // 3. Sensitive Action Check: Prompt user before proceeding
      if (action.requiresConfirmation) {
        return await _initiateConfirmationWorkflow(action);
      }

      // 4. Execute deterministic action
      return await _executeAction(action);
    } catch (e) {
      _status = VoiceAssistantStatus.error;
      _errorMessage = e.toString();
      _lastFeedback = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return VoiceExecutionResult.failure(_lastFeedback);
    } finally {
      _isProcessingCommand = false;
    }
  }

  /// Process text input fallback when mic is unavailable or user chooses to type.
  Future<VoiceExecutionResult> processTextInput(String text) async {
    if (text.trim().isEmpty) {
      return const VoiceExecutionResult(
        isSuccess: false,
        spokenResponse: '',
        displayMessage: 'Please enter a command.',
      );
    }

    final command = VoiceCommand.fromText(
      text,
      languageCode: _context.activeLanguageCode,
    );
    _speechService.submitTextFallback(text);
    return await handleCommand(command);
  }

  /// Directly dispatch a VoiceAction (e.g. from tests or explicit UI triggers)
  Future<VoiceExecutionResult> executeActionDirectly(VoiceAction action) async {
    if (action.requiresConfirmation) {
      return await _initiateConfirmationWorkflow(action);
    }
    return await _executeAction(action);
  }

  // ── CONFIRMATION WORKFLOW ────────────────────────────────────────────────

  Future<VoiceExecutionResult> _initiateConfirmationWorkflow(
      VoiceAction action) async {
    _context = _context.copyWith(pendingAction: action);
    final prompt = action.getConfirmationPrompt(_context.activeLanguageCode);
    _lastFeedback = prompt;
    _status = VoiceAssistantStatus.speaking;
    notifyListeners();

    // Speak prompt via TTS
    await _ttsService.speak(prompt, _context.activeLanguageCode);

    // If speech recognition is available, auto-listen for "yes" / "no"
    if (_speechService.isAvailable) {
      _status = VoiceAssistantStatus.listening;
      notifyListeners();
      await _speechService.startListening(
        onCommand: (command) => handleCommand(command),
        onPartial: (partial) {
          if (_status == VoiceAssistantStatus.listening) {
            _activeTranscript = partial;
            notifyListeners();
          }
        },
      );
    } else {
      _status = VoiceAssistantStatus.idle;
      notifyListeners();
    }

    return VoiceExecutionResult(
      isSuccess: true,
      spokenResponse: prompt,
      displayMessage: prompt,
    );
  }

  Future<VoiceExecutionResult> _handleConfirmationReply(
      VoiceIntent replyIntent) async {
    final pending = _context.pendingAction;
    if (pending == null) {
      _status = VoiceAssistantStatus.idle;
      notifyListeners();
      return VoiceExecutionResult.failure('No pending action found.');
    }

    if (replyIntent.type == VoiceIntentType.confirm) {
      // User explicitly affirmed action
      _context = _context.copyWith(clearPendingAction: true);
      return await _executeAction(pending);
    } else if (replyIntent.type == VoiceIntentType.CANCEL ||
        replyIntent.type == VoiceIntentType.cancel) {
      // User explicitly cancelled action
      _context = _context.copyWith(clearPendingAction: true);
      final cancelMsg = _getLocalizedCancelNotice(_context.activeLanguageCode);
      _lastFeedback = cancelMsg;
      _status = VoiceAssistantStatus.cancelled;
      notifyListeners();

      await _ttsService.speak(cancelMsg, _context.activeLanguageCode);
      _status = VoiceAssistantStatus.idle;
      notifyListeners();
      return VoiceExecutionResult.success(spokenResponse: cancelMsg);
    } else {
      // Ambiguous answer while confirming — repeat confirmation prompt
      final repeatPrompt =
          pending.getConfirmationPrompt(_context.activeLanguageCode);
      _lastFeedback = repeatPrompt;
      _status = VoiceAssistantStatus.speaking;
      notifyListeners();

      await _ttsService.speak(repeatPrompt, _context.activeLanguageCode);

      if (_speechService.isAvailable) {
        _status = VoiceAssistantStatus.listening;
        notifyListeners();
        await _speechService.startListening(
          onCommand: (cmd) => handleCommand(cmd),
          onPartial: (partial) {
            if (_status == VoiceAssistantStatus.listening) {
              _activeTranscript = partial;
              notifyListeners();
            }
          },
        );
      } else {
        _status = VoiceAssistantStatus.idle;
        notifyListeners();
      }

      return VoiceExecutionResult(
        isSuccess: true,
        spokenResponse: repeatPrompt,
        displayMessage: repeatPrompt,
      );
    }
  }

  /// Explicit UI confirmation method (e.g. tapping "Confirm" button on screen).
  Future<VoiceExecutionResult> confirmPendingAction() async {
    return _handleConfirmationReply(VoiceIntent.confirm('ui_confirm'));
  }

  /// Explicit UI cancel method (e.g. tapping "Cancel" button on screen).
  Future<VoiceExecutionResult> cancelPendingAction() async {
    return _handleConfirmationReply(VoiceIntent.cancel('ui_cancel'));
  }

  // ── ACTION EXECUTION ─────────────────────────────────────────────────────

  Future<VoiceExecutionResult> _executeAction(VoiceAction action) async {
    _status = VoiceAssistantStatus.executing;
    notifyListeners();

    final result = await _actionExecutor.execute(
      action,
      languageCode: _context.activeLanguageCode,
    );

    _lastFeedback = result.spokenResponse;
    if (result.spokenResponse.isNotEmpty) {
      _status = VoiceAssistantStatus.speaking;
      notifyListeners();

      await _ttsService.speak(
        result.spokenResponse,
        _context.activeLanguageCode,
      );
    }

    _status = VoiceAssistantStatus.idle;
    notifyListeners();
    return result;
  }

  // ── LOCALIZATION HELPERS ─────────────────────────────────────────────────

  String _getLocalizedTextFallbackNotice(String lang) {
    return LocalizationService.instance.tr(
      'voice.errors.micUnavailable',
      defaultText: lang == 'hi'
          ? 'वॉइस पहचान उपलब्ध नहीं है। कृपया लिखकर आदेश दें।'
          : (lang == 'as'
              ? 'ভইচ চিনাক্তকৰণ উপলব্ধ নহয়। অনুগ্ৰহ কৰি টাইপ কৰক।'
              : 'Speech recognition is unavailable. Please type your command.'),
    );
  }

  String _getLocalizedCancelNotice(String lang) {
    return LocalizationService.instance.tr(
      'voice.actionCancelled',
      defaultText: lang == 'hi'
          ? 'कार्य रद्द कर दिया गया।'
          : (lang == 'as' ? 'কাৰ্য বাতিল কৰা হ’ল।' : 'Action cancelled.'),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _speechService.stopListening();
    _ttsService.stop();
    super.dispose();
  }
}
