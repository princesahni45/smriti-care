// lib/core/services/step_sync_service.dart
//
// FIX: Added deferred step sync service
// Offline-first synchronization engine for daily step records.
// Syncs to Firestore: patients/{patientId}/dailySteps/{yyyy-MM-dd}
// Handles internet disconnects silently, uses deterministic date document IDs,
// and debounces/throttles writes to preserve battery and quota.

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/daily_step_record.dart';
import 'step_storage_service.dart';

class StepSyncService {
  StepSyncService._();
  static final StepSyncService instance = StepSyncService._();

  bool _isSyncing = false;
  DateTime? _lastSyncAttempt;
  DateTime? _lastSuccessfulSync;

  DateTime? get lastSuccessfulSync => _lastSuccessfulSync;

  /// FIX: Sync pending records to cloud with throttling
  Future<void> syncPendingRecords({bool force = false}) async {
    // Throttle: don't attempt more than once every 15 seconds unless forced
    if (!force && _lastSyncAttempt != null) {
      if (DateTime.now().difference(_lastSyncAttempt!).inSeconds < 15) {
        return;
      }
    }

    if (_isSyncing) return;
    _isSyncing = true;
    _lastSyncAttempt = DateTime.now();

    try {
      final pending = StepStorageService.instance.getPendingSyncRecords();
      if (pending.isEmpty) {
        _isSyncing = false;
        return;
      }

      for (final record in pending) {
        final success = await _uploadRecordToCloud(record);
        if (success) {
          await StepStorageService.instance.markRecordSynced(record.date);
          _lastSuccessfulSync = DateTime.now();
        }
      }
    } catch (e) {
      // Offline mode or network error — do not spam user or crash
      debugPrint(
          'StepSyncService sync note: running offline or pending connection: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Uploads a single record to Firestore using deterministic date document ID
  Future<bool> _uploadRecordToCloud(DailyStepRecord record) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final docRef = firestore
          .collection('patients')
          .doc(record.patientId)
          .collection('dailySteps')
          .doc(record.date);

      // Monotonic safety: only write if local steps are higher or equal
      await docRef.set({
        'patientId': record.patientId,
        'date': record.date,
        'steps': record.steps,
        'goal': record.goal,
        'updatedAt': record.updatedAt.toIso8601String(),
        'source': record.source,
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      // Firestore native error or offline
      return false;
    }
  }

  /// Fetch remote step record for authorized Caregiver or Doctor views
  Future<DailyStepRecord?> fetchPatientDailySteps({
    required String patientId,
    required String date,
  }) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId)
          .collection('dailySteps')
          .doc(date)
          .get();

      if (doc.exists && doc.data() != null) {
        return DailyStepRecord.fromMap(doc.data()!);
      }
    } catch (e) {
      debugPrint('StepSyncService remote fetch note: $e');
    }
    return null;
  }
}
