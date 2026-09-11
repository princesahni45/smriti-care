// lib/services/voice/voice_feature_service.dart
//
// Integration service connecting voice interactions to existing game and reminder models.
// Enforces:
// 1. Reading only actual, locally stored routine data (never inventing tasks).
// 2. Clear notification when no routine is configured.
// 3. Reading actual medication reminders without providing dosage advice.
// 4. Storing the last verified instruction for accurate repetition without LLM regeneration.
// 5. Dementia-friendly game instructions.

import '../../core/services/caregiver_service.dart';

class VoiceFeatureService {
  VoiceFeatureService._();
  static final VoiceFeatureService instance = VoiceFeatureService._();

  String? _lastVerifiedInstruction;

  /// Returns the most recently spoken verified instruction or reminder.
  String? get lastVerifiedInstruction => _lastVerifiedInstruction;

  /// Sets the last verified instruction for future replay.
  void setLastVerifiedInstruction(String text) {
    _lastVerifiedInstruction = text;
  }

  /// Flow A: Short dementia-friendly memory game instruction.
  String getMemoryGameInstruction({String languageCode = 'en'}) {
    final instruction = switch (languageCode.toLowerCase()) {
      'hi' =>
        'बोर्ड साफ़ करने के लिए मिलते-जुलते कार्ड के जोड़े खोजें और टैप करें।',
      'as' => 'বৰ্ডখন সম্পূৰ্ণ কৰিবলৈ একে ধৰণৰ কাৰ্ডৰ যোৰা বিচাৰি টেপ কৰক।',
      _ => 'Find and tap matching pairs of cards to clear the board.',
    };
    _lastVerifiedInstruction = instruction;
    return instruction;
  }

  /// Flow B: Summary of today's actual locally stored routine.
  /// Strictly does NOT invent or hallucinate tasks.
  String getTodayRoutineSummary({
    CaregiverService? caregiverService,
    String languageCode = 'en',
  }) {
    final service = caregiverService ?? CaregiverService.instance;
    final reminders = service.getReminders(status: 'upcoming');
    final activeList = reminders.isNotEmpty
        ? reminders
        : service.getReminders().where((r) => r.enabled).toList();

    if (activeList.isEmpty) {
      final noRoutineMsg = switch (languageCode.toLowerCase()) {
        'hi' =>
          'आपके देखभालकर्ता ने आज के लिए कोई दिनचर्या निर्धारित नहीं की है।',
        'as' => 'আপোনাৰ কেয়াৰগিভাৰে আজিৰ বাবে কোনো দিনলিপি প্ৰস্তুত কৰা নাই।',
        _ => 'Your caregiver has not configured a routine for today.',
      };
      _lastVerifiedInstruction = noRoutineMsg;
      return noRoutineMsg;
    }

    // Format actual schedule
    final items = activeList
        .take(3)
        .map((r) => '${r.title} at ${r.scheduledTime}')
        .join(', ');
    final routineMsg = switch (languageCode.toLowerCase()) {
      'hi' => 'आज की दिनचर्या में शामिल हैं: $items।',
      'as' => 'আজিৰ দিনলিপিত আছে: $items।',
      _ => "Today's schedule includes: $items.",
    };

    _lastVerifiedInstruction = routineMsg;
    return routineMsg;
  }

  /// Flow C: Next scheduled medicine reminder data.
  /// Strictly reads real reminder schedule without providing dosage advice.
  String getNextMedicineReminderSummary({
    CaregiverService? caregiverService,
    String languageCode = 'en',
  }) {
    final service = caregiverService ?? CaregiverService.instance;
    final allReminders = service.getReminders();

    // Filter for actual medication reminders
    final medReminders = allReminders.where((r) {
      final isMedType = r.type.toLowerCase() == 'medication';
      final hasMedTitle = r.title.toLowerCase().contains('medicine') ||
          r.title.toLowerCase().contains('dawa') ||
          r.title.toLowerCase().contains('osodh');
      return (isMedType || hasMedTitle) && r.enabled;
    }).toList();

    if (medReminders.isEmpty) {
      final noMedMsg = switch (languageCode.toLowerCase()) {
        'hi' => 'आपके लिए कोई दवाई का रिमाइंडर निर्धारित नहीं है।',
        'as' => 'আপোনাৰ বাবে কোনো ঔষধৰ ৰিমাইণ্ডাৰ নিৰ্ধাৰণ কৰা হোৱা নাই।',
        _ => 'You do not have any medicine reminders scheduled.',
      };
      _lastVerifiedInstruction = noMedMsg;
      return noMedMsg;
    }

    // Find first upcoming or first available
    final nextMed = medReminders.firstWhere(
      (r) => r.status == 'upcoming',
      orElse: () => medReminders.first,
    );

    final medMsg = switch (languageCode.toLowerCase()) {
      'hi' =>
        'आपका अगला दवाई का रिमाइंडर ${nextMed.title}, ${nextMed.scheduledTime} पर है।',
      'as' =>
        'আপোনাৰ পৰৱৰ্তী ঔষধৰ ৰিমাইণ্ডাৰ ${nextMed.title}, ${nextMed.scheduledTime} ত আছে।',
      _ =>
        'Your next medicine reminder is ${nextMed.title} at ${nextMed.scheduledTime}.',
    };

    _lastVerifiedInstruction = medMsg;
    return medMsg;
  }
}
