// lib/core/models/daily_step_record.dart
//
// FIX: Added offline-first step tracking data model
// Represents a patient's daily walking activity, sensor baseline, and sync metadata.

class DailyStepRecord {
  final String patientId;
  final String date; // yyyy-MM-dd
  final int steps;
  final int goal; // default 10,000
  final int baselineSensorValue;
  final int lastSensorValue;
  final DateTime updatedAt;
  final String syncStatus; // 'pending' | 'synced'
  final String source; // 'device_step_sensor'

  const DailyStepRecord({
    required this.patientId,
    required this.date,
    required this.steps,
    this.goal = 10000,
    required this.baselineSensorValue,
    required this.lastSensorValue,
    required this.updatedAt,
    this.syncStatus = 'pending',
    this.source = 'device_step_sensor',
  });

  /// Factory for brand new day initialization
  factory DailyStepRecord.initial({
    required String patientId,
    required String date,
    int baseline = 0,
  }) {
    return DailyStepRecord(
      patientId: patientId,
      date: date,
      steps: 0,
      goal: 10000,
      baselineSensorValue: baseline,
      lastSensorValue: baseline,
      updatedAt: DateTime.now(),
      syncStatus: 'pending',
    );
  }

  /// Calculated metrics
  double get progressPercentage => (steps / goal).clamp(0.0, 1.0);
  int get remainingSteps => (goal - steps).clamp(0, goal);
  bool get isGoalCompleted => steps >= goal;

  DailyStepRecord copyWith({
    String? patientId,
    String? date,
    int? steps,
    int? goal,
    int? baselineSensorValue,
    int? lastSensorValue,
    DateTime? updatedAt,
    String? syncStatus,
    String? source,
  }) {
    return DailyStepRecord(
      patientId: patientId ?? this.patientId,
      date: date ?? this.date,
      steps: steps ?? this.steps,
      goal: goal ?? this.goal,
      baselineSensorValue: baselineSensorValue ?? this.baselineSensorValue,
      lastSensorValue: lastSensorValue ?? this.lastSensorValue,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'date': date,
      'steps': steps,
      'goal': goal,
      'baselineSensorValue': baselineSensorValue,
      'lastSensorValue': lastSensorValue,
      'updatedAt': updatedAt.toIso8601String(),
      'syncStatus': syncStatus,
      'source': source,
    };
  }

  factory DailyStepRecord.fromMap(Map<String, dynamic> map) {
    return DailyStepRecord(
      patientId: map['patientId'] as String? ?? 'MC-2048',
      date: map['date'] as String? ?? '',
      steps: (map['steps'] as num?)?.toInt() ?? 0,
      goal: (map['goal'] as num?)?.toInt() ?? 10000,
      baselineSensorValue: (map['baselineSensorValue'] as num?)?.toInt() ?? 0,
      lastSensorValue: (map['lastSensorValue'] as num?)?.toInt() ?? 0,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      syncStatus: map['syncStatus'] as String? ?? 'pending',
      source: map['source'] as String? ?? 'device_step_sensor',
    );
  }
}
