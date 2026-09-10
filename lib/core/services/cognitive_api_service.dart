// lib/core/services/cognitive_api_service.dart
//
// Service interface for Cognitive Risk Telemetry & FastAPI backend synchronization.
// Handles synchronizing offline game performance and retrieving AI risk indicators.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/caregiver_models.dart';
import 'game_storage_service.dart';
import 'mri_screening_service.dart';

class SyncResult {
  final int syncedCount;
  final int failedCount;
  final bool isBackendOnline;
  final String statusMessage;

  const SyncResult({
    required this.syncedCount,
    required this.failedCount,
    required this.isBackendOnline,
    required this.statusMessage,
  });
}

class CognitiveApiService {
  CognitiveApiService._();
  static final CognitiveApiService instance = CognitiveApiService._();

  String get apiBaseUrl => MriScreeningService.instance.apiBaseUrl;

  bool get isConfigured => apiBaseUrl.isNotEmpty;

  int get pendingCount {
    final history = GameStorageService.instance.getHistory();
    return history.where((r) => r.syncStatus != 'synced').length;
  }

  /// Synchronize all offline pending game results with the FastAPI backend
  /// POST /api/v1/cognitive/telemetry/batch
  Future<SyncResult> syncPendingGameResults() async {
    final history = GameStorageService.instance.getHistory();
    final pending = history.where((r) => r.syncStatus != 'synced').toList();

    if (pending.isEmpty) {
      return const SyncResult(
        syncedCount: 0,
        failedCount: 0,
        isBackendOnline: true,
        statusMessage: 'All cognitive activities are already synchronized.',
      );
    }

    try {
      final uri = Uri.parse('$apiBaseUrl/api/v1/cognitive/telemetry/batch');
      final payload = {
        'items': pending.map((r) => r.toMap()).toList(),
      };

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Mark items as synced locally
        for (final r in pending) {
          final updated = r.copyWith(syncStatus: 'synced');
          await GameStorageService.instance.saveResult(updated);
        }

        return SyncResult(
          syncedCount: pending.length,
          failedCount: 0,
          isBackendOnline: true,
          statusMessage: 'Successfully synced ${pending.length} activity records to server.',
        );
      } else {
        return SyncResult(
          syncedCount: 0,
          failedCount: pending.length,
          isBackendOnline: true,
          statusMessage: 'Server returned HTTP ${response.statusCode}. Telemetry kept safe offline.',
        );
      }
    } catch (e) {
      debugPrint('CognitiveApiService sync notice: $e');
      return SyncResult(
        syncedCount: 0,
        failedCount: pending.length,
        isBackendOnline: false,
        statusMessage: 'FastAPI server offline ($apiBaseUrl). Results stored securely on device.',
      );
    }
  }

  /// Request AI-based cognitive risk assessment from backend model
  /// GET /api/v1/cognitive/risk-analysis?patient_id={id}
  Future<RiskAssessment?> fetchBackendRiskAssessment(String patientId) async {
    try {
      final uri = Uri.parse('$apiBaseUrl/api/v1/cognitive/risk-analysis?patient_id=$patientId');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        RiskLevel level = RiskLevel.low;
        final lvlStr = (data['level'] ?? '').toString().toLowerCase();
        if (lvlStr.contains('high')) {
          level = RiskLevel.high;
        } else if (lvlStr.contains('mod')) {
          level = RiskLevel.moderate;
        }

        return RiskAssessment(
          level: level,
          overallScore: (data['score'] as num?)?.toInt() ?? 75,
          label: data['label'] ?? 'Stable Cognitive Engagement',
          summary: data['summary'] ?? 'Consistent response timing across memory and attention tasks.',
          lastAssessed: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('CognitiveApiService assessment note: $e');
    }

    // When backend model is pending/offline, return null so UI clearly marks as pending
    return null;
  }
}
