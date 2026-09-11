// lib/services/tts/placeholder_tts_service.dart
//
// Baseline implementation of TextToSpeechService.
// Supports asynchronous speech synthesis simulation, rate control, and stop control.

import 'text_to_speech_service.dart';
import 'tts_models.dart';

class PlaceholderTextToSpeechService implements TextToSpeechService {
  bool _isSpeaking = false;
  bool _isPaused = false;
  double _rate = 0.75;
  String? _lastSpoken;

  @override
  bool get isReady => true;

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  bool get isPaused => _isPaused;

  @override
  double get currentRate => _rate;

  @override
  String? get lastSpokenText => _lastSpoken;

  @override
  Future<void> initialize() async {}

  @override
  Future<List<TTSVoice>> getAvailableVoices() async {
    return const [
      TTSVoice(
        name: 'placeholder-en',
        locale: 'en-US',
        isNetworkConnectionRequired: false,
      ),
      TTSVoice(
        name: 'placeholder-hi',
        locale: 'hi-IN',
        isNetworkConnectionRequired: false,
      ),
    ];
  }

  @override
  Future<TTSLanguageSupport> checkLanguageSupport(String languageCode) async {
    if (languageCode == 'as') {
      return const TTSLanguageSupport(
        languageCode: 'as',
        status: TTSLanguageSupportStatus.notAvailable,
        availableVoicesCount: 0,
        offlineCapable: false,
        details: 'Assamese voice not installed.',
      );
    }
    return TTSLanguageSupport(
      languageCode: languageCode,
      status: TTSLanguageSupportStatus.working,
      availableVoicesCount: 1,
      offlineCapable: true,
      selectedVoice: TTSVoice(
        name: 'placeholder-$languageCode',
        locale: '$languageCode-IN',
        isNetworkConnectionRequired: false,
      ),
    );
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    _rate = rate.clamp(0.5, 1.0);
  }

  @override
  Future<bool> speak({
    required String text,
    required String languageCode,
    double pitch = 1.0,
    double? rate,
    bool isSecuredContext = true,
  }) async {
    if (languageCode == 'as') return false;
    _isSpeaking = true;
    _isPaused = false;
    _lastSpoken = text;
    await Future.delayed(const Duration(milliseconds: 100));
    _isSpeaking = false;
    return true;
  }

  @override
  Future<bool> replay() async {
    if (_lastSpoken == null) return false;
    return speak(text: _lastSpoken!, languageCode: 'en');
  }

  @override
  Future<void> pause() async {
    _isSpeaking = false;
    _isPaused = true;
  }

  @override
  Future<void> resume() async {
    _isPaused = false;
    _isSpeaking = true;
  }

  @override
  Future<void> stop() async {
    _isSpeaking = false;
    _isPaused = false;
  }
}
