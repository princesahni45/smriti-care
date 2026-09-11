// lib/core/services/game_storage_service.dart
//
// Offline-First Local Storage & Cloud Sync Service for Cognitive Games.
// Stores real game results, computes per-patient analytics, tracks history,
// manages adaptive difficulty per patient, and synchronizes to Cloud Firestore.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/game_result.dart';

class GameStorageService {
  GameStorageService._();

  static final GameStorageService instance = GameStorageService._();

  final List<GameResult> _history = [];
  final Map<String, int> _adaptiveLevels = {};

  bool _isInitialized = false;

  bool get _isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseFirestore? get _firestore {
    if (!_isFirebaseAvailable) {
      return null;
    }

    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Initialization and Local Storage
  // ---------------------------------------------------------------------------

  /// Loads local game history and adaptive difficulty settings.
  Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    try {
      final file = await _getStorageFile();

      if (await file.exists()) {
        final content = await file.readAsString();

        if (content.isNotEmpty) {
          final decoded = jsonDecode(content);

          if (decoded is Map<String, dynamic>) {
            final historyData = decoded['history'];

            if (historyData is List) {
              _history.clear();

              for (final item in historyData) {
                if (item is Map<String, dynamic>) {
                  try {
                    _history.add(GameResult.fromMap(item));
                  } catch (e) {
                    debugPrint(
                      'GameStorageService invalid history item: $e',
                    );
                  }
                }
              }
            }

            final adaptiveData = decoded['adaptiveLevels'];

            if (adaptiveData is Map) {
              _adaptiveLevels.clear();

              adaptiveData.forEach((key, value) {
                if (value is num) {
                  _adaptiveLevels[key.toString()] = value.toInt();
                }
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('GameStorageService init error: $e');
    } finally {
      _seedDefaultHistoryIfEmpty();
      _isInitialized = true;
    }
  }

  Future<File> _getStorageFile() async {
    Directory directory;

    try {
      directory = await getApplicationDocumentsDirectory();
    } catch (_) {
      directory = Directory.systemTemp;
    }

    return File(
      '${directory.path}/smriti_care_game_history.json',
    );
  }

  Future<void> _persist() async {
    try {
      final file = await _getStorageFile();

      final data = <String, dynamic>{
        'history': _history.map((result) => result.toMap()).toList(),
        'adaptiveLevels': _adaptiveLevels,
      };

      await file.writeAsString(
        jsonEncode(data),
        flush: true,
      );
    } catch (e) {
      debugPrint('GameStorageService persist error: $e');
    }
  }

  /// Adds sample history for the default demo patient.
  ///
  /// This is only used when there is no locally stored history.
  void _seedDefaultHistoryIfEmpty() {
    if (_history.isNotEmpty) {
      return;
    }

    final now = DateTime.now();

    _history.addAll([
      GameResult(
        id: 'seed_01',
        patientId: 'MC-2048',
        gameId: 'memory-match',
        gameName: 'Memory Match',
        score: 85,
        accuracy: 85,
        attempts: 12,
        correctAnswers: 6,
        wrongAnswers: 6,
        difficulty: 'Medium (6 Pairs)',
        completionTimeSeconds: 48,
        avgResponseTimeSeconds: 3.2,
        timestamp: now.subtract(const Duration(hours: 2)),
        recommendation: 'Wonderful job! Memory recall accuracy is high.',
        syncStatus: 'synced',
      ),
      GameResult(
        id: 'seed_02',
        patientId: 'MC-2048',
        gameId: 'word-recall',
        gameName: 'Word Recall',
        score: 88,
        accuracy: 88,
        attempts: 10,
        correctAnswers: 5,
        wrongAnswers: 1,
        difficulty: 'Standard (6 Words)',
        completionTimeSeconds: 52,
        avgResponseTimeSeconds: 3.8,
        timestamp: now.subtract(const Duration(hours: 5)),
        recommendation: 'Strong immediate recall; remembered 5 of 6 words.',
        syncStatus: 'synced',
      ),
      GameResult(
        id: 'seed_03',
        patientId: 'MC-2048',
        gameId: 'orientation',
        gameName: 'Day & Time Orientation',
        score: 92,
        accuracy: 92,
        attempts: 6,
        correctAnswers: 5,
        wrongAnswers: 1,
        difficulty: 'Level 1',
        completionTimeSeconds: 26,
        avgResponseTimeSeconds: 2.8,
        timestamp: now.subtract(const Duration(days: 1, hours: 3)),
        recommendation:
            'Clear temporal orientation with day and month recall.',
        syncStatus: 'synced',
      ),
    ]);
  }

  // ---------------------------------------------------------------------------
  // Saving and Cloud Synchronization
  // ---------------------------------------------------------------------------

  /// Saves a completed game result locally first.
  ///
  /// Firestore synchronization is then attempted in the background.
  Future<void> saveResult(GameResult result) async {
    await init();

    final effectivePatientId =
        result.patientId.isNotEmpty ? result.patientId : 'MC-2048';

    final resultToSave = result.copyWith(
      patientId: effectivePatientId,
    );

    // Prevent duplicate entries by ID.
    _history.removeWhere(
      (existingResult) => existingResult.id == resultToSave.id,
    );

    // Newest results are stored first.
    _history.insert(0, resultToSave);

    // Calculate and store the next adaptive difficulty level.
    final currentLevel = _parseLevelNumber(
      resultToSave.difficulty,
    );

    final recommendedLevel = calculateNextLevel(
      resultToSave.accuracy,
      currentLevel,
    );

    _adaptiveLevels[
      '${effectivePatientId}_${resultToSave.gameId}'
    ] = recommendedLevel;

    // Legacy fallback for older code.
    _adaptiveLevels[resultToSave.gameId] = recommendedLevel;

    await _persist();

    // Do not block the user interface while syncing.
    _syncResultToFirestore(resultToSave);
  }

  /// Synchronizes one game result to Cloud Firestore.
  Future<void> _syncResultToFirestore(GameResult result) async {
    final database = _firestore;

    if (database == null) {
      return;
    }

    try {
      await database
          .collection('patientGameResults')
          .doc(result.id)
          .set(result.toMap());

      final index = _history.indexWhere(
        (storedResult) => storedResult.id == result.id,
      );

      if (index != -1) {
        _history[index] = _history[index].copyWith(
          syncStatus: 'synced',
        );

        await _persist();
      }
    } catch (e) {
      debugPrint(
        '[GameStorageService] Firestore sync skipped/offline: $e',
      );
    }
  }

  /// Synchronizes all pending game results.
  Future<int> syncPendingResults() async {
    await init();

    final database = _firestore;

    if (database == null) {
      return 0;
    }

    int syncedCount = 0;

    for (int index = 0; index < _history.length; index++) {
      final result = _history[index];

      if (result.syncStatus != 'pending') {
        continue;
      }

      try {
        await database
            .collection('patientGameResults')
            .doc(result.id)
            .set(result.toMap());

        _history[index] = result.copyWith(
          syncStatus: 'synced',
        );

        syncedCount++;
      } catch (e) {
        debugPrint(
          '[GameStorageService] Sync pending error: $e',
        );

        // Stop when the network is unavailable.
        break;
      }
    }

    if (syncedCount > 0) {
      await _persist();
    }

    return syncedCount;
  }

  // ---------------------------------------------------------------------------
  // Per-Patient Queries and Analytics
  // ---------------------------------------------------------------------------

  /// Returns the complete history, optionally filtered by patient ID.
  ///
  /// Results are returned newest first.
  List<GameResult> getHistory({
    String? patientId,
  }) {
    if (patientId == null || patientId.isEmpty) {
      return List.unmodifiable(_history);
    }

    return List.unmodifiable(
      _history.where(
        (result) => result.patientId == patientId,
      ),
    );
  }

  /// Returns recent results for a patient.
  List<GameResult> getRecentResults({
    int limit = 10,
    String? patientId,
  }) {
    if (limit <= 0) {
      return <GameResult>[];
    }

    final history = getHistory(
      patientId: patientId,
    );

    return history.take(limit).toList();
  }

  /// Returns the total number of completed games.
  int getTotalGamesCompleted({
    String? patientId,
  }) {
    return getHistory(
      patientId: patientId,
    ).length;
  }

  /// Returns today's average score.
  int getTodayScore({
    String? patientId,
  }) {
    final now = DateTime.now();

    final todayResults = getHistory(
      patientId: patientId,
    ).where(
      (result) =>
          result.timestamp.year == now.year &&
          result.timestamp.month == now.month &&
          result.timestamp.day == now.day,
    );

    if (todayResults.isEmpty) {
      return 0;
    }

    final totalScore = todayResults.fold<int>(
      0,
      (sum, result) => sum + result.score,
    );

    return (totalScore / todayResults.length).round();
  }

  /// Returns the average accuracy percentage.
  double getAverageAccuracy({
    String? patientId,
  }) {
    final results = getHistory(
      patientId: patientId,
    );

    if (results.isEmpty) {
      return 0.0;
    }

    final totalAccuracy = results.fold<int>(
      0,
      (sum, result) => sum + result.accuracy,
    );

    return totalAccuracy / results.length;
  }

  /// Returns the average response time in seconds.
  double getAverageResponseTime({
    String? patientId,
  }) {
    final results = getHistory(
      patientId: patientId,
    );

    if (results.isEmpty) {
      return 0.0;
    }

    final totalResponseTime = results.fold<double>(
      0.0,
      (sum, result) => sum + result.responseTime,
    );

    return totalResponseTime / results.length;
  }

  /// Returns the current active streak in days.
  int getCurrentStreakDays({
    String? patientId,
  }) {
    final results = getHistory(
      patientId: patientId,
    );

    if (results.isEmpty) {
      return 0;
    }

    final uniqueDays = <String>{};

    for (final result in results) {
      final key =
          '${result.timestamp.year}-${result.timestamp.month}-${result.timestamp.day}';

      uniqueDays.add(key);
    }

    final now = DateTime.now();

    var streak = 0;
    var checkDate = DateTime(
      now.year,
      now.month,
      now.day,
    );

    while (true) {
      final key =
          '${checkDate.year}-${checkDate.month}-${checkDate.day}';

      if (uniqueDays.contains(key)) {
        streak++;

        checkDate = checkDate.subtract(
          const Duration(days: 1),
        );
      } else {
        // If the patient has not played today, allow yesterday
        // to start the current streak.
        if (streak == 0 &&
            checkDate.year == now.year &&
            checkDate.month == now.month &&
            checkDate.day == now.day) {
          checkDate = checkDate.subtract(
            const Duration(days: 1),
          );

          continue;
        }

        break;
      }
    }

    return streak;
  }

  /// Returns detailed performance statistics for one game.
  ({
    int gamesPlayed,
    double avgAccuracy,
    double avgResponseTime,
    int lastScore,
    String difficulty,
    DateTime? lastPlayed,
  }) getStatsForGame(
    String gameId, {
    String? patientId,
  }) {
    final gameResults = getHistory(
      patientId: patientId,
    )
        .where(
          (result) =>
              result.gameId == gameId ||
              result.gameId.replaceAll('-', '_') ==
                  gameId.replaceAll('-', '_'),
        )
        .toList();

    if (gameResults.isEmpty) {
      return (
        gamesPlayed: 0,
        avgAccuracy: 0.0,
        avgResponseTime: 0.0,
        lastScore: 0,
        difficulty: 'Level 1',
        lastPlayed: null,
      );
    }

    final totalAccuracy = gameResults.fold<int>(
      0,
      (sum, result) => sum + result.accuracy,
    );

    final totalResponseTime = gameResults.fold<double>(
      0.0,
      (sum, result) => sum + result.responseTime,
    );

    return (
      gamesPlayed: gameResults.length,
      avgAccuracy: totalAccuracy / gameResults.length,
      avgResponseTime: totalResponseTime / gameResults.length,
      lastScore: gameResults.first.score,
      difficulty: gameResults.first.difficulty,
      lastPlayed: gameResults.first.timestamp,
    );
  }

  // ---------------------------------------------------------------------------
  // Adaptive Difficulty
  // ---------------------------------------------------------------------------

  /// Returns the recommended level for a game.
  int getRecommendedLevel(
    String gameId, {
    String? patientId,
  }) {
    final key = patientId != null && patientId.isNotEmpty
        ? '${patientId}_$gameId'
        : gameId;

    if (_adaptiveLevels.containsKey(key)) {
      return _adaptiveLevels[key]!;
    }

    if (_adaptiveLevels.containsKey(gameId)) {
      return _adaptiveLevels[gameId]!;
    }

    final results = getHistory(
      patientId: patientId,
    ).where(
      (result) =>
          result.gameId == gameId ||
          result.gameId.replaceAll('-', '_') ==
              gameId.replaceAll('-', '_'),
    );

    final lastResult = results.isNotEmpty ? results.first : null;

    if (lastResult != null) {
      final currentLevel = _parseLevelNumber(
        lastResult.difficulty,
      );

      return calculateNextLevel(
        lastResult.accuracy,
        currentLevel,
      );
    }

    return 1;
  }

  /// Calculates the next level from the current accuracy.
  static int calculateNextLevel(
    int accuracy,
    int currentLevel,
  ) {
    if (accuracy >= 80) {
      return min(3, currentLevel + 1);
    }

    if (accuracy < 50) {
      return max(1, currentLevel - 1);
    }

    return currentLevel.clamp(1, 3);
  }

  /// Returns a gentle, non-clinical recommendation.
  String getAdaptiveRecommendation(
    String gameId,
    int accuracy,
    int currentLevel,
  ) {
    final nextLevel = calculateNextLevel(
      accuracy,
      currentLevel,
    );

    if (accuracy >= 80) {
      if (nextLevel > currentLevel) {
        return 'Wonderful job! You have unlocked Level $nextLevel.';
      }

      return 'Outstanding! You have mastered the highest level!';
    }

    if (accuracy >= 50) {
      return 'Great effort! Practicing Level $currentLevel again builds gentle confidence.';
    }

    if (nextLevel < currentLevel) {
      return 'A gentler pace is best. Level $nextLevel is recommended next.';
    }

    return 'Take your time. Every bit of daily practice helps!';
  }

  int _parseLevelNumber(String difficulty) {
    final lowerDifficulty = difficulty.toLowerCase();

    if (lowerDifficulty.contains('3') ||
        lowerDifficulty.contains('hard')) {
      return 3;
    }

    if (lowerDifficulty.contains('2') ||
        lowerDifficulty.contains('medium')) {
      return 2;
    }

    return 1;
  }

  /// Manually updates adaptive difficulty for a game.
  Future<void> setAdaptiveLevel(
    String gameId,
    int level, {
    String? patientId,
  }) async {
    await init();

    final safeLevel = level.clamp(1, 3);

    final key = patientId != null && patientId.isNotEmpty
        ? '${patientId}_$gameId'
        : gameId;

    _adaptiveLevels[key] = safeLevel;

    // Maintain the legacy game-level value as well.
    _adaptiveLevels[gameId] = safeLevel;

    await _persist();
  }

  // ---------------------------------------------------------------------------
  // History Management
  // ---------------------------------------------------------------------------

  /// Clears all local game history and adaptive difficulty data.
  Future<void> clearAll() async {
    _history.clear();
    _adaptiveLevels.clear();

    await _persist();
  }
}
