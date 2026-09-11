// lib/services/tts/tts_models.dart
//
// Structured models for Text-To-Speech (TTS) engine voices, status, and telemetry.
// Strictly offline compliant: marks network-requiring voices as ineligible.

/// Status categorization for regional language voice support.
enum TTSLanguageSupportStatus {
  working,
  partiallyWorking,
  deviceDependent,
  notAvailable,
}

/// Operational playback state of the TTS engine.
enum TTSPlaybackState {
  idle,
  speaking,
  paused,
  stopped,
  error,
}

/// Metadata representation of an on-device speech synthesis voice.
class TTSVoice {
  final String name;
  final String locale;
  final bool isNetworkConnectionRequired;
  final String quality;
  final int latency;

  const TTSVoice({
    required this.name,
    required this.locale,
    required this.isNetworkConnectionRequired,
    this.quality = 'normal',
    this.latency = 100,
  });

  /// Offline validity: voices requiring cloud or network are not considered valid.
  bool get isOfflineCapable => !isNetworkConnectionRequired;

  factory TTSVoice.fromMap(Map<dynamic, dynamic> map) {
    return TTSVoice(
      name: map['name'] as String? ?? 'default',
      locale: map['locale'] as String? ?? 'en-US',
      isNetworkConnectionRequired:
          map['isNetworkConnectionRequired'] as bool? ?? false,
      quality: map['quality'] as String? ?? 'normal',
      latency: (map['latency'] as num?)?.toInt() ?? 100,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'locale': locale,
      'isNetworkConnectionRequired': isNetworkConnectionRequired,
      'quality': quality,
      'latency': latency,
    };
  }
}

/// Detailed evaluation of language synthesis viability on the current device.
class TTSLanguageSupport {
  final String languageCode;
  final TTSLanguageSupportStatus status;
  final int availableVoicesCount;
  final TTSVoice? selectedVoice;
  final bool offlineCapable;
  final String? details;

  const TTSLanguageSupport({
    required this.languageCode,
    required this.status,
    required this.availableVoicesCount,
    this.selectedVoice,
    required this.offlineCapable,
    this.details,
  });

  bool get isWorking =>
      status == TTSLanguageSupportStatus.working ||
      status == TTSLanguageSupportStatus.partiallyWorking;

  bool get isUnavailable => status == TTSLanguageSupportStatus.notAvailable;

  String get statusLabel {
    switch (status) {
      case TTSLanguageSupportStatus.working:
        return 'Working (Offline Active)';
      case TTSLanguageSupportStatus.partiallyWorking:
        return 'Partially Working';
      case TTSLanguageSupportStatus.deviceDependent:
        return 'Device Dependent';
      case TTSLanguageSupportStatus.notAvailable:
        return 'Not Available (Voice Not Installed)';
    }
  }
}

/// Exception thrown when safety rules block speech generation.
class TTSSafetyViolationException implements Exception {
  final String reason;
  final String attemptedText;

  const TTSSafetyViolationException({
    required this.reason,
    required this.attemptedText,
  });

  @override
  String toString() =>
      'TTSSafetyViolationException: $reason (Text: "$attemptedText")';
}
