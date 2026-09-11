// lib/core/voice/tts_service.dart
//
// Centralized Text-to-Speech (TTS) service abstraction for SmritiCare.
// Tailored for elderly dementia care with a gentle, slightly slower pace
// (0.85x) and support for English, Hindi, and Assamese.
//
// Conforms to requirements:
// - TTSService / TtsService
// - speak(text, language)
// - stop()
// - isAvailable([language])
// - Supports English ('en'), Hindi ('hi'), Assamese ('as')
// - Automatically synchronizes with the currently selected app language
// - Keeps voice responses short and gentle
// - Fails safely if Assamese TTS is unavailable (never crashes; response preserved visually)

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../localization/app_localizations.dart';

/// State of the TTS engine.
enum TtsServiceState {
  /// TTS is ready and idle.
  idle,

  /// Currently synthesizing or playing audio.
  speaking,

  /// Audio output paused.
  paused,

  /// Encountered an error.
  error,

  /// TTS is unavailable on this device.
  unavailable,
}

/// Abstract contract for Text-To-Speech providers.
abstract class TtsProvider {
  /// Initialize TTS resources.
  Future<bool> initialize();

  /// Speak the provided text in the chosen language.
  Future<void> speak({
    required String text,
    required String languageCode,
    required double speechRate,
    required double pitch,
    required void Function() onDone,
    required void Function(String error) onError,
  });

  /// Stop speech playback immediately.
  Future<void> stop();

  /// Whether TTS is available.
  bool get isAvailable;

  /// Dispose underlying resources.
  Future<void> dispose();
}

/// Extension providing non-breaking language query capabilities for all providers.
extension TtsProviderExtension on TtsProvider {
  /// Whether specific language audio synthesis is supported on this provider.
  bool isLanguageAvailable(String languageCode) {
    if (this is DefaultTtsProvider) {
      return (this as DefaultTtsProvider).isAvailableForLanguage(languageCode);
    }
    return isAvailable;
  }
}

/// Default development / platform fallback provider.
/// Safe in CI, widget tests, and production environments.
class DefaultTtsProvider implements TtsProvider {
  bool _available = true;
  bool _speaking = false;
  final Map<String, bool> _languageAvailability = {
    'en': true,
    'hi': true,
    'as': true,
  };
  void Function()? _onDoneCallback;
  Timer? _speechTimer;

  @override
  bool get isAvailable => _available;

  bool get isSpeaking => _speaking;

  void setAvailable(bool available) {
    _available = available;
  }

  /// Configure simulated language availability (e.g. to test Assamese TTS unavailability).
  void setLanguageAvailable(String languageCode, bool available) {
    final code = languageCode.toLowerCase().split('-').first;
    _languageAvailability[code] = available;
  }

  /// Whether language audio synthesis is available.
  bool isAvailableForLanguage(String languageCode) {
    if (!_available) return false;
    final code = languageCode.toLowerCase().split('-').first;
    return _languageAvailability[code] ?? false;
  }

  @override
  Future<bool> initialize() async {
    return _available;
  }

  @override
  Future<void> speak({
    required String text,
    required String languageCode,
    required double speechRate,
    required double pitch,
    required void Function() onDone,
    required void Function(String error) onError,
  }) async {
    _speechTimer?.cancel();
    if (!_available) {
      onError('TTS unavailable');
      return;
    }

    final code = languageCode.toLowerCase().split('-').first;
    if (_languageAvailability[code] == false) {
      onError('TTS unavailable for language: $languageCode');
      return;
    }

    _speaking = true;
    _onDoneCallback = onDone;
    debugPrint('[SmritiCare TTS ($languageCode @ ${speechRate}x)]: $text');

    // Simulate natural speech duration for test/demo environments
    final readingTimeMs = (text.length * 35).clamp(300, 1500);
    _speechTimer = Timer(Duration(milliseconds: readingTimeMs), () {
      if (_speaking) {
        _speaking = false;
        _onDoneCallback?.call();
      }
    });
  }

  @override
  Future<void> stop() async {
    _speechTimer?.cancel();
    _speaking = false;
    _onDoneCallback = null;
  }

  @override
  Future<void> dispose() async {
    _speechTimer?.cancel();
    _speaking = false;
    _onDoneCallback = null;
  }
}

/// Central Text-To-Speech coordinator for SmritiCare.
/// Also aliased as [TTSService] per system requirements.
class TtsService extends ChangeNotifier {
  TtsService._({TtsProvider? provider})
      : _provider = provider ?? DefaultTtsProvider();

  /// Create an isolated TtsService instance for unit testing.
  factory TtsService.create({TtsProvider? provider}) {
    return TtsService._(provider: provider);
  }

  static TtsService? _instance;
  static TtsService get instance => _instance ??= TtsService._();

  /// Visible for testing.
  static void setMockInstance(TtsService mock) {
    _instance = mock;
  }

  static const Set<String> _supportedLanguages = {'en', 'hi', 'as'};

  TtsProvider _provider;
  TtsServiceState _state = TtsServiceState.idle;

  /// Default speech rate tuned for elderly dementia patients (0.85x).
  double _speechRate = 0.85;
  double _pitch = 1.0;
  String _activeLanguage = 'en';
  String? _lastSpokenText;
  bool _assameseAvailable = true;

  TtsServiceState get state => _state;
  bool get isSpeaking => _state == TtsServiceState.speaking;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  String? get lastSpokenText => _lastSpokenText;

  /// Dynamically reflects the currently selected app language from LocalizationService,
  /// falling back safely to [_activeLanguage].
  String get activeLanguage {
    try {
      final current = LocalizationService.instance.currentLanguageCode;
      if (current.isNotEmpty && _supportedLanguages.contains(current.toLowerCase())) {
        return current.toLowerCase();
      }
    } catch (_) {
      // Test environment without LocalizationService
    }
    return _activeLanguage;
  }

  /// Query whether TTS is available on the device, optionally for a specific language.
  /// Handles English, Hindi, and Assamese.
  bool isAvailable([String? language]) {
    if (!_provider.isAvailable) return false;
    if (language == null) return true;

    final lang = language.toLowerCase().split('-').first;
    if (!_supportedLanguages.contains(lang)) return false;
    if (lang == 'as' && !_assameseAvailable) return false;

    return _provider.isLanguageAvailable(lang);
  }

  /// Configure Assamese TTS availability explicitly for testing fallback flows.
  void setAssameseAvailable(bool available) {
    _assameseAvailable = available;
    if (_provider is DefaultTtsProvider) {
      (_provider as DefaultTtsProvider).setLanguageAvailable('as', available);
    }
    notifyListeners();
  }

  /// Configure language availability on the active provider.
  void setLanguageAvailable(String languageCode, bool available) {
    final lang = languageCode.toLowerCase().split('-').first;
    if (lang == 'as') {
      _assameseAvailable = available;
    }
    if (_provider is DefaultTtsProvider) {
      (_provider as DefaultTtsProvider).setLanguageAvailable(lang, available);
    }
    notifyListeners();
  }

  /// Set the underlying provider implementation.
  void setProvider(TtsProvider provider) {
    _provider = provider;
    notifyListeners();
  }

  /// Initialize TTS engine.
  Future<bool> initialize({String languageCode = 'en'}) async {
    _activeLanguage = languageCode;
    try {
      final ok = await _provider.initialize();
      _state = ok ? TtsServiceState.idle : TtsServiceState.unavailable;
      notifyListeners();
      return ok;
    } catch (e) {
      _state = TtsServiceState.error;
      notifyListeners();
      return false;
    }
  }

  /// Adjust speech rate (recommended: 0.7 - 0.9 for elder care).
  void setSpeechRate(double rate) {
    _speechRate = rate.clamp(0.5, 1.5);
    notifyListeners();
  }

  /// Adjust pitch.
  void setPitch(double pitch) {
    _pitch = pitch.clamp(0.5, 2.0);
    notifyListeners();
  }

  /// Set fallback active TTS language.
  void setLanguage(String languageCode) {
    _activeLanguage = languageCode.toLowerCase().split('-').first;
    notifyListeners();
  }

  /// Keep voice responses short and gentle for dementia care.
  static String trimResponseForSpeech(String text, {int maxWords = 25}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';
    final words = trimmed.split(RegExp(r'\s+'));
    if (words.length <= maxWords) return trimmed;
    return '${words.take(maxWords).join(' ')}...';
  }

  /// Map 2-letter language codes to BCP-47 speech tags.
  String _mapLanguageLocale(String code) {
    switch (code.toLowerCase().split('-').first) {
      case 'hi':
        return 'hi-IN';
      case 'as':
        return 'as-IN';
      case 'en':
      default:
        return 'en-IN';
    }
  }

  /// Synthesize and speak [text] in the given [language] or the currently selected app language.
  ///
  /// Conforms to `speak(text, language)` signature.
  /// If Assamese (or another language) TTS is unavailable:
  /// - Fails safely without throwing any unhandled exception (never crashes).
  /// - Preserves response in [lastSpokenText] so the caller / UI displays it visually.
  Future<void> speak(String text, [String? language]) async {
    final targetLang = (language ?? activeLanguage).toLowerCase().split('-').first;
    final shortText = trimResponseForSpeech(text);
    _lastSpokenText = shortText;

    // Safety guard: if TTS or the target language (such as Assamese) is unavailable,
    // fail safely without crashing. The response remains preserved visually.
    if (!isAvailable(targetLang)) {
      debugPrint(
        '[TtsService] TTS unavailable for language "$targetLang". '
        'Failing safely; response preserved visually.',
      );
      _state = TtsServiceState.idle;
      notifyListeners();
      return;
    }

    _state = TtsServiceState.speaking;
    notifyListeners();

    try {
      await _provider.speak(
        text: shortText,
        languageCode: _mapLanguageLocale(targetLang),
        speechRate: _speechRate,
        pitch: _pitch,
        onDone: () {
          _state = TtsServiceState.idle;
          notifyListeners();
        },
        onError: (err) {
          debugPrint('[TtsService] Error speaking ($targetLang): $err. Failing safely.');
          _state = TtsServiceState.idle;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('[TtsService] Exception during speak ($targetLang): $e. Failing safely.');
      _state = TtsServiceState.idle;
      notifyListeners();
    }
  }

  /// Stop current speech playback immediately.
  Future<void> stop() async {
    try {
      await _provider.stop();
    } catch (e) {
      debugPrint('[TtsService] Exception during stop: $e');
    }
    _state = TtsServiceState.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }
}

/// Typedef providing exact requirement naming compatibility: `TTSService`.
typedef TTSService = TtsService;
