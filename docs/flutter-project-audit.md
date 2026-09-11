# MindCare NER / Smriti Care Flutter Project Audit Report

Date: 2026-09-11
Target Hardware: OnePlus Nord CE 3 Lite 5G (CPH2465, Android 15 / API 35)
Target Locales: English (en), Hindi (hi), Assamese (as)

---

## 1. Executive Summary

This report documents the architectural, operational, and code-level audit of the Smriti Care (MindCare NER) application. The repository originated with a React/TypeScript prototype located in references/ (formerly src/) and has migrated to a production-targeted Flutter implementation located at the repository root.

The project builds and passes all 18 automated tests with zero errors. The application targets dementia and Alzheimer patients and their caregivers. As such, all interfaces require high contrast, calm color schemes, oversized touch targets, simplified cognitive workflows, offline-first reliability, and strict exclusion of distracting or confusing graphical embellishments such as emojis.

---

## 2. Environment and Identification Details

- Flutter SDK Version: 3.47.3 (channel stable, release build)
- Dart SDK Version: 3.13.3
- Package Name (pubspec.yaml): smriti_care
- Application Title: Smriti Care
- Android Application ID: com.smriticare.smriti_care
- Android Compile SDK: 35 (Android 15)
- Android Min SDK: 21 (Android 5.0 Lollipop)
- Android Target SDK: 35
- Gradle Version: 8.14 (Distribution wrapper)
- Android Gradle Plugin (AGP): 8.9.1
- Java Development Kit (JDK): Eclipse Adoptium OpenJDK 17.0.20.101-hotspot (configured via flutter config --jdk-dir)
- Android NDK: 28.2.13676358
- Entry Point: lib/main.dart

---

## 3. Existing Architecture

### 3.1 Directory Structure
The repository is structured as follows:
- android/: Native Android Gradle configuration and runner.
- assets/: Localization JSON bundles (assets/i18n/), sound assets (assets/sounds/), and icon images (assets/icons/).
- docs/: Project documentation, including this audit report.
- lib/: Core application source code.
  - core/
    - constants/ (color tokens, typography, layout dimensions)
    - database/ (AppDatabase SQLite singleton helper)
    - models/ (data transfer and domain models: Contact, Reminder, GameResult, PatientAlert, PatientStats, ActivityEntry)
    - navigation/ (app_router.dart, navigation route definitions)
    - services/ (CaregiverService, GameStorageService, AudioService, NotificationService)
    - theme/ (app_theme.dart, dementia-friendly light/dark/high-contrast styling)
    - utils/ (formatters, validators)
    - widgets/ (reusable dementia-safe widgets, accessibility buttons, high-contrast cards)
  - features/
    - caregiver/ (caregiver portal, patient monitoring, caregiver dashboard)
    - games/ (cognitive games: Memory Match, Word Scramble, Daily Routine Recall, Pattern Sequence)
    - patient/ (patient home, SOS trigger, safe return home, medication reminders)
  - main.dart (application bootstrap and provider setup)
- references/: Read-only reference directory containing the legacy React/TypeScript web prototype.
- test/: Automated unit and widget tests (18 tests currently covering dashboard, games, caregiver migration, and core widgets).

### 3.2 State Management and Architecture Patterns
- State Management: Primarily uses StatefulWidget and local setState, augmented by InheritedWidget patterns and static singletons.
- Data Persistence: SQLite via sqflite, with local key-value preferences handled via shared_preferences.
- Dependency Injection: Static singleton services (e.g., CaregiverService.instance, GameStorageService.instance, AppDatabase.instance).
- Audio and Alerts: just_audio and flutter_local_notifications.

---

## 4. Existing Features and Verification Status

1. Patient Dashboard (lib/features/patient/screens/patient_dashboard_screen.dart)
   - Status: Implemented and passing widget tests.
   - Details: High-contrast large-touch buttons for Quick Actions, Daily Care routines, and emergency assistance.

2. Cognitive Games Suite (lib/features/games/)
   - Status: Implemented and passing widget and model tests.
   - Games:
     - Memory Match (card flip recall)
     - Word Scramble (linguistic stimulation)
     - Daily Routine Sequence Recall (chronological ordering)
     - Pattern Memory (visual sequence recall)
   - Storage: Game results saved to SQLite database via GameStorageService.

3. Caregiver Dashboard and Monitoring (lib/features/caregiver/)
   - Status: Implemented and passing tests.
   - Details: Displays cognitive score trends, activity timelines, alert feeds, and quick actions for caregiver check-in.

4. Audio and Notification Foundations (lib/core/services/)
   - Status: Foundation code present.
   - Details: NotificationService wraps flutter_local_notifications for medication and schedule prompts. AudioService wraps just_audio.

---

## 5. Missing Features and Placeholders

The following screens or features are currently backed by PlaceholderScreen or stubbed out:

1. Patient Reminders Screen
   - Current State: Backed by PlaceholderScreen.forModule(AppModule.reminders).
   - Requirement: Full medication and daily activity schedule screen with audio readout and simple checkoff buttons.

2. Emergency SOS Screen
   - Current State: Backed by PlaceholderScreen.forModule(AppModule.sos).
   - Requirement: Immediate one-tap calling of primary caregiver and emergency services, SMS dispatch with GPS coordinates, loud alarm beacon.

3. Safe Return Home ("Take Me Home") Screen
   - Current State: Backed by PlaceholderScreen.forModule(AppModule.navigation).
   - Requirement: Simplified GPS navigation display pointing direction towards patient home address with simplified landmarks.

4. Patient Progress and Analytics Screen
   - Current State: Backed by PlaceholderScreen.forModule(AppModule.progress).
   - Requirement: Patient-safe simplified progress summary showing daily streaks and encouraging milestones without stressful metrics.

5. Patient Profile Screen
   - Current State: Backed by PlaceholderScreen.forModule(AppModule.profile).
   - Requirement: View patient emergency medical ID, blood group, emergency contact phone, and caregiver details.

6. Offline Localization Mechanism
   - Current State: Assets exist in assets/i18n/ (en.json, hi.json, as.json, etc.), but lib/ lacks an active localization service or InheritedWidget to switch languages dynamically.
   - Requirement: An AppLocalizations service supporting English, Hindi, and Assamese with fallback to English.

7. Offline Font Asset Bundling
   - Current State: google_fonts is loaded, which relies on network downloads on first render.
   - Requirement: Local TTF bundling or asset fonts to guarantee 100 percent offline operation without layout shift.

---

## 6. Verification Results

All tests and builds were executed on the host system:
- Command: flutter pub get
  Result: Succeeded. All dependencies resolved.
- Command: dart analyze
  Result: 0 errors, 2 minor warnings, 132 infos.
- Command: flutter test
  Result: 18 out of 18 tests passed.
  - test/caregiver_migration_test.dart: Passed.
  - test/dashboard_test.dart: Passed.
  - test/games_migration_test.dart: Passed.
  - test/widget_test.dart: Passed.
- Command: flutter build apk --debug
  Result: Succeeded. Built build/app/outputs/flutter-apk/app-debug.apk (158 MB).

---

## 7. Files That Should Not Be Changed

1. references/ (all files)
   - Do not modify, rewrite, or delete any files in the references/ directory (earlier web prototype).
2. android/build.gradle.kts and android/app/build.gradle.kts core configurations
   - Do not revert the JDK 17 compatibility changes or the SDK 35 configurations.
3. assets/i18n/*.json
   - Preserve existing translation keys across all 10 language files; only add missing keys consistently across all files when needed.

---

## 8. Recommended Folder Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_dimensions.dart
│   │   └── app_typography.dart
│   ├── database/
│   │   └── app_database.dart
│   ├── localization/
│   │   ├── app_localizations.dart
│   │   └── app_localizations_delegate.dart
│   ├── models/
│   │   ├── activity_entry.dart
│   │   ├── contact.dart
│   │   ├── game_result.dart
│   │   ├── patient_alert.dart
│   │   ├── patient_stats.dart
│   │   └── reminder.dart
│   ├── navigation/
│   │   └── app_router.dart
│   ├── services/
│   │   ├── audio_service.dart
│   │   ├── caregiver_service.dart
│   │   ├── game_storage_service.dart
│   │   ├── location_service.dart
│   │   └── notification_service.dart
│   ├── theme/
│   │   └── app_theme.dart
│   ├── utils/
│   │   └── date_formatters.dart
│   └── widgets/
│       ├── dementia_safe_button.dart
│       ├── dementia_safe_card.dart
│       └── high_contrast_text.dart
├── features/
│   ├── caregiver/
│   │   ├── screens/
│   │   └── widgets/
│   ├── games/
│   │   ├── screens/
│   │   └── widgets/
│   └── patient/
│       ├── screens/
│       │   ├── emergency_sos_screen.dart
│       │   ├── patient_dashboard_screen.dart
│       │   ├── patient_profile_screen.dart
│       │   ├── patient_progress_screen.dart
│       │   ├── reminders_screen.dart
│       │   └── safe_return_home_screen.dart
│       └── widgets/
└── main.dart
```

---

## 9. Dependency Risks and Technical Debt

1. google_fonts Runtime Network Fetch
   - Risk: If the device is offline when the app boots for the first time, text may fall back to raw system fonts with uncalibrated metrics, causing layout overflow.
   - Mitigation: Bundle fonts in pubspec.yaml assets or cache them during build.

2. Deprecated withOpacity calls
   - Risk: 132 analyzer infos are generated by withOpacity on Color instances, which Flutter is deprecating in favor of withValues(alpha: ...).
   - Mitigation: Clean up withValues calls systematically in theme and widget files.

3. Background Geolocation and Foreground Services
   - Risk: Safe Return Home and SOS tracking require Android 15 (API 35) foreground service permissions (ACCESS_FINE_LOCATION, FOREGROUND_SERVICE_LOCATION).
   - Mitigation: Ensure AndroidManifest.xml contains explicit service type declarations and permission explanations.

---

## 10. Suggested Implementation Order

1. Phase 1: Localization Foundation
   - Implement lib/core/localization/ to load assets/i18n/ (English, Hindi, Assamese).
   - Hook locale switcher into MaterialApp and replace hardcoded UI strings.

2. Phase 2: Core Patient Essential Modules
   - Replace PlaceholderScreen for Reminders with interactive medication checklist.
   - Replace PlaceholderScreen for SOS with one-touch emergency dialer and SMS dispatcher.
   - Replace PlaceholderScreen for Safe Return Home with simplified location bearing/map.

3. Phase 3: Patient Profile and Progress
   - Implement patient profile screen with emergency contacts and blood type.
   - Implement calm progress screen showing completed daily routines and memory exercises.

4. Phase 4: Offline Hardening and Device Verification
   - Verify zero internet reliance on OnePlus Nord CE 3 Lite 5G.
   - Complete lint cleanup and pass all tests.
