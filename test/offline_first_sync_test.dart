// test/offline_first_sync_test.dart
//
// Comprehensive test suite for Offline-First behavior and Synchronization.
// Verifies:
// 1. Airplane mode resilience
// 2. App restart while offline without data loss
// 3. Offline reminder acknowledgement
// 4. Offline game completion
// 5. Reconnection and synchronization
// 6. Duplicate synchronization prevention
// 7. CaregiverOfflineDiagnosticsScreen rendering

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_care/services/sync/offline_sync_service.dart';
import 'package:smriti_care/services/sync/sync_event.dart';
import 'package:smriti_care/core/services/caregiver_service.dart';
import 'package:smriti_care/core/services/game_storage_service.dart';
import 'package:smriti_care/core/models/game_result.dart';
import 'package:smriti_care/services/tts/placeholder_tts_service.dart';
import 'package:smriti_care/features/caregiver/screens/caregiver_offline_diagnostics_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    final sync = OfflineSyncService.instance;
    await sync.clearAll();
    sync.setMockReachability(false); // Default to offline/airplane mode

    await CaregiverService.instance.init();
    await GameStorageService.instance.init();
  });

  group('Offline-First Core Tests', () {
    test('Airplane mode: Operates without internet and safely queues events',
        () async {
      final sync = OfflineSyncService.instance;
      sync.setMockReachability(false);

      final isOnline = await sync.isRemoteReachable();
      expect(isOnline, isFalse);

      final testEvent = SyncEvent(
        id: 'evt_offline_test_001',
        eventType: 'patient_activity',
        dedupKey: 'activity_001',
        payload: {'activityId': 'garden_walk', 'status': 'completed'},
        createdAt: DateTime.now(),
      );

      final queued = await sync.queueEvent(testEvent);
      expect(queued, isTrue);
      expect(sync.getPendingCount(), equals(1));

      // Attempting upstream sync while offline should not crash or mark events as synced
      await sync.syncUpstream();
      expect(sync.getPendingCount(), equals(1));
      expect(sync.lastSuccessfulSync, isNull);
      expect(sync.lastSyncError, contains('offline'));
    });

    test('App restart while offline: Preserves pending queue and local state',
        () async {
      final sync = OfflineSyncService.instance;
      sync.setMockReachability(false);

      final testEvent = SyncEvent(
        id: 'evt_restart_001',
        eventType: 'patient_activity',
        dedupKey: 'restart_key_001',
        payload: {'action': 'water_intake'},
        createdAt: DateTime.now(),
      );
      await sync.queueEvent(testEvent);
      expect(sync.getPendingCount(), equals(1));

      // Simulate app restart by re-initializing the service
      await sync.init();

      final pending = sync.getPendingEvents();
      expect(pending.length, equals(1));
      expect(pending.first.id, equals('evt_restart_001'));
      expect(pending.first.dedupKey, equals('restart_key_001'));
      expect(pending.first.synced, isFalse);
    });

    test(
        'Offline reminder acknowledgement: Updates local state and queues sync event',
        () async {
      final sync = OfflineSyncService.instance;
      final caregiver = CaregiverService.instance;
      sync.setMockReachability(false);

      final reminders = caregiver.getReminders();
      expect(reminders.isNotEmpty, isTrue);

      final targetReminder = reminders.first;
      final initialPendingCount = sync.getPendingCount();

      final ok = await caregiver.acknowledgeReminder(targetReminder.id);
      expect(ok, isTrue);

      // Verify reminder state in CaregiverService
      final updatedList = caregiver.getReminders();
      final updatedReminder =
          updatedList.firstWhere((r) => r.id == targetReminder.id);
      expect(updatedReminder.status, equals('acknowledged'));
      expect(updatedReminder.acknowledgedAt, isNotNull);

      // Verify sync event queued
      expect(sync.getPendingCount(), equals(initialPendingCount + 1));
      final lastEvent = sync.getPendingEvents().last;
      expect(lastEvent.eventType, equals('reminder_acknowledgement'));
      expect(lastEvent.payload['reminderId'], equals(targetReminder.id));
      expect(lastEvent.payload.containsKey('pin'), isFalse);
      expect(lastEvent.payload.containsKey('password'), isFalse);
    });

    test('Offline game completion: Updates game storage and queues sync event',
        () async {
      final sync = OfflineSyncService.instance;
      final gameStorage = GameStorageService.instance;
      sync.setMockReachability(false);

      final initialPendingCount = sync.getPendingCount();

      final result = GameResult(
        id: 'res_offline_001',
        gameId: 'memory_match',
        gameName: 'Memory Match',
        score: 85,
        accuracy: 90,
        attempts: 12,
        correctAnswers: 10,
        wrongAnswers: 2,
        difficulty: 'Medium',
        completionTimeSeconds: 45,
        timestamp: DateTime.now(),
        recommendation: 'Keep practicing daily.',
      );

      await gameStorage.saveResult(result);

      // Verify local storage updated
      final history = gameStorage.getHistory();
      expect(history.any((r) => r.id == 'res_offline_001'), isTrue);

      // Verify sync queue updated
      expect(sync.getPendingCount(), equals(initialPendingCount + 1));
      final lastEvent = sync.getPendingEvents().last;
      expect(lastEvent.eventType, equals('game_completion'));
      expect(lastEvent.payload['gameId'], equals('memory_match'));
      expect(lastEvent.payload['score'], equals(85));
    });

    test(
        'Reconnection and synchronization: Flushes pending events successfully',
        () async {
      final sync = OfflineSyncService.instance;
      sync.setMockReachability(false);

      final event1 = SyncEvent(
        id: 'evt_sync_001',
        eventType: 'game_completion',
        dedupKey: 'sync_test_001',
        payload: {'score': 90},
        createdAt: DateTime.now(),
      );
      final event2 = SyncEvent(
        id: 'evt_sync_002',
        eventType: 'reminder_acknowledgement',
        dedupKey: 'sync_test_002',
        payload: {'reminderId': 'rem-001'},
        createdAt: DateTime.now(),
      );

      await sync.queueEvent(event1);
      await sync.queueEvent(event2);
      expect(sync.getPendingCount(), equals(2));

      // Simulate connectivity returning
      sync.setMockReachability(true);
      expect(await sync.isRemoteReachable(), isTrue);

      // Execute upstream sync
      await sync.syncUpstream();

      expect(sync.getPendingCount(), equals(0));
      expect(sync.lastSuccessfulSync, isNotNull);
      expect(sync.lastSyncError, isNull);

      // Verify individual event statuses
      final all = sync.getAllEvents();
      expect(all.every((e) => e.synced), isTrue);
      expect(all.every((e) => e.syncedAt != null), isTrue);
    });

    test('Duplicate synchronization prevention: Ignores duplicate dedupKey',
        () async {
      final sync = OfflineSyncService.instance;
      sync.setMockReachability(false);

      final event = SyncEvent(
        id: 'evt_dup_001',
        eventType: 'game_completion',
        dedupKey: 'unique_dedup_123',
        payload: {'score': 80},
        createdAt: DateTime.now(),
      );

      final firstInsert = await sync.queueEvent(event);
      expect(firstInsert, isTrue);
      expect(sync.getPendingCount(), equals(1));

      // Attempt to queue second event with same dedupKey
      final duplicateEvent = SyncEvent(
        id: 'evt_dup_002',
        eventType: 'game_completion',
        dedupKey: 'unique_dedup_123', // Same key
        payload: {'score': 80},
        createdAt: DateTime.now(),
      );

      final secondInsert = await sync.queueEvent(duplicateEvent);
      expect(secondInsert, isFalse);
      expect(sync.getPendingCount(), equals(1));

      // Reconnect and sync
      sync.setMockReachability(true);
      await sync.syncUpstream();
      expect(sync.getPendingCount(), equals(0));

      // Attempting to queue identical event after sync should still be rejected
      final postSyncInsert = await sync.queueEvent(duplicateEvent);
      expect(postSyncInsert, isFalse);
      expect(sync.getPendingCount(), equals(0));
    });
  });

  group('Offline Diagnostics Screen Widget Tests', () {
    testWidgets(
        'Renders network state, storage health, sync status, and AI models',
        (WidgetTester tester) async {
      final sync = OfflineSyncService.instance;
      sync.setMockReachability(false);

      await tester.pumpWidget(
        MaterialApp(
          home: CaregiverOfflineDiagnosticsScreen(
            ttsService: PlaceholderTextToSpeechService(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Assert header
      expect(find.text('Offline Diagnostics'), findsOneWidget);

      // Assert Network State
      expect(find.text('Network State'), findsOneWidget);
      expect(find.text('Offline / Airplane Mode'), findsOneWidget);

      // Assert Local Database Status
      expect(find.text('Local Database Status'), findsOneWidget);
      expect(find.text('Patient & Caregiver Reminders'), findsOneWidget);
      expect(find.text('Cognitive Game History'), findsOneWidget);

      // Assert Sync Status
      expect(find.text('Synchronization Status'), findsOneWidget);
      expect(find.text('Sync Now'), findsOneWidget);

      // Assert AI & Voice Models
      expect(find.text('AI & Voice Models Status'), findsOneWidget);
      expect(find.text('Local Qwen Model'), findsOneWidget);
      expect(find.text('AI4Bharat ASR Engine'), findsOneWidget);

      // Assert Pending Events
      expect(find.text('Queued Synchronization Events'), findsOneWidget);
    });
  });
}
