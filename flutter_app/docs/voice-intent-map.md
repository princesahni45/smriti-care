# MindCare NER Voice Intent Specification & Safety Map

## 1. Architectural Overview

The MindCare NER voice system employs a strictly deterministic, rule-based **VoiceIntentRouter** (`DeterministicVoiceIntentRouter`) designed specifically for elderly individuals with mild-to-moderate dementia. 

### Core Architectural Principles
1. **Deterministic Rule Matching**: Spoken commands are classified exclusively through precompiled regexes and keyword sets stored in separate language configuration files (`intent_patterns_en.dart`, `intent_patterns_hi.dart`, `intent_patterns_as.dart`).
2. **AI Boundary (Qwen Isolation)**: Local small language models (such as Qwen) are utilized solely for conversational explanation, gentle reassurance, or rephrasing fallback messages. Qwen is strictly prohibited from classifying voice commands, routing intents, or triggering app state mutations.
3. **Audio Privacy & Offline Execution**: All ASR decoding (AI4Bharat Indic Conformer) and speech synthesis (system on-device TTS) occur strictly on device without remote cloud transmission or persistent microphone storage.
4. **Dementia Safety & Cognitive Friction**: Potentially disruptive actions (navigating away from current screen, calling caregiver, emergency SOS, cancelling sessions, or marking medication taken) require high-contrast visual and spoken confirmation.
5. **No Hallucinated Execution**: Commands with low acoustic confidence (< 0.60) are rejected with a calm request to repeat or use on-screen buttons.

---

## 2. Supported Intent Taxonomy

The router restricts classification to exactly 10 safe deterministic intents:

| # | Intent Identifier | Action / Route | Confirmation Required | Description |
| :--- | :--- | :--- | :--- | :--- |
| 1 | `openGames` | `/games` | No | Navigates to the Cognitive Games Hub screen. |
| 2 | `startMemoryGame` | `/games/memory-match` | No | Launches the Memory Match card exercise directly. |
| 3 | `showTodayReminders` | `/reminders` | No | Displays the daily schedule and reminder list. |
| 4 | `readNextReminder` | TTS Vocalization | No | Speaks the next scheduled reminder via TTS. |
| 5 | `repeatInstruction` | TTS Replay | No | Replays the last spoken audio instruction or prompt. |
| 6 | `openCaregiverHelp` | `/caregiver-help` | **Yes** | Triggers caregiver contact and SOS emergency dialog. |
| 7 | `openSettings` | `/settings` | No | Navigates to application settings and language selector. |
| 8 | `goHome` | `/patient/dashboard` | **Yes** | Returns to the primary patient home dashboard. |
| 9 | `cancel` | Dismiss Sheet | **Yes** | Closes the voice assistant session cleanly. |
| 10 | `unknown` | Safe Fallback | N/A | Safe fallback when no pattern matches. |

---

## 3. Multilingual Sample Phrase Mapping

Intent patterns are maintained in dedicated configuration files per language:
- `lib/services/voice/patterns/intent_patterns_en.dart`
- `lib/services/voice/patterns/intent_patterns_hi.dart`
- `lib/services/voice/patterns/intent_patterns_as.dart`

### 3.1 English (`en`)
| Intent | Sample Phrases | Confirmation Prompt | Execution Feedback |
| :--- | :--- | :--- | :--- |
| `openGames` | "open games", "show games", "brain games", "play games", "i want to play" | "Would you like to open Brain Games?" | "Opening Brain Games." |
| `startMemoryGame` | "start memory game", "memory match", "play memory game", "card matching" | "Would you like to start the Memory Match game?" | "Starting Memory Match." |
| `showTodayReminders` | "show today reminders", "show reminders", "what are my reminders", "my schedule" | "Would you like to view your reminders for today?" | "Opening today reminders." |
| `readNextReminder` | "read next reminder", "what is my next reminder", "next medicine", "what should i do next" | "Would you like me to read your next reminder?" | "Reading your next reminder." |
| `repeatInstruction` | "repeat instruction", "repeat", "say that again", "what did you say", "listen again" | "Would you like me to repeat the last instruction?" | "Repeating the last instruction." |
| `openCaregiverHelp` | "open caregiver help", "call caregiver", "help me", "i need help", "emergency help", "sos" | "Do you need immediate help or want to contact your caregiver?" | "Connecting you with caregiver assistance." |
| `openSettings` | "open settings", "settings", "change language", "app settings", "preferences" | "Would you like to open Settings?" | "Opening Settings." |
| `goHome` | "go home", "take me home", "main screen", "dashboard", "back to home" | "Would you like to go back to the Home Dashboard?" | "Returning to Home Dashboard." |
| `cancel` | "cancel", "stop", "never mind", "close", "exit voice", "stop listening" | "Would you like to cancel this action?" | "Voice assistant closed." |
| `unknown` | Unmatched input | N/A | "I could not understand that request. You can say: Open Games, Show Reminders, or Help." |

### 3.2 Hindi (`hi`) - Devanagari & Transliteration
| Intent | Sample Phrases | Confirmation Prompt | Execution Feedback |
| :--- | :--- | :--- | :--- |
| `openGames` | "खेल खोलो", "गेम दिखाओ", "दिमागी खेल", "khel kholo", "game dikhao" | "क्या आप दिमागी खेल खोलना चाहते हैं?" | "दिमागी खेल खोल रहे हैं।" |
| `startMemoryGame` | "मेमोरी गेम शुरू करो", "मेमोरी खेल", "याददाश्त वाला खेल", "memory game shuru karo" | "क्या आप मेमोरी मैच खेल शुरू करना चाहते हैं?" | "मेमोरी मैच खेल शुरू कर रहे हैं।" |
| `showTodayReminders` | "आज के रिमाइंडर दिखाओ", "रिमाइंडर दिखाओ", "दवाई का समय", "reminder dikhao" | "क्या आप आज के रिमाइंडर देखना चाहते हैं?" | "आज के रिमाइंडर खोल रहे हैं।" |
| `readNextReminder` | "अगला रिमाइंडर पढ़ो", "अगली दवाई कौन सी है", "अगला काम क्या है", "agla reminder padho" | "क्या आप अगला रिमाइंडर सुनना चाहते हैं?" | "अगला रिमाइंडर सुना रहे हैं।" |
| `repeatInstruction` | "फिर से बोलो", "दोहराओ", "क्या कहा आपने", "phir se bolo", "dohrao" | "क्या आप पिछली बात फिर से सुनना चाहते हैं?" | "पिछली बात दोहरा रहे हैं।" |
| `openCaregiverHelp` | "देखभालकर्ता को बुलाओ", "मदद चाहिए", "सहायता", "madad chahiye", "caregiver ko phone karo" | "क्या आपको तत्काल सहायता चाहिए या देखभालकर्ता से संपर्क करना है?" | "देखभालकर्ता सहायता से जोड़ रहे हैं।" |
| `openSettings` | "सेटिंग्स खोलो", "भाषा बदलो", "सेटिंग दिखाओ", "settings kholo", "bhasha badlo" | "क्या आप सेटिंग्स खोलना चाहते हैं?" | "सेटिंग्स खोल रहे हैं।" |
| `goHome` | "घर जाओ", "होम स्क्रीन", "मुख्य पृष्ठ", "डैशबोर्ड", "ghar jao", "home screen" | "क्या आप मुख्य पृष्ठ पर वापस जाना चाहते हैं?" | "मुख्य पृष्ठ पर वापस जा रहे हैं।" |
| `cancel` | "रद्द करो", "बंद करो", "कैंसिल", "छोड़ो", "radd karo", "band karo" | "क्या आप इसे रद्द करना चाहते हैं?" | "सहायक बंद कर दिया गया।" |
| `unknown` | Unmatched input | N/A | "यह आदेश समझ नहीं आया। आप कह सकते हैं: खेल खोलो, रिमाइंडर दिखाओ, या मदद।" |

### 3.3 Assamese (`as`) - Assamese Script & Transliteration
| Intent | Sample Phrases | Confirmation Prompt | Execution Feedback |
| :--- | :--- | :--- | :--- |
| `openGames` | "খেল খোলক", "খেল দেখুৱাওক", "খেল খেলিম", "khel kholok", "khel dekhuwaok" | "আপুনি খেল খোলিব বিচাৰে নেকি?" | "খেল খোলি থকা হৈছে।" |
| `startMemoryGame` | "মেমৰি খেল আৰম্ভ কৰক", "স্মৃতি খেল", "কাৰ্ড মেচ", "memory khel arombho korok" | "আপুনি স্মৃতি খেল আৰম্ভ কৰিব বিচাৰে নেকি?" | "স্মৃতি খেল আৰম্ভ কৰা হৈছে।" |
| `showTodayReminders` | "আজিৰ ৰিমাইণ্ডাৰ দেখুৱাওক", "ৰিমাইণ্ডাৰ দেখুৱাওক", "ঔষধৰ সময়", "ajir reminder dekhuwaok" | "আপুনি আজিৰ ৰিমাইণ্ডাৰ চাব বিচাৰে নেকি?" | "আজিৰ ৰিমাইণ্ডাৰ দেখুওৱা হৈছে।" |
| `readNextReminder` | "পৰৱৰ্তী ৰিমাইণ্ডাৰ পঢ়ক", "পৰৱৰ্তী ঔষধ কি", "poroborti reminder porhok" | "আপুনি পৰৱৰ্তী ৰিমাইণ্ডাৰ শুনিব বিচাৰে নেকি?" | "পৰৱৰ্তী ৰিমাইণ্ডাৰ পঢ়ি থকা হৈছে।" |
| `repeatInstruction` | "আকৌ কওক", "পুনৰ কওক", "কি ক’লে", "akou kouk", "punor kouk" | "আপুনি শেষৰ কথাষাৰ আকৌ শুনিব বিচাৰে নেকি?" | "শেষৰ কথাষাৰ পুনৰ কোৱা হৈছে।" |
| `openCaregiverHelp` | "কেয়াৰগিভাৰক মাটক", "সহায় লাগে", "সহায় কৰক", "caregiverok matok", "xohay lage" | "আপোনাক তৎক্ষণাৎ সহায় লাগে নে কেয়াৰগিভাৰৰ লগত যোগাযোগ কৰিব বিচাৰে?" | "কেয়াৰগিভাৰৰ সৈতে সংযোগ কৰা হৈছে।" |
| `openSettings` | "ছেটিংছ খোলক", "ভাষা সলনি কৰক", "ছেটিংছ", "settings kholok", "bhasa xoloni korok" | "আপুনি ছেটিংছ খোলিব বিচাৰে নেকি?" | "ছেটিংছ খোলি থকা হৈছে।" |
| `goHome` | "ঘৰলৈ যাওক", "হোম স্ক্ৰীন", "মূল পৃষ্ঠা", "ghoroloi jaok", "home screen" | "আপুনি মূল পৃষ্ঠালৈ উভতি যাব বিচাৰে নেকি?" | "মূল পৃষ্ঠালৈ উভতি যোৱা হৈছে।" |
| `cancel` | "বাতিল কৰক", "বন্ধ কৰক", "নালাগে", "batil korok", "bondho korok" | "আপুনি এইটো বাতিল কৰিব বিচাৰে নেকি?" | "সহায়ক বন্ধ কৰা হ’ল।" |
| `unknown` | Unmatched input | N/A | "কথাষাৰ বুজিব পৰা নহ’ল। আপুনি ক’ব পাৰে: খেল খোলক, ৰিমাইণ্ডাৰ দেখুৱাওক, বা সহায়।" |

---

## 4. Medical & Operational Safety Guardrails

The `VoiceSafetyGuard` component enforces strict boundary checks before any intent pattern matching occurs:

### 4.1 Prohibited Medication Dosage Modifications
- **Safety Rule**: Voice commands must never change medicine dosage, timing, or pill quantities.
- **Trigger Patterns**: Matches keywords such as "change dose", "increase mg", "take 500mg", "double dosage", "खुराक बदलो", "ঔষধৰ মাত্ৰা সলনি কৰক".
- **Enforcement**: Throws `VoiceSafetyViolation` with `PROHIBITED_DOSAGE_CHANGE`.
- **User Guidance**: *"Voice commands cannot modify medication dosages or schedules. Please refer to your physical prescription or speak with your caregiver or Dr. Ananya Bora."*

### 4.2 Prohibited Caregiver PIN Changes
- **Safety Rule**: Voice commands must never access, reveal, or change caregiver PIN credentials.
- **Trigger Patterns**: Matches keywords such as "change pin", "reset pin", "caregiver passcode", "पिन बदलो", "পিন সলনি কৰক".
- **Enforcement**: Throws `VoiceSafetyViolation` with `PROHIBITED_PIN_CHANGE`.
- **User Guidance**: *"Caregiver PIN cannot be viewed or changed using voice. Please ask your caregiver to update their PIN directly inside the locked Caregiver Settings panel."*

### 4.3 Prohibited Medical Diagnoses
- **Safety Rule**: Voice assistant must never provide diagnostic claims, clinical assessments, or symptom interpretations.
- **Trigger Patterns**: Matches queries like "do I have Alzheimer's?", "diagnose my symptoms", "what disease do I have?", "क्या मुझे बीमारी है", "মোক কি বেমাৰ হৈছে".
- **Enforcement**: Throws `VoiceSafetyViolation` with `PROHIBITED_MEDICAL_DIAGNOSIS`.
- **User Guidance**: *"Smriti Care cannot provide medical or clinical diagnoses. Please contact your physician, Dr. Ananya Bora, or speak with your caregiver for medical guidance."*

### 4.4 Mandatory Medicine Taken Confirmation
- **Safety Rule**: Medication reminders cannot be marked as taken by voice without an explicit, physical confirmation prompt.
- **Trigger Patterns**: Matches statements like "I took my medicine", "mark medicine as taken", "maine dawai kha li", "osodh khalu".
- **Enforcement**: Flags `requiresConfirmation: true` and presents a confirmation dialog with large touch targets.

### 4.5 Acoustic Confidence Threshold Enforcement
- **Safety Rule**: No command is executed based solely on uncertain ASR results.
- **Threshold**: Any recognized utterance with acoustic confidence strictly below **0.60** (60%) is routed to `VoiceIntentType.unknown`.
- **User Guidance**: *"Speech was not clear enough to perform an action. Please repeat or use the screen buttons."*

---

## 5. End-to-End Execution Flow

```
[User Speaks]
      |
[AI4Bharat Indic ASR] -> returns raw text & confidence score
      |
[UI Display] -> displays recognized text in high-contrast card
      |
[LanguageDetector] -> analyzes Unicode script (Devanagari \u0900-\u097F -> hi, Assamese \u0980-\u09FF -> as, Latin -> en)
      |
[TextNormalizer] -> lowercases, strips punctuation (including danda), collapses whitespace
      |
[VoiceSafetyGuard]
      +---> Is Dosage Change / PIN Change / Medical Diagnosis?
      |        |-- YES -> Display Safety Alert Card & speak clinical disclaimer via TTS
      +---> Is ASR Confidence < 0.60?
      |        |-- YES -> Display uncertain fallback prompt; prompt user to retry
      +---> Is Medicine Taken reported?
               |-- YES -> Route to showTodayReminders with requiresConfirmation: true
      |
[Deterministic Pattern Matching] (Specific intents tested before general intents)
      |-- English: intent_patterns_en.dart
      |-- Hindi: intent_patterns_hi.dart
      |-- Assamese: intent_patterns_as.dart
      |
[Confirmation Check]
      +---> requiresConfirmation == true?
      |        |-- Display dialog: "We heard: [Utterance]"
      |        |-- Vocalize confirmation prompt via TTS (0.75x cadence)
      |        |-- User taps "Yes, Continue" -> Proceed to action
      |        |-- User taps "No, Retry" -> Cancel and restart session
      |
[Deterministic App Action]
      |-- openGames -> context.go('/games')
      |-- startMemoryGame -> context.go('/games/memory-match')
      |-- showTodayReminders -> context.go('/reminders')
      |-- readNextReminder -> TTS vocalizes next reminder details
      |-- repeatInstruction -> TTS replays last spoken utterance
      |-- openCaregiverHelp -> context.go('/caregiver-help')
      |-- openSettings -> context.go('/settings')
      |-- goHome -> context.go('/patient/dashboard')
      |-- cancel -> Navigator.of(context).pop()
      |-- unknown -> Speak safe fallback; Qwen rephrasing fallback
```
