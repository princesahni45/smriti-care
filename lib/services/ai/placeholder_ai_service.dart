// lib/services/ai/placeholder_ai_service.dart
//
// Test Mock Implementation of AIService conforming to updated contract.

import 'ai_service.dart';
import 'ai_model_status.dart';
import 'ai_request.dart';
import 'ai_response.dart';
import 'ai_fallback_service.dart';

class PlaceholderAIService implements AIService {
  final AIFallbackService _fallbackService;
  final AIModelStatus _status;

  const PlaceholderAIService({
    AIFallbackService fallbackService = const AIFallbackService(),
    AIModelStatus status = AIModelStatus.notInstalled,
  })  : _fallbackService = fallbackService,
        _status = status;

  @override
  bool get isAvailable => _status == AIModelStatus.ready;

  @override
  AIModelStatus get status => _status;

  @override
  AIModelBenchmarkMetrics get metrics => const AIModelBenchmarkMetrics();

  @override
  Future<void> initialize() async {}

  @override
  Future<AIResponse> generateResponse(AIRequest request) async {
    return _fallbackService.generateFallback(request, status: _status);
  }

  @override
  Future<void> cancel() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<String> getConversationalResponse({
    required String prompt,
    required String languageCode,
  }) async {
    switch (languageCode) {
      case 'hi':
        return 'नमस्ते, मैं आपकी सहायता के लिए यहाँ हूँ। सब कुछ ठीक है।';
      case 'as':
        return 'নমস্কাৰ, মই আপোনাক সহায় কৰিবলৈ ইয়াত আছোঁ। সকলো ঠিক আছে।';
      case 'en':
      default:
        return 'Hello, I am here with you. Everything is calm and safe.';
    }
  }

  @override
  Future<List<String>> generateMemoryPrompts({
    required String patientName,
    required String topic,
    required String languageCode,
  }) async {
    return const [
      'Tell me about your favorite morning walk.',
      'What is a song you enjoyed listening to?',
    ];
  }
}
