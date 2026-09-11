# MindCare NER / Smriti Care Architecture Specification

Date: 2026-09-11
Target Hardware: OnePlus Nord CE 3 Lite 5G (Android 15 / API 35)
Target Locales: English (en), Hindi (hi), Assamese (as)

---

## 1. Introduction & Mission

MindCare NER (Smriti Care) is an assistive mobile platform engineered specifically for elderly individuals experiencing cognitive decline, dementia, and Alzheimer disease, as well as their primary family caregivers.

Dementia-safe design imposes non-negotiable architectural constraints:
1. Interfaces must be unambiguous, oversized, high-contrast, and strictly free of confusing decorative elements (e.g., zero emojis).
2. The core functionality (SOS, medication reminders, safe return home, cognitive games) must work completely offline without internet reliance.
3. Critical life-safety actions must remain 100 percent deterministic and must never be governed, delayed, or summarized by non-deterministic generative AI models.

---

## 2. Current Architecture (Baseline)

### 2.1 Starting State
The baseline Flutter application was established by migrating functional UI prototypes from a prior web repository into Flutter:
- Entry Point: `lib/main.dart` initializing `lib/app.dart`.
- Navigation: `go_router` declaring static routes (`/`, `/dashboard`, `/caregiver-dashboard`, `/games`, etc.).
- UI Components: Split between `lib/features/`, `lib/screens/`, and `lib/widgets/`.
- State Management: Mostly `StatefulWidget` local state, assisted by static singletons (`CaregiverService.instance`, `GameStorageService.instance`).
- Data Storage: Local SQLite database (`app_database.dart`) and path-based file storage (`game_storage_service.dart`).
- Cognitive Games: Memory Match, Word Recall, and Different Object, storing results in local files.

### 2.2 Architectural Deficits Identified in Audit
1. Mixed Widget Organization: Unstandardized distribution across `lib/widgets/`, `lib/shared/widgets/`, and `lib/screens/`.
2. Lack of Explicit Service Interfaces: Direct static singleton calls prevent clean unit testing, dependency substitution, and test mocking.
3. Lack of Explicit AI Safety Boundaries: No defined interface separating planned conversational features from critical safety mechanisms.
4. Hardcoded Localization: Translation dictionaries exist in `assets/i18n/`, but no dynamic switching mechanism exists in the Dart layer.

---

## 3. Target Architecture

The project adheres to a modular, feature-oriented clean architecture:

```
lib/
  core/
    constants/       # Color tokens, layout dimensions, typography
    errors/          # Domain exceptions (StorageException, SafetyException)
    localization/    # AppLocaleConfig, translation delegates (en, hi, as)
    routing/         # Centralized AppRoutes constants and GoRouter config
    storage/         # LocalStorageService interface & implementations
    theme/           # Dementia-friendly light, dark, and high-contrast themes
    utils/           # Pure formatting and validation helpers
  services/
    ai/              # AIService contract & placeholder implementations
    voice/           # SpeechRecognitionService & DeterministicVoiceIntentRouter
    tts/             # TextToSpeechService contract & implementations
    sync/            # SyncService contract & implementations
    notifications/   # LocalNotificationService contract
  features/
    patient/         # Patient dashboard, daily care routines
    caregiver/       # Caregiver dashboard, tabs, activity timeline, alerts
    games/           # Cognitive games (Memory Match, Word Recall, Different Object)
    reminders/       # Medication and schedule management
    voice_assistant/ # Spoken dementia companion interface
    safety/          # Emergency SOS, Safe Return Home navigation
  shared/
    widgets/         # Reusable dementia-safe buttons, cards, headers
    models/          # Re-exported domain models across feature boundaries
  app.dart           # App-level MaterialApp and router initialization
  main.dart          # Entry point and bootstrap
```

### 3.1 Service Interfaces & Contracts
All cross-cutting capabilities are encapsulated behind explicit abstract contracts:
- `AIService` (`lib/services/ai/ai_service.dart`): Reassuring conversational companion. Marked as Planned / Not yet connected.
- `SpeechRecognitionService` (`lib/services/voice/speech_recognition_service.dart`): Speech-to-text listener. Marked as Planned / Not yet connected.
- `TextToSpeechService` (`lib/services/tts/text_to_speech_service.dart`): Dementia-tuned TTS synthesis (default rate 0.85). Marked as Planned / Not yet connected.
- `VoiceIntentRouter` (`lib/services/voice/voice_intent_router.dart`): Decoupled intent classification.
- `LocalStorageService` (`lib/core/storage/local_storage_service.dart`): Key-value and entity storage abstraction.
- `SyncService` (`lib/services/sync/sync_service.dart`): Offline-first sync manager. Marked as Planned / Not yet connected.

---

## 4. End-to-End Data Flow

```
+-------------------------------------------------------------------------+
|                              User Interface                             |
|  [Patient Dashboard]  [Caregiver Portal]  [Cognitive Games]  [Safety]   |
+-------------------+-------------------+-------------------+-------------+
                    |                   |                   |
                    v                   v                   v
+-------------------------------------------------------------------------+
|                     Deterministic Business Logic Layer                  |
|  - Game Scoring Engine (Exact Milliseconds, Moves, Accuracy)            |
|  - Deterministic Voice Intent Router (Keyword / Safety Priority)        |
|  - Emergency SOS Trigger & Coordinates Dispatch                         |
|  - Scheduled Medication Alarm Dispatcher                                |
+-------------------------------------------------------------------------+
                    |                   |                   |
                    v                   v                   v
+-------------------------------------------------------------------------+
|                       Service Layer & Storage                           |
|  - LocalStorageService / SQLite (AppDatabase, GameStorageService)       |
|  - LocalNotificationService (Immediate & Scheduled Alarms)              |
|  - AudioService (Local Sound Effects & Reassuring Guidance)             |
+-------------------------------------------------------------------------+
                    | (Optional / Background)
                    v
+-------------------------------------------------------------------------+
|                  AI & Cloud Sync Layer (Decoupled)                      |
|  - AIService (Planned Qwen / Reassuring Chat - NEVER on Critical Path)  |
|  - SyncService (Planned Cloud Upstream Push when Online)                |
+-------------------------------------------------------------------------+
```

---

## 5. Architectural Safety Directives

### 5.1 Why Deterministic Game Scoring Must Remain Separate from Qwen / LLMs

1. Clinical Validity and Longitudinal Consistency:
   Cognitive decline monitoring relies on standardized psychometric and neuropsychological metrics (e.g., exact millisecond reaction times, number of mismatch attempts in card games, correct object classification counts). An LLM is inherently probabilistic; generating or evaluating game scores via a language model introduces non-deterministic hallucinations, drift, and grading variance. Clinical caregivers require repeatable, mathematically exact metrics over weeks and months to detect real neurological decline.

2. Zero Latency and 100 Percent Offline Operation:
   Elderly users become agitated or confused if a game hangs or delays while awaiting an inference response. The scoring engine evaluates results instantaneously on-device using pure Dart arithmetic, ensuring zero battery strain and flawless offline operation.

3. Complete Predictability:
   Scoring logic contains zero subjective reasoning. A match is either correct or incorrect; the move count is an integer increment. LLMs must never be in the scoring loop.

### 5.2 Why Emergency SOS and Medication Logic Must NOT Be Controlled by an LLM

1. Unacceptable Risk of Hallucination in Life-Critical Decisions:
   If an elderly patient presses SOS or says "Help me, I fell down", the system must trigger immediate native phone dialing and SMS dispatch with exact GPS coordinates. An LLM in this critical execution path risks:
   - Refusal or conversational evasion ("I am an AI assistant and cannot provide medical assistance...").
   - Hallucinating that the situation is resolved or benign.
   - Summarizing or altering critical emergency contact numbers.
   
2. Network and Latency Fatalities:
   Emergencies often occur in areas with poor cellular data connectivity or during device offline states. An emergency routine that relies on cloud LLM inference or heavy local model initialization could delay an SOS call by 5 to 30 seconds or fail entirely. Deterministic code executes within 2 milliseconds on bare Android APIs.

3. Regulatory Compliance:
   Medical and assistive devices must provide verifiable, deterministic audit trails for alarms and alerts. Medication schedules (drug name, dosage time, frequency) are strict temporal constants established by physicians and family caregivers. LLMs are prohibited from altering, reinterpreting, or dismissing medication reminders.

---

## 6. Verification & Quality Gates

Every modification to the MindCare NER codebase must satisfy four mandatory quality gates:
1. `dart format`: Code must be cleanly formatted to standard Dart conventions.
2. `dart analyze`: Must produce zero compiler errors and zero unresolved warnings.
3. `flutter test`: 100 percent of automated unit, model, and widget tests must pass.
4. `flutter build apk --debug`: Must compile cleanly for Android 15 (Target SDK 35).
5. Zero Emojis: All UI strings, logs, documentation, and comments must remain completely free of emojis.
