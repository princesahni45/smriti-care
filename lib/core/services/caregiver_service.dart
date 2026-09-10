// lib/core/services/caregiver_service.dart
//
// 100% Offline Local Storage & Data Service for the Caregiver Portal.
// Manages patient profile, reminders, emergency safety settings, and alerts.
// Integrates live with GameStorageService for patient cognitive game analytics.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/caregiver_models.dart';
import 'game_storage_service.dart';

class CaregiverService {
  CaregiverService._();
  static final CaregiverService instance = CaregiverService._();

  bool _isInitialized = false;

  late PatientProfile _patient;
  late CaregiverProfile _caregiver;
  final List<CaregiverReminder> _reminders = [];
  late EmergencyContact _emergencyContact;
  late HomeLocation _homeLocation;
  late EmergencyConfig _emergencyConfig;
  final List<CaregiverAlert> _alerts = [];

  final List<Map<String, dynamic>> _weeklyEngagement = [
    {'day': 'Mon', 'score': 58},
    {'day': 'Tue', 'score': 71},
    {'day': 'Wed', 'score': 64},
    {'day': 'Thu', 'score': 82},
    {'day': 'Fri', 'score': 76},
    {'day': 'Sat', 'score': 88},
    {'day': 'Sun', 'score': 72},
  ];

  Future<void> init() async {
    if (_isInitialized) return;
    _seedDefaults();

    try {
      final file = await _getStorageFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final decoded = jsonDecode(content) as Map<String, dynamic>;

          if (decoded['patient'] is Map) {
            _patient = PatientProfile.fromMap(decoded['patient'] as Map<String, dynamic>);
          }
          if (decoded['caregiver'] is Map) {
            _caregiver = CaregiverProfile.fromMap(decoded['caregiver'] as Map<String, dynamic>);
          }
          if (decoded['emergencyContact'] is Map) {
            _emergencyContact = EmergencyContact.fromMap(decoded['emergencyContact'] as Map<String, dynamic>);
          }
          if (decoded['homeLocation'] is Map) {
            _homeLocation = HomeLocation.fromMap(decoded['homeLocation'] as Map<String, dynamic>);
          }
          if (decoded['emergencyConfig'] is Map) {
            _emergencyConfig = EmergencyConfig.fromMap(decoded['emergencyConfig'] as Map<String, dynamic>);
          }
          if (decoded['reminders'] is List) {
            _reminders.clear();
            for (final item in decoded['reminders'] as List) {
              if (item is Map<String, dynamic>) {
                _reminders.add(CaregiverReminder.fromMap(item));
              }
            }
          }
          if (decoded['alerts'] is List) {
            _alerts.clear();
            for (final item in decoded['alerts'] as List) {
              if (item is Map<String, dynamic>) {
                _alerts.add(CaregiverAlert.fromMap(item));
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('CaregiverService init note: ');
    } finally {
      _isInitialized = true;
    }
  }

  void _seedDefaults() {
    _patient = PatientProfile(
      id: 'MC-2048',
      fullName: 'Mr. Ramesh Das',
      age: 72,
      location: 'Guwahati, Assam',
      bloodGroup: 'B+',
      physician: 'Dr. Ananya Bora',
      dementiaLevel: 'Moderate',
      primaryLanguage: 'English',
      avatarInitials: 'RD',
      lastUpdated: DateTime.now(),
    );

    _caregiver = const CaregiverProfile(
      name: 'Mohak Singh',
      email: 'singhmohak360@gmail.com',
      initials: 'MS',
      role: 'Caregiver',
      connectedPatientId: 'MC-2048',
    );

    _emergencyContact = EmergencyContact(
      name: 'Rahul Das',
      relationship: 'Son',
      phone: '+91 98765 43210',
      secondaryPhone: '+91 98765 01234',
      updatedAt: DateTime.now(),
    );

    _homeLocation = HomeLocation(
      address: 'Ambari, Guwahati, Assam',
      latitude: 26.1856,
      longitude: 91.7539,
      updatedAt: DateTime.now(),
    );

    _emergencyConfig = const EmergencyConfig(
      emergencyNumber: '112',
      label: 'National Emergency Response Support System',
      country: 'India',
    );

    if (_reminders.isEmpty) {
      _reminders.addAll([
        CaregiverReminder(
          id: 'rem-001',
          patientId: 'MC-2048',
          type: 'medication',
          title: 'Morning Medicine',
          message: 'Take with a glass of water after breakfast',
          scheduledTime: '08:00 AM',
          repeat: 'daily',
          enabled: true,
          status: 'acknowledged',
          acknowledgedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        CaregiverReminder(
          id: 'rem-002',
          patientId: 'MC-2048',
          type: 'hydration',
          title: 'Time for Water',
          message: 'Drink a glass of water to stay hydrated',
          scheduledTime: '11:00 AM',
          repeat: 'daily',
          enabled: true,
          status: 'acknowledged',
          acknowledgedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        const CaregiverReminder(
          id: 'rem-003',
          patientId: 'MC-2048',
          type: 'cognitive_activity',
          title: 'Brain Activity',
          message: 'Time for a gentle brain activity and memory game',
          scheduledTime: '02:00 PM',
          repeat: 'daily',
          enabled: true,
          status: 'upcoming',
        ),
        const CaregiverReminder(
          id: 'rem-004',
          patientId: 'MC-2048',
          type: 'appointment',
          title: 'Physiotherapy Check',
          message: 'Dr. Bora routine mobility checkup',
          scheduledTime: '04:30 PM',
          repeat: 'once',
          enabled: true,
          status: 'upcoming',
        ),
        const CaregiverReminder(
          id: 'rem-005',
          patientId: 'MC-2048',
          type: 'daily_routine',
          title: 'Evening Walk',
          message: 'Comfortable 15-minute garden walk',
          scheduledTime: '05:30 PM',
          repeat: 'daily',
          enabled: true,
          status: 'upcoming',
        ),
        const CaregiverReminder(
          id: 'rem-006',
          patientId: 'MC-2048',
          type: 'medication',
          title: 'Night Medicine',
          message: 'Take evening capsule before sleep',
          scheduledTime: '09:00 PM',
          repeat: 'daily',
          enabled: true,
          status: 'upcoming',
        ),
      ]);
    }

    if (_alerts.isEmpty) {
      _alerts.add(
        CaregiverAlert(
          id: 'alt-001',
          type: 'routine',
          title: 'Daily Check Normal',
          message: 'All scheduled morning activities completed comfortably.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
      );
    }
  }

  Future<File> _getStorageFile() async {
    Directory dir;
    try {
      dir = await getApplicationDocumentsDirectory();
    } catch (_) {
      dir = Directory.systemTemp;
    }
    return File('/smriti_care_caregiver.json');
  }

  Future<void> _persist() async {
    try {
      final file = await _getStorageFile();
      final data = {
        'patient': _patient.toMap(),
        'caregiver': _caregiver.toMap(),
        'emergencyContact': _emergencyContact.toMap(),
        'homeLocation': _homeLocation.toMap(),
        'emergencyConfig': _emergencyConfig.toMap(),
        'reminders': _reminders.map((r) => r.toMap()).toList(),
        'alerts': _alerts.map((a) => a.toMap()).toList(),
      };
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('CaregiverService persist note: ');
    }
  }

  // ── Patient & Caregiver Getters ─────────────────────────────────

  PatientProfile getPatientProfile() => _patient;
  CaregiverProfile getCaregiverProfile() => _caregiver;

  // ── Stats Calculation ───────────────────────────────────────────

  Map<String, String> getOverviewMetrics() {
    final liveScore = GameStorageService.instance.getTodayScore();
    final cognitiveScoreStr = liveScore > 0 ? ' / 100' : '72 / 100';

    final medReminders = _reminders.where((r) => r.type == 'medication').toList();
    final medDone = medReminders.where((r) => r.status == 'acknowledged').length;
    final medTotal = medReminders.isNotEmpty ? medReminders.length : 3;

    return {
      'activityTime': '42 min',
      'cognitiveScore': cognitiveScoreStr,
      'medication': ' of  taken',
      'nextAppointment': '12 Sep',
      'totalReminders': '',
      'completedReminders': '',
      'alertsCount': '',
    };
  }

  List<Map<String, dynamic>> getWeeklyEngagement() => List.unmodifiable(_weeklyEngagement);

  // ── Reminders Operations ────────────────────────────────────────

  List<CaregiverReminder> getReminders({String? status, String? type}) {
    var list = List<CaregiverReminder>.from(_reminders);
    if (status != null && status.isNotEmpty) {
      list = list.where((r) => r.status == status).toList();
    }
    if (type != null && type.isNotEmpty) {
      list = list.where((r) => r.type == type).toList();
    }
    return list;
  }

  Future<void> addReminder(CaregiverReminder reminder) async {
    await init();
    _reminders.add(reminder);
    await _persist();
  }

  Future<void> updateReminder(CaregiverReminder updated) async {
    await init();
    final idx = _reminders.indexWhere((r) => r.id == updated.id);
    if (idx != -1) {
      _reminders[idx] = updated;
      await _persist();
    }
  }

  Future<void> toggleReminder(String id) async {
    await init();
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx != -1) {
      final cur = _reminders[idx];
      _reminders[idx] = cur.copyWith(enabled: !cur.enabled);
      await _persist();
    }
  }

  Future<void> deleteReminder(String id) async {
    await init();
    _reminders.removeWhere((r) => r.id == id);
    await _persist();
  }

  // ── Safety & Emergency Operations ───────────────────────────────

  EmergencyContact getEmergencyContact() => _emergencyContact;

  Future<void> saveEmergencyContact(EmergencyContact contact) async {
    await init();
    _emergencyContact = contact;
    await _persist();
  }

  HomeLocation getHomeLocation() => _homeLocation;

  Future<void> saveHomeLocation(HomeLocation location) async {
    await init();
    _homeLocation = location;
    await _persist();
  }

  EmergencyConfig getEmergencyConfig() => _emergencyConfig;

  Future<void> saveEmergencyConfig(EmergencyConfig config) async {
    await init();
    _emergencyConfig = config;
    await _persist();
  }

  List<CaregiverAlert> getAlerts() => List.unmodifiable(_alerts);

  Future<void> dismissAlert(String id) async {
    await init();
    final idx = _alerts.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _alerts[idx] = _alerts[idx].copyWith(acknowledged: true);
      await _persist();
    }
  }

  // ── Recent Activity Feed ────────────────────────────────────────

  List<CaregiverActivityItem> getRecentActivities() {
    final items = <CaregiverActivityItem>[];

    // Read live completed games from GameStorageService
    final recentGames = GameStorageService.instance.getRecentResults(limit: 3);
    for (final g in recentGames) {
      items.add(
        CaregiverActivityItem(
          title: 'Completed ',
          subtitle: 'Score: % • Accuracy: % ()',
          timeAgo: 'Today',
          iconType: 'game',
          isCompleted: true,
        ),
      );
    }

    // Include completed & upcoming care tasks
    final completedReminders = _reminders.where((r) => r.status == 'acknowledged').take(2);
    for (final r in completedReminders) {
      items.add(
        CaregiverActivityItem(
          title: r.title,
          subtitle: 'Completed at ',
          timeAgo: 'Today',
          iconType: r.type,
          isCompleted: true,
        ),
      );
    }

    if (items.isEmpty) {
      // Friendly defaults matching web routine
      items.addAll([
        const CaregiverActivityItem(
          title: 'Morning medicine',
          subtitle: 'Completed at 8:00 AM',
          timeAgo: 'Today, 8:04 AM',
          iconType: 'medication',
          isCompleted: true,
        ),
        const CaregiverActivityItem(
          title: 'Memory Match Activity',
          subtitle: 'Score: 85% • Accuracy: 90% (Level 2)',
          timeAgo: 'Today, 10:30 AM',
          iconType: 'game',
          isCompleted: true,
        ),
        const CaregiverActivityItem(
          title: 'Time for Water',
          subtitle: 'Completed at 11:00 AM',
          timeAgo: 'Today, 11:01 AM',
          iconType: 'hydration',
          isCompleted: true,
        ),
      ]);
    }

    return items;
  }
}
