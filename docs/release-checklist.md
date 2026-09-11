# MindCare NER Release Checklist for Smart India Hackathon (SIH) Demonstration

Document Version: 1.0.0
Date: 2026-09-11
Target Device: OnePlus Nord CE 3 Lite 5G (CPH2493, Android 13 / 14 OxygenOS)
Target Platform: Android (ARM64-v8a, armeabi-v7a, x86_64)

---

## 1. Release Checklist Matrix

| Item # | Verification Requirement | Configured Value / Implementation | Status | Verification Detail / Command |
|---|---|---|---|---|
| 1 | Application Name & Icon | Name: "MindCare NER"<br>Icon: `@mipmap/ic_launcher` (all densities) | PASS | Verified in `android/app/src/main/AndroidManifest.xml` (`android:label="MindCare NER"`), `lib/app.dart` (`title: 'MindCare NER'`), and launcher icon assets in `android/app/src/main/res/mipmap-*/`. |
| 2 | Package / Application ID | `com.smriticare.smriti_care` | PASS | Verified in `android/app/build.gradle.kts` (`applicationId = "com.smriticare.smriti_care"`), `android/app/src/main/kotlin/com/smriticare/smriti_care/MainActivity.kt`, and native MethodChannel definitions. |
| 3 | Remove Debug UI from Patient Flow | `debugShowCheckedModeBanner: false`<br>Diagnostic tools hidden | PASS | Verified in `lib/app.dart`. Raw error stack traces and internal debugging bars are excluded from patient screens. |
| 4 | Gate Caregiver Diagnostics | 4-digit PIN Gate (`1234`) | PASS | Caregiver portal, sync diagnostics, and TTS/AI diagnostics require valid PIN authentication via `_openCaregiverWithPin()` in `lib/screens/main_shell_screen.dart` and `lib/features/patient/patient_dashboard_screen.dart`. |
| 5 | No Hardcoded Production Credentials | Zero production secrets or user credentials | PASS | Audited entire codebase. Only local seed/mock caregiver PIN (`1234`) and local database schema constants exist. |
| 6 | No API Keys or Secrets | Zero cloud keys | PASS | No cloud API keys, private tokens, or AWS/GCP secrets in source tree. Offline architecture relies on local services. |
| 7 | App Permissions | `RECORD_AUDIO`<br>`INTERNET`<br>`ACCESS_NETWORK_STATE` | PASS | Declared in `android/app/src/main/AndroidManifest.xml`. Runtime microphone permission handled with elderly-friendly prompt and text fallback if denied. |
| 8 | Offline Startup | Zero internet dependency on cold boot | PASS | Verified in Airplane mode. App launches directly into the patient dashboard without network requests or spinning timeouts. |
| 9 | Patient Kiosk Flow | No-swipe navigation, large buttons | PASS | Large touch targets (>= 48x48 logical pixels), high contrast (#173944 on #FFFFFF), clear visible labels, and single-tap direct navigation. |
| 10 | Caregiver PIN Flow | Session lock & portal access | PASS | Caregiver unlock dialog uses fixed Column/Row keypad (preventing shrinkwrap crashes), validates PIN, and clears keypad buffer on exit. |
| 11 | Language Selection | English ('en'), Hindi ('hi'), Assamese ('as') | PASS | Controlled via `LocaleController`, persisted to local disk (`SharedPreferences`), immediately updates all active widgets without resetting session state. |
| 12 | Games and Reminders | Memory Match, Word Recall, Different Object | PASS | Reminders schedule deterministically. Games feature local deterministic scoring, streaks, and adaptive difficulty without AI tampering. |
| 13 | Voice Feature Status & Fallback | Deterministic Voice Router + High-contrast Narration Bar | PASS | Safe intent classification (`openGames`, `startMemoryGame`, `showTodayReminders`, etc.). When TTS audio or mic is unavailable, high-contrast visual narration bar displays text with replay control. |
| 14 | Qwen & AI4Bharat Availability Status | Honest status reporting (`notInstalled`) | PASS | Services check local model weight presence (`LocalQwenService`, `AI4BharatASRService`). When weights are not preloaded into `/data/data/com.smriticare.smriti_care/files/models/`, app honestly reports `notInstalled` and falls back cleanly to rule-based logic and text input. |
| 15 | Release APK Generation | Gradle `assembleRelease` | PASS | Successfully compiled via `flutter build apk --release` with exit code 0. |
| 16 | Recorded APK Path & Build Version | Path: `build/app/outputs/flutter-apk/app-release.apk`<br>Version: `1.0.0+1`<br>Size: `55.8 MB` | PASS | Release APK verified and present on filesystem. |

---

## 2. Release Build Details

- **Application Name**: MindCare NER
- **Application Package ID**: `com.smriticare.smriti_care`
- **Build Version**: `1.0.0`
- **Build Number**: `1`
- **Gradle Version**: 8.14.0
- **Android Gradle Plugin (AGP)**: 8.9.1
- **Compile SDK Version**: 34
- **Target SDK Version**: 34
- **Minimum SDK Version**: 24 (Android 7.0 Nougat)
- **Output Artifact Path**:
  `build/app/outputs/flutter-apk/app-release.apk`
- **Absolute Artifact Path**:
  `d:\smriti-care\build\app\outputs\flutter-apk\app-release.apk`
- **Artifact Size**: 55.8 MB (58,561,164 bytes)
- **Asset Tree-Shaking**:
  - `CupertinoIcons.ttf`: Reduced from 257,628 to 848 bytes (99.7% reduction)
  - `MaterialIcons-Regular.otf`: Reduced from 1,645,184 to 19,796 bytes (98.8% reduction)

---

## 3. Security, Privacy, and Secret Audit

1. **Static Analysis for API Keys and Secrets**:
   A comprehensive regex audit was conducted across all Dart, Kotlin, and Gradle configuration files. No AWS, GCP, Firebase, OpenAI, Anthropic, or external API keys exist in the repository.
2. **Audio Privacy Guardrails**:
   Microphone audio recorded during speech recognition is processed locally in RAM buffers and discarded immediately. Audio is never stored permanently and never uploaded to any remote endpoint.
3. **Medical Safety Boundaries**:
   Voice commands and LLM responses are strictly barred from modifying medication dosage instructions or diagnosing clinical conditions.
4. **Caregiver PIN Security**:
   The default development PIN is `1234`. Caregiver settings and developer diagnostics cannot be accessed from the patient view without entering this PIN.

---

## 4. Hardware Verification & Model Weight Status

- **Device**: OnePlus Nord CE 3 Lite 5G
- **RAM**: 8 GB LPDDR4X (supports running Qwen 0.6B Q4_K_M quantized LLM requiring ~450 MB RAM).
- **Local Model Storage Path**:
  `/data/data/com.smriticare.smriti_care/files/models/`
- **Current Model Weight Status**:
  In accordance with repository size limits and competition guidelines, binary model weights (~450MB for Qwen and ~150MB for AI4Bharat ASR) are excluded from the repository.
  The application runtime honestly detects their absence, displays `Model Status: notInstalled`, and uses the deterministic `AIFallbackService` and on-screen narration bar without crashing or hanging.

---

## 5. Demonstration Runbook for Evaluators

1. **Install Release APK**:
   ```bash
   adb install -r build/app/outputs/flutter-apk/app-release.apk
   ```
2. **Cold Boot Test**:
   Place device into Airplane mode (disable Wi-Fi and Mobile Data). Launch "MindCare NER". Verify instant rendering of the patient home screen.
3. **Patient Kiosk Interaction**:
   - Tap "Play Cognitive Games" to launch Memory Match. Complete a round and observe deterministic score updates.
   - Tap language button on the dashboard to switch to Hindi or Assamese. Verify immediate UI translation across cards.
   - Tap "Today's Routine" to see deterministic medication and activity reminders.
4. **Voice Intent and Narration**:
   - Tap the voice interaction button. If microphone permission is granted, speak a safe intent ("What should I do today?"). If offline speech models are not preloaded, use the high-contrast text fallback and observe the visual narration bar with audio replay.
5. **Caregiver Gate Verification**:
   - Tap the Caregiver button on the bottom bar.
   - Enter invalid PIN (`0000`) -> Observe rejection.
   - Enter valid PIN (`1234`) -> Observe unlock and navigation to Caregiver Portal (Patient Progress, Reminders Manager, System & Model Diagnostics).
