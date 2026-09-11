// lib/services/ai/ai_fallback_service.dart
//
// Deterministic Multilingual Fallback Engine for MindCare NER.
//
// Ensures zero interruption when on-device LLM is not installed, loading,
// or experiencing resource constraints.

import 'ai_request.dart';
import 'ai_response.dart';
import 'ai_model_status.dart';

class AIFallbackService {
  const AIFallbackService();

  /// Generates an immediate deterministic response matching the 5 allowed POC categories.
  AIResponse generateFallback(
    AIRequest request, {
    String? reason,
    AIModelStatus status = AIModelStatus.unavailable,
  }) {
    final text = _resolveResponse(request);
    return AIResponse.fallback(
      text: text,
      reason: reason ?? 'Handled by deterministic dementia-safe rules',
      status: status,
    );
  }

  String _resolveResponse(AIRequest request) {
    final lang = request.languageCode;
    final name = request.patientName;

    switch (request.contextType) {
      case AIContextType.greeting:
        return _greeting(name, lang);

      case AIContextType.gameExplanation:
        final game = request.metadata['gameTitle'] as String? ?? 'Memory Match';
        return _gameExplanation(game, lang);

      case AIContextType.reminderRepeat:
        final reminder =
            request.metadata['reminderTitle'] as String? ?? 'Medicine Reminder';
        final time =
            request.metadata['reminderTime'] as String? ?? 'after meal';
        return _reminderRepeat(reminder, time, lang);

      case AIContextType.caregiverAssistance:
        return _caregiverAssistance(lang);

      case AIContextType.generalQuery:
        return _generalReassurance(name, lang);
    }
  }

  String _greeting(String name, String lang) {
    switch (lang) {
      case 'hi':
        return 'नमस्ते $name जी। आपका दिन शांतिपूर्ण और सुखद हो। मैं यहाँ आपके साथ हूँ।';
      case 'as':
        return 'নমস্কাৰ $name ডাঙৰীয়া। আপোনাৰ দিনটো শুভ হওক। মই আপোনাৰ লগতে আছোঁ।';
      case 'en':
      default:
        return 'Hello $name, it is wonderful to see you. You are in a safe, peaceful place.';
    }
  }

  String _gameExplanation(String game, String lang) {
    switch (lang) {
      case 'hi':
        return '$game एक शांत गतिविधि है। कार्ड्स को ध्यान से देखें और मिलान करें। कोई जल्दी नहीं है।';
      case 'as':
        return '$game এটা সহজ খেল। ছবিবোৰ মনত ৰাখি মিলাওক। কোনো লৰালৰি নাই।';
      case 'en':
      default:
        return '$game is a gentle activity to exercise your memory. Take all the time you need; there is no hurry.';
    }
  }

  String _reminderRepeat(String reminder, String time, String lang) {
    switch (lang) {
      case 'hi':
        return 'आपकी अगली याद: $reminder ($time)। सब कुछ समय पर व्यवस्थित है।';
      case 'as':
        return 'আপোনাৰ পৰৱৰ্তী সোঁৱৰণী: $reminder ($time)। সকলো समयমতে ঠিক কৰা আছে।';
      case 'en':
      default:
        return 'Here is your reminder: $reminder scheduled for $time. Everything is organized for you.';
    }
  }

  String _caregiverAssistance(String lang) {
    switch (lang) {
      case 'hi':
        return 'यदि आपको सहायता चाहिए, तो कृपया अपने देखभालकर्ता को बुलाएं। वे हमेशा आपकी मदद के लिए तैयार हैं।';
      case 'as':
        return 'যদি কিবা সহায় লাগে, তেন্তে আপোনাৰ সেৱাদাতাক মাতক। তেওঁ সহায় কৰিবলৈ সাজু।';
      case 'en':
      default:
        return 'If you need help with anything, please let your caregiver know. They are here to support you.';
    }
  }

  String _generalReassurance(String name, String lang) {
    switch (lang) {
      case 'hi':
        return 'सब कुछ ठीक है $name जी। यदि आपके पास कोई सवाल है, तो हम और आपके देखभालकर्ता यहाँ हैं।';
      case 'as':
        return 'সকলো ঠিকেই আছে $name ডাঙৰীয়া। যিকোনো প্ৰয়োজনত সেৱাদাতাক ক’ব পাৰে।';
      case 'en':
      default:
        return 'Everything is calm and well, $name. If you need any assistance, your caregiver is close by.';
    }
  }
}
