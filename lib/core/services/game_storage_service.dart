// lib/core/services/game_storage_service.dart
//
// 100% Offline Local Storage Service for Cognitive Games.
// Stores game results, computes activity stats, tracks history,
// and implements offline adaptive difficulty.

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/game_result.dart';

class GameStorageService {
  GameStorageService._();
  static final GameStorageService instance = GameStorageService._();

  final List<GameResult> _history = [];
  final Map<String, int> _adaptiveLevels = {};
  bool _isInitialized = false;

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
      debugPrint('GameStorageService init note: $e');
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
      debugPrint('GameStorageService persist note: $e');
    }
  }

  /// Save a completed game result
  Future<void> saveResult(GameResult result) async {
    await init();
    _history.insert(0, result); // newest first

    // Calculate adaptive difficulty transition
    final currentLevel = _parseLevelNumber(result.difficulty);
    final recommendedLevel = calculateNextLevel(result.accuracy, currentLevel);
    _adaptiveLevels[result.gameId] = recommendedLevel;

    await _persist();
  }

  /// Retrieve full game history (newest first)
  List<GameResult> getHistory() {
    return List.unmodifiable(_history);
  }

  /// Retrieve limited recent results
  List<GameResult> getRecentResults({int limit = 10}) {
    return _history.take(limit).toList();
  }

  /// Total games completed across all activities
  int getTotalGamesCompleted() {
    return _history.length;
  }

  /// Today's aggregated score
  int getTodayScore() {
    final now = DateTime.now();
    final todayResults = _history.where((r) =>
        r.timestamp.year == now.year &&
        r.timestamp.month == now.month &&
        r.timestamp.day == now.day);
    if (todayResults.isEmpty) return 0;
    final total = todayResults.fold<int>(0, (sum, r) => sum + r.score);
    return (total / todayResults.length).round();
  }

  /// Current active streak in days
  int getCurrentStreakDays() {
    if (_history.isEmpty) return 0;

    final uniqueDays = <String>{};
    for (final r in _history) {
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
            checkDate
                .isAtSameMomentAs(DateTime(now.year, now.month, now.day))) {
          checkDate = checkDate.subtract(const Duration(days: 1));
          continue;
        }
        break;
      }
    }
    return streak;
  }

  // ── Adaptive Difficulty Logic (Step 13) ──────────────────────────

  /// Recommended level for a game (defaults to 1)
  int getRecommendedLevel(String gameId) {
    if (_adaptiveLevels.containsKey(gameId)) {
      return _adaptiveLevels[gameId]!;
    }
    // Infer from last game result if available
    final last = _history.where((r) => r.gameId == gameId).firstOrNull;
    if (last != null) {
      final lvl = _parseLevelNumber(last.difficulty);
      return calculateNextLevel(last.accuracy, lvl);
    }
    return 1;
  }

  /// Core Adaptive Rule:
  /// Accuracy >= 80% -> Increase difficulty (+1)
  /// Accuracy 50 - 79% -> Keep difficulty
  /// Accuracy < 50% -> Decrease difficulty (-1)
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
      return 'Great effort! Practicing Level $currentLevel again will build gentle confidence.';
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

  /// Manually update adaptive difficulty level for a game (1 to 3).
  Future<void> setAdaptiveLevel(String gameId, int level) async {
    await init();
    _adaptiveLevels[gameId] = level.clamp(1, 3);
    await _persist();
  }

  /// Clear history (useful for reset or testing)
  Future<void> clearAll() async {
    _history.clear();
    _adaptiveLevels.clear();
    await _persist();
  }
}
