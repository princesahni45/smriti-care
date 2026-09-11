# MindCare NER: Voice Feature Integration Documentation

## Overview

This document describes the end-to-end integration of the offline deterministic Voice Assistant with MindCare NER's game engine (`MemoryMatchScreen`, `GameStorageService`) and reminder subsystems (`CaregiverService`).

The system adheres strictly to dementia-safe UI/UX principles, offline-first reliability, explicit patient confirmation, and strict boundaries preventing generative models from calculating scores, giving medical dosage advice, or altering configuration settings.

---

## Architectural Principles

1. **Deterministic Execution over Generative AI**
   - User speech is converted to text via on-device ASR and matched to safe intents through deterministic regular expression and keyword patterns (`IntentPatternsEn`, `IntentPatternsHi`, `IntentPatternsAs`).
   - Generative language models (e.g., local Qwen) are strictly isolated from game scoring, medical schedule alterations, and security-critical decisions.
   - When generative assistance is unavailable or uninstalled, the entire deterministic workflow remains fully operational.

2. **Zero Hallucination Guarantee for Schedules and Medication**
   - The voice assistant reads only actual stored routines and reminders from `CaregiverService`.
   - It never invents, guesses, or suggests tasks.
   - If the caregiver has not configured a routine, the system explicitly tells the user that no routine is configured.
   - Medication reminders strictly report scheduled times and names; voice commands never provide dosage advice or alter medication regimens.

3. **Caregiver Security and Session Protection**
   - Voice commands cannot alter caregiver PINs, access caregiver configuration tabs, or change security settings.
   - The active patient session remains isolated and cannot be reset or modified via voice input.

4. **TTS and Offline Fallback**
   - All spoken text is rendered visually on screen inside `VoiceAssistantSheet` to ensure accessibility for hard-of-hearing elderly users.
   - If TTS is disabled or unavailable, the user can read the complete response on screen with high-contrast text and large typography.

---

## Integration Flows

### Flow A: Start a Memory Game
- **Trigger**: "Start a memory game", "Open memory game", "Play memory match", or Hindi/Assamese equivalents ("मेमोरी गेम शुरू करो", "মেমৰি গেম আৰম্ভ কৰক").
- **Intent**: `VoiceIntent.startMemoryGame`
- **Execution**:
  1. Recognized text is displayed on screen.
  2. `VoiceFeatureService.instance.getMemoryGameInstruction(languageCode)` produces a clear, dementia-friendly instruction ("Opening the memory game. Find the matching pairs of cards at your own pace.").
  3. Instruction is spoken via TTS (if available) and stored as the last verified instruction.
  4. App navigates directly to `/games/memory-match`.
  5. The memory game uses purely deterministic math for scoring:
     ```dart
     final int accuracyScore = ((matchedPairs / (totalMoves > 0 ? totalMoves : 1)) * 100).round().clamp(0, 100);
     final int timeEfficiency = (100 - (secondsElapsed / 2)).round().clamp(0, 100);
     final int finalScore = (accuracyScore * 0.65 + timeEfficiency * 0.35).round().clamp(0, 100);
     ```
     Generative AI is not invoked during gameplay or score computation.

### Flow B: What Should I Do Today? (Daily Routine)
- **Trigger**: "What should I do today?", "Show my routine", "Today schedule", or localized variants ("आज मुझे क्या करना चाहिए?", "মই আজি কি কৰা উচিত?").
- **Intent**: `VoiceIntent.showTodayReminders`
- **Execution**:
  1. Queries `CaregiverService.instance.getReminders()`.
  2. If the routine list is empty, outputs the exact safe string:
     - English: *"Your caregiver has not configured a routine for today."*
     - Hindi: *"आपकी देखभालकर्ता ने आज के लिए कोई दिनचर्या निर्धारित नहीं की है।"*
     - Assamese: *"আপোনাৰ পৰিচৰ্যাকৰ্তাই আজিৰ বাবে কোনো নিয়মসূচী নিৰ্ধাৰণ কৰা নাই।"*
  3. If items exist, concatenates scheduled times and reminder titles in chronological order without hallucinating or embellishing activities.
  4. Visual card updates and TTS speaks the schedule.

### Flow C: When is My Medicine Reminder? (Medication Check)
- **Trigger**: "When is my medicine reminder?", "Next medicine", "When do I take medicine?", or localized variants ("मेरी दवाई का समय कब है?", "মোৰ ঔষধৰ সময় কেতিয়া?").
- **Intent**: `VoiceIntent.readNextReminder`
- **Execution**:
  1. Filters local reminders for medication items (category `medication` or title containing keywords like `medicine`, `dawa`, `osodh`).
  2. Identifies the next upcoming medication reminder.
  3. Outputs only the reminder title and scheduled time (e.g., *"Your next medicine reminder is Morning Tablet at 08:00 AM."*).
  4. Never provides dosage instructions, titration, or pharmaceutical recommendations.
  5. Does not allow marking medicine as taken or altering schedules via voice alone.

### Flow D: Repeat Instruction
- **Trigger**: "Repeat", "Say that again", "Can you repeat?", or localized variants ("फिर से कहो", "পুনৰ কওক").
- **Intent**: `VoiceIntent.repeatInstruction`
- **Execution**:
  1. Retrieves `VoiceFeatureService.instance.lastVerifiedInstruction`.
  2. If an instruction was previously stored, repeats it verbatim through TTS and the visual modal.
  3. If no prior instruction was recorded, prompts: *"There is no previous instruction to repeat. How can I help you?"*
  4. Never delegates repeat queries to LLMs, ensuring 100% fidelity to the original statement.

### Flow E: Help Me (Caregiver Assistance)
- **Trigger**: "Help me", "Need help", "Call caregiver", or localized variants ("मुझे मदद चाहिए", "মোক সহায় লাগে").
- **Intent**: `VoiceIntent.openCaregiverHelp`
- **Execution**:
  1. Enforces mandatory patient confirmation: requires tapping the confirm button or saying "yes" before triggering any alert.
  2. Does not automatically dial emergency services or transmit alerts without deliberate interaction.
  3. Navigates to `/caregiver-help` upon confirmation.

---

## Integration Services & Components

### 1. `VoiceFeatureService` (`lib/services/voice/voice_feature_service.dart`)
Central helper coordinating voice interactions with feature stores:
- `getMemoryGameInstruction({String languageCode})`
- `getTodayRoutineSummary({CaregiverService? caregiverService, String languageCode})`
- `getNextMedicineReminderSummary({CaregiverService? caregiverService, String languageCode})`
- `lastVerifiedInstruction` / `setLastVerifiedInstruction(String text)`

### 2. `VoiceAssistantSheet` (`lib/features/voice_assistant/widgets/voice_assistant_sheet.dart`)
Elderly-accessible bottom sheet modal containing:
- High-contrast visual listening orb and real-time state badge (`Listening`, `Processing`, `Speaking`, `Idle`).
- Live speech recognition transcription text display.
- One-touch manual action buttons and "Type Instead" text fallback.
- Direct execution of Flows A through E with GoRouter navigation.

### 3. `MainShellScreen` Floating Action Button (`lib/screens/main_shell_screen.dart`)
- Accessible 64x64 Floating Action Button labeled "Voice Help" with high visual contrast.
- Provides immediate access to the voice assistant from any primary screen without gesture requirements.

---

## Verification and Safety Test Suite

The test suite in `test/voice_feature_integration_test.dart` verifies:
1. **Intent Classification**: English, Hindi, and Assamese pattern matching for all 5 flows.
2. **Deterministic Game Scoring**: Verifies that `MemoryMatchScreen` calculates scores mathematically without external or AI dependencies.
3. **No-Hallucination Routines**: Asserts that `VoiceFeatureService` reports actual stored items or accurately communicates unconfigured routines.
4. **Medication Guardrails**: Confirms medication title and time extraction while strictly omitting dosage advice.
5. **Exact Repetition**: Tests that repeated instructions match previous outputs verbatim without AI regeneration.
6. **Confirmation Requirement**: Ensures caregiver help requests enforce confirmation before navigation or notification.
7. **Offline Operation**: Verifies all flows execute locally without network access.
8. **Security Boundary**: Verifies caregiver PINs cannot be inspected, retrieved, or modified through voice channels.
