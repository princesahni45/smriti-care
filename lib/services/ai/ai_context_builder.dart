// lib/services/ai/ai_context_builder.dart
//
// Structured Dementia-Safe Prompt and Context Builder for MindCare NER.

import 'ai_request.dart';

class AIContextBuilder {
  const AIContextBuilder();

  /// Constructs a localized, bounded prompt suitable for an on-device quantized Qwen model.
  String buildPrompt(AIRequest request) {
    final systemPrompt = _getSystemPrompt(request.languageCode);
    final contextSpecificInstruction = _getContextInstruction(request);

    return '<|im_start|>system\n'
        '$systemPrompt\n'
        '$contextSpecificInstruction\n'
        '<|im_end|>\n'
        '<|im_start|>user\n'
        'Patient Name: ${request.patientName}\n'
        'Request: ${request.prompt}\n'
        '<|im_end|>\n'
        '<|im_start|>assistant\n';
  }

  String _getSystemPrompt(String languageCode) {
    switch (languageCode) {
      case 'hi':
        return 'आप स्मृति केयर के एक शांत और दयालु साथी हैं। '
            'वरिष्ठ नागरिक के लिए उत्तर 1 या 2 छोटे वाक्यों में दें। '
            'कोई दवा की सलाह या निदान न दें। '
            'जरूरत पड़ने पर देखभालकर्ता से बात करने को कहें।';
      case 'as':
        return 'আপুনি স্মৃতি কেয়াৰৰ এজন শান্ত আৰু মৰমিয়াল সহায়ক। '
            'বয়োজ্যেষ্ঠৰ বাবে উত্তৰ ১ বা ২টা চুটি বাক্যত দিয়ক। '
            'কোনো ঔষধৰ পৰামৰ্শ বা ৰোগ নিৰ্ণয় নকৰিব। '
            'প্ৰয়োজন হ’লে সেৱাদাতাক সোধক।';
      case 'en':
      default:
        return 'You are a warm, reassuring assistant for an elderly person with memory impairment. '
            'Keep answers to 1 or 2 calm, simple sentences. '
            'Never give medical diagnoses or medication advice. '
            'Suggest contacting their caregiver if they need help.';
    }
  }

  String _getContextInstruction(AIRequest request) {
    switch (request.contextType) {
      case AIContextType.greeting:
        return 'Instruction: Give a warm, comforting greeting.';
      case AIContextType.gameExplanation:
        final game = request.metadata['gameTitle'] ?? 'this activity';
        return 'Instruction: Explain $game in simple, non-pressuring steps.';
      case AIContextType.reminderRepeat:
        final reminder = request.metadata['reminderTitle'] ?? 'your schedule';
        return 'Instruction: Reassure the user about $reminder.';
      case AIContextType.caregiverAssistance:
        return 'Instruction: Gently encourage the patient to let their caregiver assist.';
      case AIContextType.generalQuery:
        return 'Instruction: Answer simply and cheerfully.';
    }
  }
}
