# Text-To-Speech (TTS) Support Matrix & Audio Narration Guidelines

## 1. Executive Summary

This document defines the on-device Text-To-Speech (TTS) architecture, language support status, elderly cognitive speech parameters, and dementia safety guardrails for the MindCare NER application running on the **OnePlus Nord CE 3 Lite 5G** (Snapdragon 695 5G, 8GB RAM, Android 13/14/15).

### Core Architectural Principles
1. **Zero Cloud Transmission**: All speech audio synthesis is conducted on-device using local Android TTS engines. Text strings are NEVER sent to remote cloud TTS APIs.
2. **Strict Truthfulness & Honesty for Assamese**: If an Assamese voice engine or offline Indic TTS model is not installed on the user device, the application explicitly reports the language as **Not Available**. It **never** silently translates or substitutes Assamese text into English or Hindi audio.
3. **Elderly Calm Cadence**: The default speech rate is slowed down to **0.75x** (configurable between 0.5x and 1.0x) to assist elderly patients with memory loss or auditory processing delays.
4. **Dementia Safety Guardrails**: Voice narration of medication dosage changes or pill adjustments is strictly intercepted and blocked. Sensitive patient records are blocked on unsecured screens.
5. **Dementia-Safe Replay**: Prominent, high-contrast replay controls ("Listen Again") accompany all spoken instructions, paired with clean on-screen text fallbacks for hearing-impaired users.

---

## 2. Language Support Matrix

| Language | ISO Code | Script | Support Category | On-Device Engine Required | Offline Capability | Fallback Behavior |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **English** | `en` | Latin | **Working** | Android Embedded Google TTS (`en-US` / `en-IN` offline voice pack) | 100% Offline | High-contrast on-screen text display |
| **Hindi** | `hi` | Devanagari | **Partially Working / Device-Dependent** | Android Google TTS Indic Pack (`hi-IN` offline voice data) | 100% Offline (if voice pack downloaded) | High-contrast on-screen text display |
| **Assamese** | `as` | Eastern Nagari | **Not Available / Device-Dependent** | Regional Indic TTS Engine (e.g. AI4Bharat Indic-TTS / eSpeak-NG Indic APK) | Requires regional engine installation | Clean Assamese on-screen text fallback with transparent status message |

### 2.1 Category Definitions

- **Working**: Pre-bundled and active out-of-the-box on standard OnePlus / OxygenOS builds with offline voice synthesis capabilities.
- **Partially Working**: Engine architecture is supported, but actual offline availability depends on whether the user device has downloaded the offline voice data pack through Android System Settings.
- **Device-Dependent**: The operating system or third-party accessibility service must provide the engine binaries and acoustic tables for this locale.
- **Not Available**: The language cannot synthesize audio because no compatible voice is installed on the device. The application transparently notifies the user/caregiver without falling back to cloud APIs or incorrect translation.

---

## 3. Hardware Profile: OnePlus Nord CE 3 Lite 5G

- **SoC**: Qualcomm Snapdragon 695 5G
- **System Memory**: 8 GB LPDDR4X
- **Audio Output**: Dual Stereo Speakers with 200% Ultra Volume Mode (beneficial for elderly hearing loss)
- **Audio Latency**: < 120 ms local synthesis queue latency
- **Resident RAM Impact**: < 18 MB for active Android TTS engine bindings

---

## 4. Dementia Safety Guardrails

### 4.1 Medication Dosage Blocking Policy
Dementia patients often experience confusion regarding prescription times and dosages. Generative AI models (e.g., local Qwen) or free-form user chats might inadvertently produce incorrect dosages.
- **Rule**: Any text containing numerical dosage units (e.g., `50mg`, `10ml`, `2 tablets`, `pills`) or medication modification phrasing (`take`, `increase`, `double`, `skip your medicine`) throws a `TTSSafetyViolationException`.
- **Enforcement**: The `LocalTextToSpeechService` inspects the candidate utterance before sending any byte to the hardware speaker.

### 4.2 Unsecured Screen Guardrail
- **Rule**: Patient health history, diagnostic classifications, or private family records must NOT be spoken out loud unless the user is on an authenticated, secured screen.
- **Enforcement**: Screens pass `isSecuredContext: false` on public or lock screens, preventing accidental ambient broadcasting of private elderly information.

### 4.3 Utterance Simplicity & Brevity
- Spoken instructions are kept brief (typically 1 to 2 sentences) and conversational.
- Complex technical jargon or system error logs are suppressed in audio narration.

---

## 5. User Interface & Controls

### 5.1 DementiaVoiceNarrationBar
Located on patient activity screens, cognitive games, and reminder views:
- **Listen Again (Replay)**: Large primary touch target (minimum 48dp height) with high-contrast text and replay icon.
- **Pause / Resume**: Clear toggle allowing the patient or caregiver to pause audio.
- **Stop Button**: High-contrast coral stop button to immediately silence audio.
- **Text Fallback**: Clean card displaying the complete transcribed sentence in large readable typography.

### 5.2 Caregiver TTS Diagnostics Screen (`/caregiver/tts-diagnostics`)
Allows caregivers and clinicians to:
- Audit installed device voices and locales.
- Inspect offline capability indicators.
- Adjust the global elderly speech cadence slider (`0.5x` to `1.0x`).
- Test English, Hindi, and Assamese synthesis independently.
- Test safety guardrail interception of medication dosage advice.
