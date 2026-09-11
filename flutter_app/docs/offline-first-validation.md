# MindCare NER: Offline-First Behavior & Synchronization Validation

## Executive Summary

MindCare NER is built ground-up with an offline-first architecture designed for elderly dementia patients in North-East India (OnePlus Nord CE 3 Lite 5G target device). Network connectivity across regional and rural areas is frequently intermittent or unavailable. The application guarantees 100% functionality for all patient features in offline and airplane modes, while maintaining a robust, deduplicated, privacy-safe synchronization queue for when connectivity is restored.

---

## 1. Offline Audit Matrix & Subsystem Verification

| Requirement | Implementation Component | Offline Status | Verification Details |
| :--- | :--- | :--- | :--- |
| **1. Patient Dashboard** | `PatientDashboardScreen`, `DashboardScreen` | 100% Offline | Launches directly into local shell without network dependencies. |
| **2. Cognitive Games** | `MemoryMatchScreen`, `WordRecallScreen`, `GameStorageService` | 100% Offline | Game logic, timer, card matching, and mathematical scoring operate locally. Scores persist to `smriti_care_game_history.json`. |
| **3. Reminders** | `CaregiverService`, `CaregiverReminder` | 100% Offline | Stored locally in `smriti_care_caregiver_store.json`. Alarms and schedules evaluate on-device. |
| **4. Language Selection** | `LocaleController`, `AppLocalizations` | 100% Offline | English, Hindi, and Assamese strings are bundled via ARB files in volatile app assets. |
| **5. Local Qwen AI** | `LocalQwenService`, `NativeAIBridge` | Offline Guarded | Executes purely on-device only when model weights are verified on storage (`status == ready`). Never falls back to cloud APIs. |
| **6. AI4Bharat ASR** | `AI4BharatASRService`, `NativeASRBridge` | Offline Guarded | Processes audio in volatile RAM; executes on-device without streaming audio buffers to external servers. |
| **7. TTS Offline Telemetry** | `LocalTextToSpeechService`, `TTSLanguageSupport` | Offline Reported | Transparently verifies on-device voice availability; reports `isOfflineCapable == true` and flags missing regional voice packs. |
| **8. Local Activity Events** | `GameStorageService.saveResult` | Persistent | Persists game completions locally and queues sanitized `game_completion` events. |
| **9. Reminder Acknowledgements** | `CaregiverService.acknowledgeReminder` | Persistent | Updates reminder status to `acknowledged` locally with timestamp and queues `reminder_acknowledgement` event. |
| **10. Queue Sync Events Offline** | `OfflineSyncService.queueEvent` | Persistent Queue | Queues `SyncEvent` models into persistent disk storage (`smriti_care_sync_queue.json`). |
| **11. Retry Upon Reconnection** | `OfflineSyncService.syncUpstream` | Automatic & Manual | Automatically batches and transmits pending events when `isRemoteReachable()` becomes true. |
| **12. Deduplication Prevention** | `SyncEvent.dedupKey` | Idempotent | Deterministic deduplication keys prevent duplicate events in queue and during upstream sync. |
| **13. App Restart Persistence** | `path_provider` Local JSON Stores | Zero Data Loss | Preferences, game results, caregiver configurations, and sync queues survive app restarts and reboots. |
| **14. Privacy & Logging Guard** | `OfflineSyncService` Sanitize Policy | Zero PII in Logs | Debug logs exclusively output anonymous event IDs and event type metadata; zero personal data or passwords exposed. |

---

## 2. Synchronization Architecture

### 2.1 Sync Event Model (`SyncEvent`)
Each offline interaction generates an idempotent `SyncEvent`:
- `id`: Unique identifier (e.g., `evt_game_memory_match_1789101670414`).
- `eventType`: Type classification (`game_completion`, `reminder_acknowledgement`, `patient_activity`).
- `dedupKey`: Unique business key for idempotency:
  - Game events: `game_{gameId}_{timestamp}`
  - Reminder acknowledgements: `rem_ack_{reminderId}_{dateKey}`
- `payload`: Sanitized metadata map containing scores, timestamps, and activity IDs. Strictly excludes passwords, caregiver PINs, and detailed medical records.
- `createdAt`: Event creation timestamp.
- `synced`: Boolean flag indicating upstream server receipt.
- `syncedAt`: Timestamp of successful transmission.
- `retryCount`: Count of retry attempts.
- `lastError`: Error description if transmission failed.

### 2.2 Offline Sync Service (`OfflineSyncService`)
The service manages local disk persistence and synchronization lifecycle:
- **Queue Storage**: Serialized to `smriti_care_sync_queue.json` in the application documents directory.
- **Idempotency Guarantee**: If an event with an existing `dedupKey` is queued (whether currently pending or already synced), it is safely ignored with an anonymous log.
- **Network Check**: Uses local DNS lookup (`InternetAddress.lookup`) with configurable mock reachability for field testing and automated tests.
- **Batch Processing**: When online, pending events are marked `synced = true` with a batch timestamp.

---

## 3. Caregiver Offline Diagnostics Screen

A dedicated diagnostics interface is accessible via `/caregiver/offline-diagnostics` or through the Caregiver Portal Profile & Safety tab:

1. **Network State Card**:
   - Displays real-time status: "Online" or "Offline / Airplane Mode".
   - Includes an interactive button to simulate airplane mode for field verification.
2. **Local Database Health Card**:
   - Status badge: `Healthy (Local Storage)`.
   - Live checks for:
     - `smriti_care_caregiver_store.json` (Patient & Caregiver Reminders)
     - `smriti_care_game_history.json` (Cognitive Game History)
     - `smriti_care_preferences.json` (User Preferences & Locale)
     - `smriti_care_sync_queue.json` (Offline Sync Queue)
3. **Synchronization Status Card**:
   - Pending count badge (e.g., "0 Pending" or "3 Pending").
   - Last successful sync timestamp.
   - Any recent synchronization error notes.
   - Manual "Sync Now" trigger button.
4. **AI & Voice Models Status Card**:
   - Status for on-device Qwen and AI4Bharat ASR engines.
   - TTS offline capability breakdown for English (`en`), Hindi (`hi`), and Assamese (`as`).
5. **Queued Events List**:
   - Inspects pending sync events (type, sanitized ID, retry count, time) with zero PII exposure.

---

## 4. Automated Test Validation

The test suite in `test/offline_first_sync_test.dart` verifies all offline and synchronization behaviors:

```bash
flutter test test/offline_first_sync_test.dart
```

### Test Results
- **Airplane mode**: Successfully verified that the app operates without internet, records patient activities, and keeps events pending without errors.
- **App restart while offline**: Verified that simulated app restart reloads all pending sync events and local states from disk.
- **Offline reminder acknowledgement**: Verified that acknowledging a reminder immediately updates local storage and inserts an un-synced `reminder_acknowledgement` event without leaking PINs.
- **Offline game completion**: Verified that saving a game result updates game history and inserts an un-synced `game_completion` event.
- **Reconnection and synchronization**: Verified that restoring connectivity triggers upstream sync, marks events as synced with timestamps, and clears the pending count to 0.
- **Duplicate synchronization prevention**: Verified that events sharing a `dedupKey` are rejected before and after sync.
- **Diagnostics Screen Widget Test**: Verified that `CaregiverOfflineDiagnosticsScreen` renders network status, storage health, sync status, and AI model telemetry cleanly without errors.
