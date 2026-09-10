// lib/core/models/game_result.dart
//
// Data model capturing the result of a completed cognitive activity.
// Strictly non-clinical: records game performance for elderly engagement tracking.

import 'dart:convert';

class GameResult {
  final String id;
  final String patientId;
  final String gameId;
  final String gameName;
  final int score; // 0 - 100
  final int accuracy; // 0 - 100
  final int attempts;
  final int correctAnswers;
  final int wrongAnswers;
  final String difficulty;
  final int completionTimeSeconds;
  final double avgResponseTimeSeconds;
  final DateTime timestamp;
  final String recommendation;
  final String syncStatus; // 'pending', 'synced', 'offline'

  const GameResult({
    required this.id,
    this.patientId = 'MC-2048',
    required this.gameId,
    required this.gameName,
    required this.score,
    required this.accuracy,
    required this.attempts,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.difficulty,
    required this.completionTimeSeconds,
    this.avgResponseTimeSeconds = 0.0,
    required this.timestamp,
    required this.recommendation,
    this.syncStatus = 'pending',
  });

  /// Helpful aliases satisfying Step 7 cognitive game telemetry specs
  int get mistakes => wrongAnswers;
  DateTime get completionTime => timestamp;
  double get responseTime =>
      avgResponseTimeSeconds > 0
          ? avgResponseTimeSeconds
          : (attempts > 0 ? (completionTimeSeconds / attempts) : 0.0);

  int get level {
    final lower = difficulty.toLowerCase();
    if (lower.contains('3') || lower.contains('hard')) return 3;
    if (lower.contains('2') || lower.contains('medium')) return 2;
    return 1;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'gameId': gameId,
      'gameName': gameName,
      'score': score,
      'accuracy': accuracy,
      'attempts': attempts,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'mistakes': mistakes,
      'difficulty': difficulty,
      'level': level,
      'completionTimeSeconds': completionTimeSeconds,
      'responseTime': responseTime,
      'avgResponseTimeSeconds': avgResponseTimeSeconds,
      'timestamp': timestamp.toIso8601String(),
      'completionTime': timestamp.toIso8601String(),
      'recommendation': recommendation,
      'syncStatus': syncStatus,
    };
  }

  factory GameResult.fromMap(Map<String, dynamic> map) {
    return GameResult(
      id: map['id'] as String? ?? '',
      patientId: map['patientId'] as String? ?? 'MC-2048',
      gameId: map['gameId'] as String? ?? 'unknown',
      gameName: map['gameName'] as String? ?? 'Activity',
      score: (map['score'] as num?)?.toInt() ?? 0,
      accuracy: (map['accuracy'] as num?)?.toInt() ?? 0,
      attempts: (map['attempts'] as num?)?.toInt() ?? 0,
      correctAnswers: (map['correctAnswers'] as num?)?.toInt() ?? 0,
      wrongAnswers: (map['wrongAnswers'] ?? map['mistakes'] as num?)?.toInt() ?? 0,
      difficulty: map['difficulty'] as String? ?? 'Level 1',
      completionTimeSeconds: (map['completionTimeSeconds'] as num?)?.toInt() ?? 0,
      avgResponseTimeSeconds: (map['responseTime'] ?? map['avgResponseTimeSeconds'] as num?)?.toDouble() ?? 0.0,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
          : (map['completionTime'] != null
              ? DateTime.tryParse(map['completionTime'] as String) ?? DateTime.now()
              : DateTime.now()),
      recommendation: map['recommendation'] as String? ?? '',
      syncStatus: map['syncStatus'] as String? ?? 'pending',
    );
  }

  GameResult copyWith({
    String? id,
    String? patientId,
    String? gameId,
    String? gameName,
    int? score,
    int? accuracy,
    int? attempts,
    int? correctAnswers,
    int? wrongAnswers,
    String? difficulty,
    int? completionTimeSeconds,
    double? avgResponseTimeSeconds,
    DateTime? timestamp,
    String? recommendation,
    String? syncStatus,
  }) {
    return GameResult(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      gameId: gameId ?? this.gameId,
      gameName: gameName ?? this.gameName,
      score: score ?? this.score,
      accuracy: accuracy ?? this.accuracy,
      attempts: attempts ?? this.attempts,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      wrongAnswers: wrongAnswers ?? this.wrongAnswers,
      difficulty: difficulty ?? this.difficulty,
      completionTimeSeconds: completionTimeSeconds ?? this.completionTimeSeconds,
      avgResponseTimeSeconds: avgResponseTimeSeconds ?? this.avgResponseTimeSeconds,
      timestamp: timestamp ?? this.timestamp,
      recommendation: recommendation ?? this.recommendation,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory GameResult.fromJson(String source) =>
      GameResult.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
