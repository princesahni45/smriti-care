// lib/services/tts/local_text_to_speech_service.dart
//
// Primary Implementation of TextToSpeechService backed by Native On-Device TTS.
//
// SAFETY & DEMENTIA CONSTRAINTS:
// 1. Elderly Calm Cadence: Default playback rate is 0.75x.
// 2. Strict Medication Dosage Guardrail: Text mentioning specific milligram/milliliter
//    or medicine modification instructions is blocked before reaching speech synthesis.
// 3. Unsecured Context Guardrail: Sensitive patient private data is blocked on unsecured screens.
// 4. Honesty Principle for Assamese: Transparently fails if an Assamese voice engine
//    is absent; NEVER translates silently to English or Hindi.
// 5. Zero Cloud Transmission: Speech generation is entirely local.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'text_to_speech_service.dart';
import 'tts_models.dart';
import 'native_tts_bridge.dart';

class LocalTextToSpeechService implements TextToSpeechService {
  final NativeTTSBridge _bridge;

  bool _isReady = false;
  bool _isSpeaking = false;
  bool _isPaused = false;
  double _currentRate = 0.75; // Slower cadence for elderly comprehension
  String? _lastSpokenText;
  String _lastSpokenLanguage = 'en';

  LocalTextToSpeechService({
    NativeTTSBridge? bridge,
  }) : _bridge = bridge ?? const MethodChannelNativeTTSBridge();

  static final LocalTextToSpeechService instance = LocalTextToSpeechService();

  @override
  bool get isReady => _isReady;

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  bool get isPaused => _isPaused;

  @override
  double get currentRate => _currentRate;

  @override
  String? get lastSpokenText => _lastSpokenText;

  /// True as local speech synthesis runs entirely on-device without cloud transmission.
  bool get isOfflineCapable => true;

  /// Reports whether speech synthesis for a given language runs offline.
  Future<bool> isOfflineAvailable(String languageCode) async {
    final support = await checkLanguageSupport(languageCode);
    return support.offlineCapable && support.isWorking;
  }

  @override
  Future<void> initialize() async {
    try {
      _isReady = await _bridge.initTts();
      await _bridge.setSpeechRate(_currentRate);
    } catch (e) {
      debugPrint('LocalTextToSpeechService init failed: $e');
      _isReady = false;
    }
  }

  @override
  Future<List<TTSVoice>> getAvailableVoices() async {
    final voices = await _bridge.getAvailableVoices();
    // Strictly filter out any voices requiring network/cloud connections
    return voices.where((v) => !v.isNetworkConnectionRequired).toList();
  }

  @override
  Future<TTSLanguageSupport> checkLanguageSupport(String languageCode) async {
    final res =
        await _bridge.checkLanguageAvailable(languageCode: languageCode);
    final isAvail = res['isAvailable'] as bool? ?? false;

    final allVoices = await getAvailableVoices();
    final matchingVoices = allVoices.where((v) {
      final loc = v.locale.toLowerCase();
      if (languageCode == 'en') return loc.startsWith('en');
      if (languageCode == 'hi') return loc.startsWith('hi');
      if (languageCode == 'as') return loc.startsWith('as');
      return false;
    }).toList();

    if (!isAvail || matchingVoices.isEmpty) {
      TTSLanguageSupportStatus status = TTSLanguageSupportStatus.notAvailable;
      String details = 'No offline voice pack installed for $languageCode.';

      if (languageCode == 'as') {
        details =
            'Assamese voice engine is not installed on this device. Regional TTS pack required.';
      }

      return TTSLanguageSupport(
        languageCode: languageCode,
        status: status,
        availableVoicesCount: 0,
        selectedVoice: null,
        offlineCapable: false,
        details: details,
      );
    }

    TTSLanguageSupportStatus status = TTSLanguageSupportStatus.working;
    if (matchingVoices.length == 1) {
      status = TTSLanguageSupportStatus.partiallyWorking;
    }

    return TTSLanguageSupport(
      languageCode: languageCode,
      status: status,
      availableVoicesCount: matchingVoices.length,
      selectedVoice: matchingVoices.first,
      offlineCapable: true,
      details: 'Active offline voice: ${matchingVoices.first.name}',
    );
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    // Clamp speech rate strictly between 0.5 and 1.0 for elderly cognitive comfort
    _currentRate = rate.clamp(0.5, 1.0);
    await _bridge.setSpeechRate(_currentRate);
  }

  /// Safety validator for spoken output: blocks medication dosage instructions
  /// and sensitive health records on unsecured surfaces.
  void _validateSafety({
    required String text,
    required bool isSecuredContext,
  }) {
    // 1. Medication dosage guardrail
    final dosagePattern = RegExp(
      r'\b(\d+\s*(mg|ml|mcg|tablets?|pills?|capsules?))\b',
      caseSensitive: false,
    );
    final medChangePattern = RegExp(
      r'\b(take|increase|decrease|double|skip|stop taking)\s+(your\s+)?(medicine|medication|dose|dosage|pills?)\b',
      caseSensitive: false,
    );

    if (dosagePattern.hasMatch(text) || medChangePattern.hasMatch(text)) {
      throw TTSSafetyViolationException(
        reason:
            'Voice narration of medication dosage or medicine alterations is strictly prohibited.',
        attemptedText: text,
      );
    }

    // 2. Sensitive private info guardrail on unsecured screens
    if (!isSecuredContext) {
      final sensitiveInfoPattern = RegExp(
        r'\b(emergency contact|aadhaar|ssn|blood group|medical history|diagnosed with)\b',
        caseSensitive: false,
      );
      if (sensitiveInfoPattern.hasMatch(text)) {
        throw TTSSafetyViolationException(
          reason:
              'Cannot speak private health records or emergency contacts on an unsecured screen.',
          attemptedText: text,
        );
      }
    }
  }

  @override
  Future<bool> speak({
    required String text,
    required String languageCode,
    double pitch = 1.0,
    double? rate,
    bool isSecuredContext = true,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return false;

    // Safety validation before any audio synthesis
    _validateSafety(text: cleanText, isSecuredContext: isSecuredContext);

    // Check language voice availability on-device
    final support = await checkLanguageSupport(languageCode);
    if (support.isUnavailable) {
      debugPrint('TTS Voice unavailable for $languageCode: ${support.details}');
      _isSpeaking = false;
      _isPaused = false;
      return false;
    }

    final activeRate = rate != null ? rate.clamp(0.5, 1.0) : _currentRate;

    _lastSpokenText = cleanText;
    _lastSpokenLanguage = languageCode;
    _isSpeaking = true;
    _isPaused = false;

    final ok = await _bridge.speak(
      text: cleanText,
      languageCode: languageCode,
      rate: activeRate,
      pitch: pitch,
    );

    if (!ok) {
      _isSpeaking = false;
    }
    return ok;
  }

  @override
  Future<bool> replay() async {
    if (_lastSpokenText == null || _lastSpokenText!.isEmpty) return false;
    return speak(
      text: _lastSpokenText!,
      languageCode: _lastSpokenLanguage,
      rate: _currentRate,
    );
  }

  @override
  Future<void> pause() async {
    if (_isSpeaking) {
      await _bridge.pause();
      _isSpeaking = false;
      _isPaused = true;
    }
  }

  @override
  Future<void> resume() async {
    if (_isPaused) {
      await _bridge.resume();
      _isPaused = false;
      _isSpeaking = true;
    }
  }

  @override
  Future<void> stop() async {
    await _bridge.stop();
    _isSpeaking = false;
    _isPaused = false;
  }
}
