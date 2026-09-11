// lib/core/services/step_counter_service.dart
//
// FIX: Added offline-first step counter service
// Connects to Android hardware step counter sensor via pedometer package.
// Manages sensor lifecycle, baseline tracking, permission states,
// and streams live updates via ValueNotifier.

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pedometer/pedometer.dart';
import '../models/daily_step_record.dart';
import 'step_storage_service.dart';
import 'step_sync_service.dart';

enum StepTrackingStatus {
  loading,
  trackingActive,
  permissionRequired,
  unsupported,
  offline,
}

class StepCounterService {
  StepCounterService._();
  static final StepCounterService instance = StepCounterService._();

  static const MethodChannel _permissionChannel =
      MethodChannel('com.smriticare.smriti_care/step_permission');

  StreamSubscription<StepCount>? _stepSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianSubscription;

  final ValueNotifier<DailyStepRecord> recordNotifier =
      ValueNotifier<DailyStepRecord>(
    DailyStepRecord.initial(
        patientId: 'MC-2048',
        date: StepStorageService.formatDate(DateTime.now())),
  );

  final ValueNotifier<StepTrackingStatus> statusNotifier =
      ValueNotifier<StepTrackingStatus>(StepTrackingStatus.loading);

  final ValueNotifier<bool> isWalkingNotifier = ValueNotifier<bool>(false);

  String _currentPatientId = 'MC-2048';
  bool _isStarted = false;
  int _lastKnownRawSensorValue = 0;

  DailyStepRecord get currentRecord => recordNotifier.value;
  StepTrackingStatus get currentStatus => statusNotifier.value;
  int get lastRawSensorValue => _lastKnownRawSensorValue;

  /// FIX: Initialize and start step counting with proper permission checking
  Future<void> init({String patientId = 'MC-2048'}) async {
    _currentPatientId = patientId;
    if (_isStarted) return;
    _isStarted = true;

    debugPrint(
        '[StepCounterService] Step service initialized for patient: $patientId');

    // Load local stored steps first
    await StepStorageService.instance.init();
    final cached = StepStorageService.instance.getTodayRecordCached();
    if (cached != null) {
      recordNotifier.value = cached;
      _lastKnownRawSensorValue = cached.lastSensorValue;
      debugPrint(
          '[StepCounterService] Today\'s calculated steps (cached): ${cached.steps}');
    }

    // Check Android activity recognition permission before subscribing
    if (Platform.isAndroid) {
      final hasPermission = await checkPermission();
      debugPrint(
          '[StepCounterService] Activity permission: ${hasPermission ? "granted" : "not granted"}');
      if (!hasPermission) {
        statusNotifier.value = StepTrackingStatus.permissionRequired;
        return;
      }
    }

    _startListening();

    // Trigger deferred sync if there are pending records from earlier
    StepSyncService.instance.syncPendingRecords();
  }

  /// Check Android permission via native channel
  Future<bool> checkPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final bool granted =
          await _permissionChannel.invokeMethod('checkActivityPermission') ??
              false;
      return granted;
    } catch (e) {
      debugPrint('[StepCounterService] Permission check error: $e');
      return true; // Fallback to attempting stream directly
    }
  }

  /// Request Android activity recognition permission
  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final bool granted =
          await _permissionChannel.invokeMethod('requestActivityPermission') ??
              false;
      debugPrint(
          '[StepCounterService] Activity permission request result: $granted');
      if (granted) {
        statusNotifier.value = StepTrackingStatus.loading;
        _startListening();
      } else {
        statusNotifier.value = StepTrackingStatus.permissionRequired;
      }
      return granted;
    } catch (e) {
      debugPrint('[StepCounterService] Permission request error: $e');
      return false;
    }
  }

  /// Open application settings if permission was permanently denied
  Future<void> openAppSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _permissionChannel.invokeMethod('openAppSettings');
    } catch (e) {
      debugPrint('[StepCounterService] Open settings error: $e');
    }
  }

  /// Start listening to pedometer stream
  void _startListening() {
    try {
      _stepSubscription?.cancel();
      _stepSubscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
        cancelOnError: false,
      );

      _pedestrianSubscription?.cancel();
      _pedestrianSubscription = Pedometer.pedestrianStatusStream.listen(
        _onPedestrianStatus,
        onError: (_) {},
        cancelOnError: false,
      );

      statusNotifier.value = StepTrackingStatus.trackingActive;
      debugPrint(
          '[StepCounterService] Step sensor available: true, stream active');
    } catch (e) {
      debugPrint('[StepCounterService] Pedometer initialization error: $e');
      debugPrint('[StepCounterService] Step sensor available: false');
      statusNotifier.value = StepTrackingStatus.unsupported;
    }
  }

  /// Called on each hardware step sensor tick
  Future<void> _onStepCount(StepCount event) async {
    final rawSteps = event.steps;
    _lastKnownRawSensorValue = rawSteps;
    debugPrint('[StepCounterService] Raw sensor steps: $rawSteps');

    // Update steps through storage service which enforces daily baseline and monotonic growth
    final updated = await StepStorageService.instance.updateSteps(
      patientId: _currentPatientId,
      sensorValue: rawSteps,
    );

    recordNotifier.value = updated;
    statusNotifier.value = StepTrackingStatus.trackingActive;
    debugPrint(
        '[StepCounterService] Today\'s calculated steps: ${updated.steps}');

    // Intelligent sync: trigger deferred cloud sync
    StepSyncService.instance.syncPendingRecords();
  }

  /// Handle sensor errors (permission denied or unsupported hardware)
  void _onStepCountError(dynamic error) {
    debugPrint('[StepCounterService] Pedometer sensor stream error: $error');
    final errStr = error.toString().toLowerCase();

    if (errStr.contains('permission') || errStr.contains('denied')) {
      statusNotifier.value = StepTrackingStatus.permissionRequired;
    } else if (errStr.contains('sensor') ||
        errStr.contains('unsupported') ||
        errStr.contains('not available') ||
        errStr.contains('nosuchmethod')) {
      statusNotifier.value = StepTrackingStatus.unsupported;
    } else {
      // General failure or sensor sleep
      statusNotifier.value = StepTrackingStatus.trackingActive;
    }
  }

  void _onPedestrianStatus(PedestrianStatus event) {
    isWalkingNotifier.value = (event.status == 'walking');
  }

  /// Retry listening (e.g. after user grants permission)
  Future<void> retry() async {
    statusNotifier.value = StepTrackingStatus.loading;
    final granted = await requestPermission();
    if (granted) {
      _startListening();
    }
  }

  /// Dispose listeners cleanly
  void dispose() {
    _stepSubscription?.cancel();
    _pedestrianSubscription?.cancel();
    _isStarted = false;
  }
}
