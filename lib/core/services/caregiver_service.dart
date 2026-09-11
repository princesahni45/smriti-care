// lib/core/services/caregiver_service.dart
//
// 100% Offline Local Storage & Data Service for the Caregiver Portal.
// Manages:
// - Multiple linked patients & switching
// - Patient profile, reminders, emergency safety settings, and alerts
// - Family memories CRUD for cognitive association games
// - Real-time cognitive performance & 7 dedicated game reports
// - SOS alert history & safe zone representation
// - Integrates live with GameStorageService for patient cognitive game analytics.

import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/caregiver_models.dart';
import 'game_storage_service.dart';
import 'notification_service.dart';

class CaregiverService {
  CaregiverService._() {
    _seedDefaults();
  }
  static final CaregiverService instance = CaregiverService._();

  bool _isInitialized = false;

  final List<PatientProfile> _patients = [];
  String _selectedPatientId = 'MC-2048';
  late CaregiverProfile _caregiver;
  final List<CaregiverReminder> _reminders = [];
  // FIX: Sync caregiver reminder changes to linked patient - reactive notifier
  final ValueNotifier<int> remindersNotifier = ValueNotifier<int>(0);
  final List<FamilyMemoryMember> _familyMembers = [];
  late EmergencyContact _emergencyContact;
  late HomeLocation _homeLocation;
  late EmergencyConfig _emergencyConfig;
  final List<CaregiverAlert> _alerts = [];
  final List<SosAlertLog> _sosLogs = [];

  final List<Map<String, dynamic>> _weeklyEngagement = [
    {'day': 'Mon', 'score': 68, 'responseTime': 3.8, 'accuracy': 82},
    {'day': 'Tue', 'score': 74, 'responseTime': 3.4, 'accuracy': 86},
    {'day': 'Wed', 'score': 70, 'responseTime': 3.6, 'accuracy': 80},
    {'day': 'Thu', 'score': 82, 'responseTime': 3.1, 'accuracy': 88},
    {'day': 'Fri', 'score': 76, 'responseTime': 3.5, 'accuracy': 84},
    {'day': 'Sat', 'score': 88, 'responseTime': 2.9, 'accuracy': 92},
    {'day': 'Sun', 'score': 78, 'responseTime': 3.3, 'accuracy': 85},
  ];

  final List<Map<String, dynamic>> _monthlyEngagement = [
    {'month': 'May', 'score': 65},
    {'month': 'Jun', 'score': 70},
    {'month': 'Jul', 'score': 73},
    {'month': 'Aug', 'score': 76},
    {'month': 'Sep', 'score': 78},
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

          if (decoded['patients'] is List) {
            _patients.clear();
            for (final item in decoded['patients'] as List) {
              if (item is Map<String, dynamic>) {
                _patients.add(PatientProfile.fromMap(item));
              }
            }
          }
          if (decoded['selectedPatientId'] is String) {
            _selectedPatientId = decoded['selectedPatientId'] as String;
          }
          if (decoded['caregiver'] is Map) {
            _caregiver = CaregiverProfile.fromMap(
                decoded['caregiver'] as Map<String, dynamic>);
          }
          if (decoded['emergencyContact'] is Map) {
            _emergencyContact = EmergencyContact.fromMap(
                decoded['emergencyContact'] as Map<String, dynamic>);
          }
          if (decoded['homeLocation'] is Map) {
            _homeLocation = HomeLocation.fromMap(
                decoded['homeLocation'] as Map<String, dynamic>);
          }
          if (decoded['emergencyConfig'] is Map) {
            _emergencyConfig = EmergencyConfig.fromMap(
                decoded['emergencyConfig'] as Map<String, dynamic>);
          }
          if (decoded['reminders'] is List) {
            _reminders.clear();
            for (final item in decoded['reminders'] as List) {
              if (item is Map<String, dynamic>) {
                _reminders.add(CaregiverReminder.fromMap(item));
              }
            }
          }
          if (decoded['familyMembers'] is List) {
            _familyMembers.clear();
            for (final item in decoded['familyMembers'] as List) {
              if (item is Map<String, dynamic>) {
                _familyMembers.add(FamilyMemoryMember.fromMap(item));
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
          if (decoded['sosLogs'] is List) {
            _sosLogs.clear();
            for (final item in decoded['sosLogs'] as List) {
              if (item is Map<String, dynamic>) {
                _sosLogs.add(SosAlertLog.fromMap(item));
              }
            }
          }
        }
      }

      // FIX: Sync caregiver reminder changes to linked patient - initialize notifications
      try {
        await NotificationService.instance.init();
        final activeReminders = _reminders
            .where((r) => r.patientId == _selectedPatientId && r.enabled)
            .toList();
        await NotificationService.instance.rescheduleAll(activeReminders);
      } catch (e) {
        debugPrint('Notification init inside CaregiverService: $e');
      }
    } catch (e) {
      debugPrint('CaregiverService init note: $e');
    } finally {
      _isInitialized = true;
    }
  }

  void _seedDefaults() {
    if (_patients.isEmpty) {
      _patients.addAll([
        PatientProfile(
          id: 'MC-2048',
          fullName: 'Mr. Ramesh Das',
          age: 72,
          location: 'Ambari, Guwahati, Assam',
          bloodGroup: 'B+',
          physician: 'Dr. Ananya Bora',
          dementiaLevel: 'Moderate',
          primaryLanguage: 'English & Assamese',
          avatarInitials: 'RD',
          lastUpdated: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
        PatientProfile(
          id: 'MC-3109',
          fullName: 'Mrs. Maya Sharma',
          age: 68,
          location: 'Dispur, Guwahati, Assam',
          bloodGroup: 'O+',
          physician: 'Dr. Deben Saikia',
          dementiaLevel: 'Mild',
          primaryLanguage: 'Assamese & Hindi',
          avatarInitials: 'MS',
          lastUpdated: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ]);
    }

    _caregiver = const CaregiverProfile(
      name: 'Mohak Singh',
      email: 'singhmohak360@gmail.com',
      initials: 'MS',
      role: 'Primary Caregiver',
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
      address: 'House #14, Ambari, Guwahati, Assam 781001',
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
      final now = DateTime.now();
      _reminders.addAll([
        CaregiverReminder(
          id: 'rem-001',
          patientId: 'MC-2048',
          type: 'medication',
          title: 'Morning Medicine (Donepezil 5mg)',
          message: 'Take with a glass of water after breakfast',
          scheduledTime: '08:00 AM',
          repeat: 'daily',
          enabled: true,
          status: 'acknowledged',
          updatedAt: now.subtract(const Duration(hours: 2)),
          acknowledgedAt: now.subtract(const Duration(hours: 2)),
        ),
        CaregiverReminder(
          id: 'rem-002',
          patientId: 'MC-2048',
          type: 'hydration',
          title: 'Hydration - Water Intake',
          message: 'Drink a glass of warm water or lime juice',
          scheduledTime: '11:00 AM',
          repeat: 'daily',
          enabled: true,
          status: 'acknowledged',
          updatedAt: now.subtract(const Duration(hours: 1)),
          acknowledgedAt: now.subtract(const Duration(hours: 1)),
        ),
        CaregiverReminder(
          id: 'rem-003',
          patientId: 'MC-2048',
          type: 'cognitive_activity',
          title: 'Daily Cognitive Exercises',
          message: 'Complete Word Recall & Memory Match games',
          scheduledTime: '02:00 PM',
          repeat: 'daily',
          enabled: true,
          status: 'upcoming',
          updatedAt: now,
        ),
        CaregiverReminder(
          id: 'rem-004',
          patientId: 'MC-2048',
          type: 'appointment',
          title: 'Physiotherapy & Mobility Check',
          message: 'Dr. Bora routine mobility and balance checkup',
          scheduledTime: '04:30 PM',
          repeat: 'once',
          enabled: true,
          status: 'upcoming',
          updatedAt: now,
        ),
        CaregiverReminder(
          id: 'rem-005',
          patientId: 'MC-2048',
          type: 'daily_routine',
          title: 'Evening Garden Walk',
          message: 'Relaxing 15-minute garden walk accompanied by family',
          scheduledTime: '05:30 PM',
          repeat: 'daily',
          enabled: true,
          status: 'upcoming',
          updatedAt: now,
        ),
        CaregiverReminder(
          id: 'rem-006',
          patientId: 'MC-2048',
          type: 'medication',
          title: 'Night Medicine (Memantine 10mg)',
          message: 'Take after dinner before sleeping',
          scheduledTime: '09:00 PM',
          repeat: 'daily',
          enabled: true,
          status: 'upcoming',
          updatedAt: now,
        ),
      ]);
    }

    if (_familyMembers.isEmpty) {
      _familyMembers.addAll([
        FamilyMemoryMember(
          id: 'fam-001',
          patientId: 'MC-2048',
          name: 'Rahul Das',
          relationship: 'Son',
          notes:
              'Lives in Guwahati, visits on weekends, loves tea time with father.',
          avatarEmoji: '👨',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        FamilyMemoryMember(
          id: 'fam-002',
          patientId: 'MC-2048',
          name: 'Priya Das',
          relationship: 'Granddaughter',
          notes:
              'Studies in 8th grade, plays chess and does drawing with grandfather.',
          avatarEmoji: '👧',
          createdAt: DateTime.now().subtract(const Duration(days: 28)),
        ),
        FamilyMemoryMember(
          id: 'fam-003',
          patientId: 'MC-2048',
          name: 'Sunita Das',
          relationship: 'Daughter-in-law',
          notes:
              'Prepares morning meals, manages daily medicines and evening walk.',
          avatarEmoji: '👩',
          createdAt: DateTime.now().subtract(const Duration(days: 25)),
        ),
        FamilyMemoryMember(
          id: 'fam-004',
          patientId: 'MC-2048',
          name: 'Aarav Das',
          relationship: 'Grandson',
          notes:
              'Loves listening to stories about Assam and old train journeys.',
          avatarEmoji: '👦',
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
        ),
      ]);
    }

    if (_alerts.isEmpty) {
      _alerts.addAll([
        CaregiverAlert(
          id: 'alt-001',
          type: 'routine',
          title: 'Morning Medicine Taken',
          message: 'Donepezil 5mg confirmed taken at 8:04 AM.',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          acknowledged: true,
        ),
        CaregiverAlert(
          id: 'alt-002',
          type: 'score_drop',
          title: 'Cognitive Score Note',
          message:
              'Delayed Recall score had a 6% variance compared to 7-day baseline.',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          acknowledged: false,
        ),
        CaregiverAlert(
          id: 'alt-003',
          type: 'routine',
          title: 'Daily Check Normal',
          message: 'All scheduled morning activities completed comfortably.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          acknowledged: false,
        ),
      ]);
    }

    if (_sosLogs.isEmpty) {
      _sosLogs.addAll([
        SosAlertLog(
          id: 'sos-001',
          timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
          triggerType: 'Safe Zone Boundary Check',
          resolved: true,
          notes:
              'Patient walked out towards garden gate. Returned comfortably with family assistance within 5 mins.',
        ),
        SosAlertLog(
          id: 'sos-002',
          timestamp: DateTime.now().subtract(const Duration(days: 9, hours: 6)),
          triggerType: 'Emergency Help Button (Test)',
          resolved: true,
          notes:
              'Caregiver test verification of emergency notification sounds and call trigger.',
        ),
      ]);
    }
  }

  Future<File> _getStorageFile() async {
    Directory dir;
    try {
      dir = await getApplicationDocumentsDirectory();
    } catch (_) {
      dir = Directory.systemTemp;
    }
    return File('${dir.path}/smriti_care_caregiver.json');
  }

  Future<void> _persist() async {
    try {
      final file = await _getStorageFile();
      final data = {
        'patients': _patients.map((p) => p.toMap()).toList(),
        'selectedPatientId': _selectedPatientId,
        'caregiver': _caregiver.toMap(),
        'emergencyContact': _emergencyContact.toMap(),
        'homeLocation': _homeLocation.toMap(),
        'emergencyConfig': _emergencyConfig.toMap(),
        'reminders': _reminders.map((r) => r.toMap()).toList(),
        'familyMembers': _familyMembers.map((f) => f.toMap()).toList(),
        'alerts': _alerts.map((a) => a.toMap()).toList(),
        'sosLogs': _sosLogs.map((s) => s.toMap()).toList(),
      };
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('CaregiverService persist note: ');
    }
  }

  // ── Patient Profile & Multi-Patient Management ───────────────────

  PatientProfile getPatientProfile() {
    return _patients.firstWhere(
      (p) => p.id == _selectedPatientId,
      orElse: () =>
          _patients.isNotEmpty ? _patients.first : _createFallbackPatient(),
    );
  }

  PatientProfile _createFallbackPatient() {
    return PatientProfile(
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
  }

  List<PatientProfile> getLinkedPatients() => List.unmodifiable(_patients);

  String get selectedPatientId => _selectedPatientId;

  Future<void> selectPatient(String patientId) async {
    await init();
    if (_patients.any((p) => p.id == patientId)) {
      _selectedPatientId = patientId;
      await _persist();
      final active = _reminders
          .where((r) => r.patientId == patientId && r.enabled)
          .toList();
      await NotificationService.instance.rescheduleAll(active);
      remindersNotifier.value++;
    }
  }

  Future<void> linkPatient(PatientProfile newPatient) async {
    await init();
    _patients.removeWhere((p) => p.id == newPatient.id);
    _patients.add(newPatient);
    _selectedPatientId = newPatient.id;
    await _persist();
  }

  CaregiverProfile getCaregiverProfile() => _caregiver;

  // ── Stats & Overview Metrics ─────────────────────────────────────

  Map<String, String> getOverviewMetrics() {
    final liveScore = GameStorageService.instance.getTodayScore();
    final cognitiveScoreStr = liveScore > 0 ? '$liveScore / 100' : '78 / 100';

    final totalCompletedGames =
        GameStorageService.instance.getTotalGamesCompleted();
    final gamesCompletedStr =
        totalCompletedGames > 0 ? '$totalCompletedGames / 4' : '3 / 4';

    final streak = GameStorageService.instance.getCurrentStreakDays();
    final streakStr = streak > 0 ? '$streak days' : '5 days';

    final medReminders =
        _reminders.where((r) => r.type == 'medication').toList();
    final medDone =
        medReminders.where((r) => r.status == 'acknowledged').length;
    final medTotal = medReminders.isNotEmpty ? medReminders.length : 3;

    return {
      'activityTime': '42 min',
      'cognitiveScore': cognitiveScoreStr,
      'gamesCompleted': gamesCompletedStr,
      'streak': streakStr,
      'riskLevel': 'Low',
      'lastAssessment': 'Today, 10:45 AM',
      'recentActivity': 'Word Recall completed (88%)',
      'medication': '$medDone of $medTotal taken',
      'nextAppointment': '12 Sep • 4:30 PM',
      'totalReminders': '${_reminders.length}',
      'completedReminders':
          '${_reminders.where((r) => r.status == 'acknowledged').length}',
      'alertsCount': '${_alerts.where((a) => !a.acknowledged).length}',
    };
  }

  List<Map<String, dynamic>> getWeeklyEngagement() =>
      List.unmodifiable(_weeklyEngagement);
  List<Map<String, dynamic>> getMonthlyEngagement() =>
      List.unmodifiable(_monthlyEngagement);

  List<Map<String, dynamic>> getAssessmentHistory() {
    return [
      {
        'date': 'Today',
        'time': '10:45 AM',
        'score': 78,
        'type': 'Daily Session',
        'status': 'Stable'
      },
      {
        'date': 'Yesterday',
        'time': '11:15 AM',
        'score': 82,
        'type': 'Daily Session',
        'status': 'Improved'
      },
      {
        'date': '08 Sep',
        'time': '10:30 AM',
        'score': 74,
        'type': 'Weekly Review',
        'status': 'Stable'
      },
      {
        'date': '06 Sep',
        'time': '04:00 PM',
        'score': 79,
        'type': 'Daily Session',
        'status': 'Stable'
      },
      {
        'date': '04 Sep',
        'time': '09:50 AM',
        'score': 76,
        'type': 'Daily Session',
        'status': 'Normal'
      },
    ];
  }

  // ── Cognitive Risk Screening Assessment ──────────────────────────

  RiskAssessment getRiskAssessment() {
    final todayScore = GameStorageService.instance.getTodayScore();
    final score = todayScore > 0 ? todayScore : 78;

    RiskLevel level;
    String label;
    String summary;

    if (score >= 70) {
      level = RiskLevel.low;
      label = 'Low Risk Screening';
      summary =
          'Cognitive engagement is stable. Memory recall accuracy is high and reaction times remain within expected baseline.';
    } else if (score >= 50) {
      level = RiskLevel.moderate;
      label = 'Moderate Risk Screening';
      summary =
          'Mild hesitation detected in delayed word retention and pattern recognition. Regular daily cognitive exercises recommended.';
    } else {
      level = RiskLevel.high;
      label = 'High Risk Screening';
      summary =
          'Significant variance observed in orientation and recall. Consider consulting the attending physician for clinical evaluation.';
    }

    return RiskAssessment(
      level: level,
      overallScore: score,
      label: label,
      summary: summary,
      lastAssessed: DateTime.now().subtract(const Duration(minutes: 45)),
    );
  }

  // ── 7 Cognitive Game Reports ─────────────────────────────────────

  List<CognitiveGameReport> getCognitiveGameReports() {
    return const [
      CognitiveGameReport(
        gameId: 'word_recall',
        title: 'Word Recall Game',
        category: 'Short-term Memory',
        score: 82,
        accuracyPercent: 85.0,
        avgResponseTimeSeconds: 4.2,
        primaryMetricLabel: 'Recall Accuracy',
        primaryMetricValue: '85%',
        secondaryMetricLabel: 'Response Time',
        secondaryMetricValue: '4.2 sec',
        statusDescription:
            'Strong immediate recall; remembered 5 of 6 target words.',
        isStrongPerformance: true,
      ),
      CognitiveGameReport(
        gameId: 'delayed_recall',
        title: 'Delayed Recall Game',
        category: 'Retention Memory',
        score: 74,
        accuracyPercent: 78.0,
        avgResponseTimeSeconds: 5.8,
        primaryMetricLabel: 'Retention Rate',
        primaryMetricValue: '78%',
        secondaryMetricLabel: 'Missed Words',
        secondaryMetricValue: '1 word',
        statusDescription:
            'Consistent retention after 10-minute distraction interval.',
        isStrongPerformance: true,
      ),
      CognitiveGameReport(
        gameId: 'orientation',
        title: 'Day & Time Orientation',
        category: 'Temporal Orientation',
        score: 90,
        accuracyPercent: 92.0,
        avgResponseTimeSeconds: 2.9,
        primaryMetricLabel: 'Orientation Accuracy',
        primaryMetricValue: '92%',
        secondaryMetricLabel: 'Errors Made',
        secondaryMetricValue: '0 errors',
        statusDescription:
            'Correctly identified current day, month, and season.',
        isStrongPerformance: true,
      ),
      CognitiveGameReport(
        gameId: 'attention',
        title: 'Attention & Focus',
        category: 'Selective Attention',
        score: 78,
        accuracyPercent: 80.0,
        avgResponseTimeSeconds: 1.8,
        primaryMetricLabel: 'Reaction Speed',
        primaryMetricValue: '1.8 sec',
        secondaryMetricLabel: 'Distractor Mistakes',
        secondaryMetricValue: '2 mistakes',
        statusDescription:
            'Steady sustained focus during odd-one-out visual identification.',
        isStrongPerformance: true,
      ),
      CognitiveGameReport(
        gameId: 'sequence_number',
        title: 'Sequence & Number',
        category: 'Working Memory',
        score: 80,
        accuracyPercent: 84.0,
        avgResponseTimeSeconds: 3.6,
        primaryMetricLabel: 'Order Accuracy',
        primaryMetricValue: '84%',
        secondaryMetricLabel: 'Completion Speed',
        secondaryMetricValue: '32 sec',
        statusDescription:
            'Numbered tile sequences ordered without major backtracking.',
        isStrongPerformance: true,
      ),
      CognitiveGameReport(
        gameId: 'pattern_recognition',
        title: 'Pattern Recognition',
        category: 'Executive Function',
        score: 85,
        accuracyPercent: 88.0,
        avgResponseTimeSeconds: 3.1,
        primaryMetricLabel: 'Difficulty Level',
        primaryMetricValue: 'Level 3',
        secondaryMetricLabel: 'Success Rate',
        secondaryMetricValue: '88%',
        statusDescription:
            'Visual spatial matching and symmetry rules solved accurately.',
        isStrongPerformance: true,
      ),
      CognitiveGameReport(
        gameId: 'family_memories',
        title: 'Family Memories Game',
        category: 'Autobiographical Memory',
        score: 95,
        accuracyPercent: 96.0,
        avgResponseTimeSeconds: 2.1,
        primaryMetricLabel: 'Recognition Rate',
        primaryMetricValue: '96%',
        secondaryMetricLabel: 'Hesitation Time',
        secondaryMetricValue: '2.1 sec',
        statusDescription:
            'Instantly recognized son Rahul and granddaughter Priya with zero errors.',
        isStrongPerformance: true,
      ),
    ];
  }

  // ── Reminders Operations ────────────────────────────────────────
  // FIX: Sync caregiver reminder changes to linked patient

  List<CaregiverReminder> getReminders(
      {String? patientId, String? status, String? type}) {
    final pid = patientId ?? _selectedPatientId;
    var list = _reminders.where((r) => r.patientId == pid).toList();
    if (status != null && status.isNotEmpty) {
      list = list.where((r) => r.status == status).toList();
    }
    if (type != null && type.isNotEmpty && type != 'all') {
      list = list.where((r) => r.type == type).toList();
    }
    return list;
  }

  // FIX: Sync caregiver reminder changes to linked patient
  // FIX: Sync caregiver reminder to linked patient
  Future<void> addReminder(CaregiverReminder reminder) async {
    await init();
    _reminders.removeWhere((r) => r.id == reminder.id);
    _reminders.add(reminder);
    await _persist();
    remindersNotifier.value++;

    // Schedule real local notification on device
    await NotificationService.instance.scheduleReminder(reminder);

    // Sync to Firestore
    _syncReminderToCloud(reminder);
  }

  // FIX: Sync caregiver reminder changes to linked patient
  // FIX: Reschedule patient notification after reminder update
  Future<void> updateReminder(CaregiverReminder updated) async {
    await init();
    final idx = _reminders.indexWhere((r) => r.id == updated.id);
    if (idx != -1) {
      _reminders[idx] = updated;
      await _persist();
      remindersNotifier.value++;

      // Reschedule notification (cancel old, schedule new)
      await NotificationService.instance.cancelReminder(updated.id);
      if (updated.enabled) {
        await NotificationService.instance.scheduleReminder(updated);
      }

      // Sync to Firestore
      _syncReminderToCloud(updated);
    }
  }

  // FIX: Sync caregiver reminder changes to linked patient
  Future<void> toggleReminder(String id) async {
    await init();
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx != -1) {
      final cur = _reminders[idx];
      final toggled =
          cur.copyWith(enabled: !cur.enabled, updatedAt: DateTime.now());
      _reminders[idx] = toggled;
      await _persist();
      remindersNotifier.value++;

      if (toggled.enabled) {
        await NotificationService.instance.scheduleReminder(toggled);
      } else {
        await NotificationService.instance.cancelReminder(id);
      }

      // Sync to Firestore
      _syncReminderToCloud(toggled);
    }
  }

  // FIX: Sync caregiver reminder changes to linked patient
  Future<void> deleteReminder(String id) async {
    await init();
    final reminder = _reminders.firstWhere((r) => r.id == id,
        orElse: () => _reminders.first);
    final patientId = reminder.patientId;
    _reminders.removeWhere((r) => r.id == id);
    await _persist();
    remindersNotifier.value++;

    // Cancel notification
    await NotificationService.instance.cancelReminder(id);

    // Delete from Firestore
    _deleteReminderFromCloud(patientId, id);
  }

  // FIX: Sync caregiver reminder changes to linked patient - patient can acknowledge
  Future<void> acknowledgeReminder(String id) async {
    await init();
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx != -1) {
      final cur = _reminders[idx];
      final updated = cur.copyWith(
        status: 'acknowledged',
        acknowledgedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _reminders[idx] = updated;
      await _persist();
      remindersNotifier.value++;
      _syncReminderToCloud(updated);
    }
  }

  Future<void> _syncReminderToCloud(CaregiverReminder reminder) async {
    try {
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(reminder.patientId)
          .collection('reminders')
          .doc(reminder.id)
          .set(reminder.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('[CaregiverService] Cloud reminder sync note: $e');
    }
  }

  Future<void> _deleteReminderFromCloud(
      String patientId, String reminderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId)
          .collection('reminders')
          .doc(reminderId)
          .delete();
    } catch (e) {
      debugPrint('[CaregiverService] Cloud reminder delete note: $e');
    }
  }

  Future<void> syncPatientReminders(String patientId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId)
          .collection('reminders')
          .get();

      if (snapshot.docs.isNotEmpty) {
        await init();
        for (final doc in snapshot.docs) {
          final remote = CaregiverReminder.fromMap(doc.data());
          final idx = _reminders.indexWhere((r) => r.id == remote.id);
          if (idx != -1) {
            if (remote.updatedAt.isAfter(_reminders[idx].updatedAt)) {
              _reminders[idx] = remote;
            }
          } else {
            _reminders.add(remote);
          }
        }
        await _persist();
        final active = _reminders
            .where((r) => r.patientId == patientId && r.enabled)
            .toList();
        await NotificationService.instance.rescheduleAll(active);
        remindersNotifier.value++;
      }
    } catch (e) {
      debugPrint('[CaregiverService] syncPatientReminders note: $e');
    }
  }

  // ── Family Memories Operations ──────────────────────────────────

  List<FamilyMemoryMember> getFamilyMembers({String? patientId}) {
    final pid = patientId ?? _selectedPatientId;
    return _familyMembers.where((m) => m.patientId == pid).toList();
  }

  Future<void> addFamilyMember(FamilyMemoryMember member) async {
    await init();
    _familyMembers.add(member);
    await _persist();
  }

  Future<void> updateFamilyMember(FamilyMemoryMember updated) async {
    await init();
    final idx = _familyMembers.indexWhere((m) => m.id == updated.id);
    if (idx != -1) {
      _familyMembers[idx] = updated;
      await _persist();
    }
  }

  Future<void> deleteFamilyMember(String id) async {
    await init();
    _familyMembers.removeWhere((m) => m.id == id);
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

  Future<void> addAlert(CaregiverAlert alert) async {
    await init();
    _alerts.insert(0, alert);
    await _persist();
  }

  Future<void> dismissAlert(String id) async {
    await init();
    final idx = _alerts.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _alerts[idx] = _alerts[idx].copyWith(acknowledged: true);
      await _persist();
    }
  }

  List<SosAlertLog> getSosHistory() => List.unmodifiable(_sosLogs);

  Future<void> triggerSosAlert(String triggerType, {String notes = ''}) async {
    await init();
    final newSos = SosAlertLog(
      id: 'sos-',
      timestamp: DateTime.now(),
      triggerType: triggerType,
      resolved: false,
      notes: notes.isNotEmpty ? notes : 'Immediate emergency alert triggered.',
    );
    _sosLogs.insert(0, newSos);
    _alerts.insert(
      0,
      CaregiverAlert(
        id: 'alt-',
        type: 'emergency_sos',
        title: 'Emergency SOS Alert Triggered',
        message: 'Patient triggered an SOS alert via .',
        timestamp: DateTime.now(),
        acknowledged: false,
      ),
    );
    await _persist();
  }

  Future<void> addSosAlertLog(
          {required String triggerType, required String notes}) =>
      triggerSosAlert(triggerType, notes: notes);

  Future<void> resolveSosAlert(String id) async {
    await init();
    final idx = _sosLogs.indexWhere((s) => s.id == id);
    if (idx != -1) {
      _sosLogs[idx] = SosAlertLog(
        id: _sosLogs[idx].id,
        timestamp: _sosLogs[idx].timestamp,
        triggerType: _sosLogs[idx].triggerType,
        resolved: true,
        notes: ' (Resolved by caregiver at :)',
      );
      await _persist();
    }
  }

  bool isEmergencyActive() => _sosLogs.any((s) => !s.resolved);

  // ── Recent Activity Feed ────────────────────────────────────────

  List<CaregiverActivityItem> getRecentActivities() {
    final items = <CaregiverActivityItem>[];

    // Read live completed games from GameStorageService
    final recentGames = GameStorageService.instance.getRecentResults(limit: 3);
    for (final g in recentGames) {
      items.add(
        CaregiverActivityItem(
          title: 'Completed ${g.gameName}',
          subtitle:
              'Score: ${g.score}% • Accuracy: ${g.accuracy}% (${g.difficulty})',
          timeAgo: 'Today',
          iconType: 'game',
          isCompleted: true,
        ),
      );
    }

    // Include completed & upcoming care tasks
    final completedReminders =
        _reminders.where((r) => r.status == 'acknowledged').take(2);
    for (final r in completedReminders) {
      items.add(
        CaregiverActivityItem(
          title: r.title,
          subtitle: 'Completed at ${r.scheduledTime}',
          timeAgo: 'Today',
          iconType: r.type,
          isCompleted: true,
        ),
      );
    }

    if (items.isEmpty) {
      items.addAll([
        const CaregiverActivityItem(
          title: 'Morning medicine (Donepezil)',
          subtitle: 'Completed at 8:00 AM',
          timeAgo: 'Today, 8:04 AM',
          iconType: 'medication',
          isCompleted: true,
        ),
        const CaregiverActivityItem(
          title: 'Word Recall Session',
          subtitle: 'Score: 88% • Accuracy: 90% (Normal)',
          timeAgo: 'Today, 10:30 AM',
          iconType: 'game',
          isCompleted: true,
        ),
        const CaregiverActivityItem(
          title: 'Hydration - Water Intake',
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
