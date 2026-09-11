# MindCare NER Voice Subsystem Architecture

Date: 2026-09-11
Target Device: OnePlus Nord CE 3 Lite 5G (Android 15 / API 35)
Target Locales: English (en), Hindi (hi), Assamese (as)

---

## 1. Executive Status & Mission

The MindCare NER voice subsystem provides an accessible, dignified speech interface for elderly patients experiencing cognitive impairment, Alzheimer disease, or dementia. 

### Status
- Speech recognition foundation and lifecycle state machines are implemented on-device.
- Concurrency control guarantees that only one microphone session can be active at a time.
- Permission states (Granted, Denied, Permanently Denied) are handled with calm, elderly-friendly guidance.
- Text fallback ensures that patients in noisy rooms or with speech impairments can still navigate and interact.
- **Important Disclaimer**: Cloud speech recognition is NOT integrated. Offline Assamese speech recognition is explicitly NOT claimed to be active in this release; it is architected for upcoming integration with localized on-device models.

---

## 2. Voice State Machine & Error Architecture

The voice subsystem operates across six deterministic states:
1. `idle`: Microphone is closed; no listening or synthesis in progress.
2. `listening`: Microphone is open; recording buffer actively captures spoken input.
3. `processing`: Spoken utterance is undergoing local acoustic feature extraction and deterministic intent resolution.
4. `speaking`: Text-to-Speech synthesis is actively playing through the device speaker.
5. `unavailable`: Voice subsystem is restricted or not supported by hardware/OS.
6. `error`: A recoverable or terminal failure has occurred (e.g., permission refusal, microphone busy).

### Error Hierarchy (`VoiceError`)
- `permissionDenied`: Patient tapped Deny. System presents a gentle prompt: "Microphone permission is required to listen to your voice. Please tap Allow."
- `permissionPermanentlyDenied`: Patient or OS disabled the microphone in system settings. Prompt instructs: "Microphone access is turned off in device settings. Please ask your caregiver to enable it."
- `microphoneBusy`: Another session or recording is active. Concurrency locks prevent duplicate sessions.
- `serviceUnavailable`: Model weights or engine components are not loaded.
- `unknown`: Audio was unintelligible or muffled. The UI presents "Try Again" and opens the on-screen text fallback.

---

## 3. Privacy, Storage & Offline Requirements

1. **Zero Cloud Audio Transmission**:
   Elderly medical, conversational, and ambient home audio must never be streamed to external third-party cloud servers.
2. **Zero Permanent Audio Retention**:
   Voice buffers exist solely in volatile memory during listening and processing. Upon session completion, stop, cancel, or timeout, buffers are immediately purged. No raw audio files (`.wav`, `.mp3`) are written to disk.
3. **100 Percent Offline Functionality**:
   Elderly users in rural North-Eastern India often encounter weak or non-existent 4G/5G connections. The system must never block or degrade core navigation because of network unavailability.

---

## 4. Planned AI4Bharat & Indic ASR Integration

For production multilingual speech recognition across North-Eastern India, the architecture isolates native platform plugins behind `SpeechRecognitionService`:

```
+-------------------------------------------------------------+
|               User Interface / VoiceAssistantSheet          |
+-------------------------------------------------------------+
                               |
                               v
+-------------------------------------------------------------+
|             SpeechRecognitionService (Abstract)             |
+-------------------------------------------------------------+
          |                                        |
          v                                        v
+-----------------------------------+    +---------------------+
| PlaceholderSpeechRecognitionService |    |  IndicASRService    |
| (Current Safe Baseline Engine)    |    |  (Planned On-Device |
|                                   |    |   AI4Bharat Model)  |
+-----------------------------------+    +---------------------+
```

### Planned AI4Bharat IndicWhisper / Conformer Pipeline:
- Quantized ONNX / TFLite acoustic models embedded directly into Android asset storage.
- Local inference supporting Assamese (`as`) and Hindi (`hi`) without remote API keys or network latency.
- Strict vocabulary clamping for emergency keywords ("Help", "SOS", "Bachao", "Sahay", "Ghar jao", "Dawa").

---

## 5. Planned TTS Integration

- Integration with native Android Text-To-Speech engine (`flutter_tts` / Android `TextToSpeech` API).
- Elderly listening constraints: Default speech cadence configured to `rate: 0.85` (15% slower than default) with neutral pitch (`1.0`) to avoid high-frequency hearing loss comprehension issues.
- User control: Dedicated "Stop Sound" / `stopSpeaking()` control immediately halts playback if the patient feels overwhelmed.

---

## 6. Deterministic Voice Intent Routing

Spoken utterances are passed to `DeterministicVoiceIntentRouter`:
- **Emergency SOS**: Keywords `help`, `emergency`, `sos`, `madad`, `bachao`, `sahay` route immediately with 100% confidence to the emergency phone dialer.
- **Safe Return Home**: Keywords `home`, `ghar`, `ghar jao`, `ghor` trigger navigation.
- **Medication Reminders**: Keywords `reminder`, `medicine`, `dawa`, `osodh`, `dawai` open scheduled checklists.
- Free-form generative LLMs are strictly forbidden from intercepting safety and emergency commands.
