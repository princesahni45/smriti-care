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
    if (!_isFirebaseAvailable) return null;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Ensure storage file is loaded on startup
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final file = await _getStorageFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final decoded = jsonDecode(content) as Map<String, dynamic>;

          if (decoded['history'] is List) {
            _history.clear();
            for (final item in decoded['history'] as List) {
              if (item is Map<String, dynamic>) {
                _history.add(GameResult.fromMap(item));
              }
            }
          }

          if (decoded['adaptiveLevels'] is Map) {
            _adaptiveLevels.clear();
            (decoded['adaptiveLevels'] as Map<String, dynamic>).forEach((k, v) {
              if (v is num) _adaptiveLevels[k] = v.toInt();
            });
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
    Directory dir;
    try {
      dir = await getApplicationDocumentsDirectory();
    } catch (_) {
      dir = Directory.systemTemp;
    }
    return File('${dir.path}/smriti_care_game_history.json');
  }

  Future<void> _persist() async {
    try {
      final file = await _getStorageFile();
      final data = {
        'history': _history.map((r) => r.toMap()).toList(),
        'adaptiveLevels': _adaptiveLevels,
      };
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('GameStorageService persist error: $e');
    }
  }

  /// Initial seed for default patient MC-2048 to demonstrate real historical trend
  void _seedDefaultHistoryIfEmpty() {
    if (_history.isEmpty) {
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
          recommendation: 'Clear temporal orientation with day and month recall.',
          syncStatus: 'synced',
        ),
      ]);
    }
  }

  // ── Saving & Cloud Sync ───────────────────────────────────────────────────

  /// Save a completed game result (offline-first, triggers Firestore sync if online)
  Future<void> saveResult(GameResult result) async {
    await init();

    final effectivePatientId =
        result.patientId.isNotEmpty ? result.patientId : 'MC-2048';
    final toSave = result.copyWith(patientId: effectivePatientId);

    // Prevent duplicate entries by id
    _history.removeWhere((r) => r.id == toSave.id);
    _history.insert(0, toSave); // newest first

    // Calculate adaptive difficulty transition
    final currentLevel = _parseLevelNumber(toSave.difficulty);
    final recommendedLevel = calculateNextLevel(toSave.accuracy, currentLevel);
    _adaptiveLevels['${effectivePatientId}_${toSave.gameId}'] = recommendedLevel;
    _adaptiveLevels[toSave.gameId] = recommendedLevel; // legacy fallback

    await _persist();

    // Trigger cloud synchronization in background
    _syncResultToFirestore(toSave);
  }

  /// Syncs an individual game result to Firestore
  Future<void> _syncResultToFirestore(GameResult result) async {
    final db = _firestore;
    if (db == null) return;

    try {
      await db.collection('patientGameResults').doc(result.id).set(result.toMap());
      // Mark as synced locally
      final index = _history.indexWhere((r) => r.id == result.id);
      if (index != -1) {
        _history[index] = _history[index].copyWith(syncStatus: 'synced');
        await _persist();
      }
    } catch (e) {
      debugPrint('[GameStorageService] Firestore sync skipped/offline: $e');
    }
  }

  /// Synchronize all pending game results when online connectivity is restored
  Future<int> syncPendingResults() async {
    await init();
    final db = _firestore;
    if (db == null) return 0;

    int syncedCount = 0;
    for (int i = 0; i < _history.length; i++) {
      if (_history[i].syncStatus == 'pending') {
        try {
          await db
              .collection('patientGameResults')
              .doc(_history[i].id)
              .set(_history[i].toMap());
          _history[i] = _history[i].copyWith(syncStatus: 'synced');
          syncedCount++;
        } catch (e) {
          debugPrint('[GameStorageService] Sync pending error: $e');
          break; // Stop loop if network unavailable
        }
      }
    }

    if (syncedCount > 0) {
      await _persist();
    }
    return syncedCount;
  }

  // ── Per-Patient Queries & Analytics ───────────────────────────────────────

  /// Retrieve full game history, optionally filtered by patientId (newest first)
  List<GameResult> getHistory({String? patientId}) {
    if (patientId == null || patientId.isEmpty) {
      return List.unmodifiable(_history);
    }
    return List.unmodifiable(_history.where((r) => r.patientId == patientId));
  }

  /// Retrieve limited recent results for a given patient
  List<GameResult> getRecentResults({int limit = 10, String? patientId}) {
    final list = getHistory(patientId: patientId);
    return list.take(limit).toList();
  }

  /// Total games completed for a given patient
  int getTotalGamesCompleted({String? patientId}) {
    return getHistory(patientId: patientId).length;
  }

  /// Today's aggregated score for a given patient
  int getTodayScore({String? patientId}) {
    final now = DateTime.now();
    final todayResults = getHistory(patientId: patientId).where((r) =>
        r.timestamp.year == now.year &&
        r.timestamp.month == now.month &&
        r.timestamp.day == now.day);
    if (todayResults.isEmpty) return 0;
    final total = todayResults.fold<int>(0, (acc, r) => acc + r.score);
    return (total / todayResults.length).round();
  }

  /// Average accuracy percentage for a given patient
  double getAverageAccuracy({String? patientId}) {
    final list = getHistory(patientId: patientId);
    if (list.isEmpty) return 0.0;
    final totalAcc = list.fold<int>(0, (acc, r) => acc + r.accuracy);
    return totalAcc / list.length;
  }

  /// Average response time in seconds for a given patient
  double getAverageResponseTime({String? patientId}) {
    final list = getHistory(patientId: patientId);
    if (list.isEmpty) return 0.0;
    final totalTime = list.fold<double>(0.0, (acc, r) => acc + r.responseTime);
    return totalTime / list.length;
  }

  /// Current active streak in days for a given patient
  int getCurrentStreakDays({String? patientId}) {
    final list = getHistory(patientId: patientId);
    if (list.isEmpty) return 0;

    final uniqueDays = <String>{};
    for (final r in list) {
      final key = '${r.timestamp.year}-${r.timestamp.month}-${r.timestamp.day}';
      uniqueDays.add(key);
    }

    final now = DateTime.now();
    var streak = 0;
    var checkDate = DateTime(now.year, now.month, now.day);

    while (true) {
      final key = '${checkDate.year}-${checkDate.month}-${checkDate.day}';
      if (uniqueDays.contains(key)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        // Allow streak to count if today has not been played yet but yesterday was
        if (streak == 0 &&
            checkDate.isAtSameMomentAs(DateTime(now.year, now.month, now.day))) {
          checkDate = checkDate.subtract(const Duration(days: 1));
          continue;
        }
        break;
      }
    }
    return streak;
  }

  /// Detailed performance stats for a specific game
  ({
    int gamesPlayed,
    double avgAccuracy,
    double avgResponseTime,
    int lastScore,
    String difficulty,
    DateTime? lastPlayed
  }) getStatsForGame(String gameId, {String? patientId}) {
    final gameResults = getHistory(patientId: patientId)
        .where((r) => r.gameId == gameId || r.gameId.replaceAll('-', '_') == gameId.replaceAll('-', '_'))
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

    final totalAcc = gameResults.fold<int>(0, (acc, r) => acc + r.accuracy);
    final totalTime = gameResults.fold<double>(0.0, (acc, r) => acc + r.responseTime);

    return (
      gamesPlayed: gameResults.length,
      avgAccuracy: totalAcc / gameResults.length,
      avgResponseTime: totalTime / gameResults.length,
      lastScore: gameResults.first.score,
      difficulty: gameResults.first.difficulty,
      lastPlayed: gameResults.first.timestamp,
    );
  }

  // ── Adaptive Difficulty Logic ─────────────────────────────────────────────

  /// Recommended level for a game (defaults to 1)
  int getRecommendedLevel(String gameId, {String? patientId}) {
    final key = patientId != null ? '${patientId}_$gameId' : gameId;
    if (_adaptiveLevels.containsKey(key)) {
      return _adaptiveLevels[key]!;
    }
    if (_adaptiveLevels.containsKey(gameId)) {
      return _adaptiveLevels[gameId]!;
    }

    // Infer from last game result if available
    final last = getHistory(patientId: patientId)
        .where((r) => r.gameId == gameId)
        .firstOrNull;
    if (last != null) {
      final lvl = _parseLevelNumber(last.difficulty);
      return calculateNextLevel(last.accuracy, lvl);
    }
    return 1;
  }

  static int calculateNextLevel(int accuracy, int currentLevel) {
    if (accuracy >= 80) {
      return min(3, currentLevel + 1);
    } else if (accuracy < 50) {
      return max(1, currentLevel - 1);
    } else {
      return currentLevel;
    }
  }

  /// Gentle, non-clinical encouragement string based on score
  String getAdaptiveRecommendation(
      String gameId, int accuracy, int currentLevel) {
    final nextLevel = calculateNextLevel(accuracy, currentLevel);
    if (accuracy >= 80) {
      if (nextLevel > currentLevel) {
        return 'Wonderful job! You have unlocked Level $nextLevel.';
      }
      return 'Outstanding! You have mastered the highest level!';
    } else if (accuracy >= 50) {
      return 'Great effort! Practicing Level $currentLevel again builds gentle confidence.';
    } else {
      if (nextLevel < currentLevel) {
        return 'A gentler pace is best. Level $nextLevel is recommended next.';
      }
      return 'Take your time. Every bit of daily practice helps!';
    }
  }

  int _parseLevelNumber(String difficulty) {
    final lower = difficulty.toLowerCase();
    if (lower.contains('3') || lower.contains('hard')) return 3;
    if (lower.contains('2') || lower.contains('medium')) return 2;
    return 1;
  }

  Future<void> clearAll() async {
    _history.clear();
    _adaptiveLevels.clear();
    await _persist();
  }
}
