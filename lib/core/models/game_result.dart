// lib/core/models/game_result.dart
//
// Data model capturing the result of a completed cognitive activity.
// Strictly non-clinical: records game performance for elderly engagement tracking.

import 'dart:convert';

class GameResult {
  final String id;
  final String gameId;
  final String gameName;
  final int score; // 0 - 100
  final int accuracy; // 0 - 100
  final int attempts;
  final int correctAnswers;
  final int wrongAnswers;
  final String difficulty;
  final int completionTimeSeconds;
  final DateTime timestamp;
  final String recommendation;

  const GameResult({
    required this.id,
    required this.gameId,
    required this.gameName,
    required this.score,
    required this.accuracy,
    required this.attempts,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.difficulty,
    required this.completionTimeSeconds,
    required this.timestamp,
    required this.recommendation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gameId': gameId,
      'gameName': gameName,
      'score': score,
      'accuracy': accuracy,
      'attempts': attempts,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'difficulty': difficulty,
      'completionTimeSeconds': completionTimeSeconds,
      'timestamp': timestamp.toIso8601String(),
      'recommendation': recommendation,
    };
  }

  factory GameResult.fromMap(Map<String, dynamic> map) {
    return GameResult(
      id: map['id'] as String? ?? '',
      gameId: map['gameId'] as String? ?? 'unknown',
      gameName: map['gameName'] as String? ?? 'Activity',
      score: (map['score'] as num?)?.toInt() ?? 0,
      accuracy: (map['accuracy'] as num?)?.toInt() ?? 0,
      attempts: (map['attempts'] as num?)?.toInt() ?? 0,
      correctAnswers: (map['correctAnswers'] as num?)?.toInt() ?? 0,
      wrongAnswers: (map['wrongAnswers'] as num?)?.toInt() ?? 0,
      difficulty: map['difficulty'] as String? ?? 'Level 1',
      completionTimeSeconds:
          (map['completionTimeSeconds'] as num?)?.toInt() ?? 0,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      recommendation: map['recommendation'] as String? ?? '',
    );
  }

  String toJson() => jsonEncode(toMap());

  factory GameResult.fromJson(String source) =>
      GameResult.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
