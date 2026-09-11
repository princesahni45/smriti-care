// lib/core/services/step_storage_service.dart
//
// FIX: Added offline-first step storage service
// 100% Offline Local Storage for Patient Daily Steps.
// Handles baseline persistence, daily midnight resets, device reboot re-basing,
// and local history for Caregiver/Doctor review.

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/daily_step_record.dart';

class StepStorageService {
  StepStorageService._();
  static final StepStorageService instance = StepStorageService._();

  bool _isInitialized = false;
  final Map<String, DailyStepRecord> _history =
      {}; // date (yyyy-MM-dd) -> record

  @visibleForTesting
  void clearForTesting() {
    _history.clear();
    _isInitialized = true;
  }

  /// Format date as deterministic yyyy-MM-dd
  static String formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Initialize and load stored step history
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final file = await _getStorageFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final decoded = jsonDecode(content);
          if (decoded is Map<String, dynamic>) {
            _history.clear();
            decoded.forEach((dateKey, val) {
              if (val is Map<String, dynamic>) {
                _history[dateKey] = DailyStepRecord.fromMap(val);
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint('StepStorageService init error: $e');
    } finally {
      _isInitialized = true;
    }
  }

  Future<File> _getStorageFile() async {
    Directory dir;
    try {
      dir = await getApplicationDocumentsDirectory();
    } catch (_) {
      dir = Directory.systemTemp;
    }
    return File('${dir.path}/smriti_care_step_history.json');
  }

  Future<void> _persist() async {
    try {
      final file = await _getStorageFile();
      final map = <String, dynamic>{};
      _history.forEach((date, record) {
        map[date] = record.toMap();
      });
      await file.writeAsString(jsonEncode(map));
    } catch (e) {
      debugPrint('StepStorageService persist error: $e');
    }
  }

  /// FIX: Added daily sensor baseline handling & midnight reset logic
  /// Retrieves or initializes today's record.
  /// If today's record doesn't exist, establishes a new daily baseline using current sensor value.
  Future<DailyStepRecord> getOrCreateTodayRecord({
    required String patientId,
    required int currentSensorValue,
  }) async {
    await init();
    final today = formatDate(DateTime.now());

    if (_history.containsKey(today)) {
      return _history[today]!;
    }

    // New calendar day: start with 0 steps and set baseline to current sensor reading
    final newRecord = DailyStepRecord(
      patientId: patientId,
      date: today,
      steps: 0,
      goal: 10000,
      baselineSensorValue: currentSensorValue,
      lastSensorValue: currentSensorValue,
      updatedAt: DateTime.now(),
      syncStatus: 'pending',
    );
    _history[today] = newRecord;
    await _persist();
    return newRecord;
  }

  /// FIX: Update today's steps with monotonicity guarantee
  Future<DailyStepRecord> updateSteps({
    required String patientId,
    required int sensorValue,
  }) async {
    await init();
    final today = formatDate(DateTime.now());
    final current = await getOrCreateTodayRecord(
      patientId: patientId,
      currentSensorValue: sensorValue,
    );

    // If sensorValue is 0 or uninitialized, return current
    if (sensorValue <= 0) return current;

    // Check for sensor counter reset/reboot
    int effectiveBaseline = current.baselineSensorValue;
    if (sensorValue < current.lastSensorValue) {
      // Hardware reboot detected: re-baseline so current.steps are preserved
      effectiveBaseline = sensorValue - current.steps;
    }

    // Calculate today's steps from baseline
    final calculated = max(0, sensorValue - effectiveBaseline);

    // Monotonic guarantee: never reduce steps for the day
    final newSteps = max(current.steps, calculated);

    final updated = current.copyWith(
      steps: newSteps,
      baselineSensorValue: effectiveBaseline,
      lastSensorValue: sensorValue,
      updatedAt: DateTime.now(),
      syncStatus: 'pending', // Mark as pending sync when steps change
    );

    _history[today] = updated;
    await _persist();
    return updated;
  }

  /// Mark a specific record as synced
  Future<void> markRecordSynced(String date) async {
    await init();
    if (_history.containsKey(date)) {
      _history[date] = _history[date]!.copyWith(syncStatus: 'synced');
      await _persist();
    }
  }

  /// Retrieve today's record if already stored, or null
  DailyStepRecord? getTodayRecordCached() {
    final today = formatDate(DateTime.now());
    return _history[today];
  }

  /// Retrieve pending records that need cloud synchronization
  List<DailyStepRecord> getPendingSyncRecords() {
    return _history.values.where((r) => r.syncStatus == 'pending').toList();
  }

  /// Retrieve recent history (e.g. last 7 or 30 days) for Caregiver/Doctor dashboards
  List<DailyStepRecord> getRecentHistory({int days = 7, String? patientId}) {
    final list = _history.values.where((r) {
      if (patientId != null && r.patientId != patientId) return false;
      return true;
    }).toList();

    // Sort newest date first
    list.sort((a, b) => b.date.compareTo(a.date));
    return list.take(days).toList();
  }

  /// Calculates 7-day average steps
  int getSevenDayAverageSteps({String? patientId}) {
    final history = getRecentHistory(days: 7, patientId: patientId);
    if (history.isEmpty) return 0;
    final total = history.fold<int>(0, (sum, r) => sum + r.steps);
    return (total / history.length).round();
  }

  /// Counts days where 10,000 goal was completed in last 7 days
  int getGoalCompletedDays({String? patientId, int days = 7}) {
    final history = getRecentHistory(days: days, patientId: patientId);
    return history.where((r) => r.isGoalCompleted).length;
  }
}
