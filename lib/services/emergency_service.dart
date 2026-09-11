// lib/services/emergency_service.dart
//
// SmritiCare — Emergency SOS & Contacts Service
//
// Responsibilities:
//  1. Stores Primary & Secondary emergency phone numbers.
//  2. Local persistent offline storage (100% accessible without internet).
//  3. Firestore synchronization to: patients/{patientId}/emergency_settings/main
//  4. Launches native phone dialer (tel:) and SMS composer (sms:) via url_launcher.
//  5. Enforces security: only authenticated caregivers can edit numbers; patients cannot.
//  6. Builds structured emergency SOS message with coordinates & optional map URL.

import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/services/caregiver_auth_service.dart';
import 'location_service.dart';

// FIX: Use shared SOS contacts for caregiver and patient
class EmergencySettingsData {
  final String primaryNumber;
  final String secondaryNumber;
  final String primaryName;
  final String secondaryName;
  final String primaryRelationship;
  final String secondaryRelationship;
  final DateTime updatedAt;
  final bool isCloudSynced;

  // Aliases for compatibility with emergencyContacts/config
  String get primaryPhone => primaryNumber;
  String get secondaryPhone => secondaryNumber;

  const EmergencySettingsData({
    required this.primaryNumber,
    required this.secondaryNumber,
    this.primaryName = 'Primary Caregiver',
    this.secondaryName = 'Emergency Contact',
    this.primaryRelationship = 'Family',
    this.secondaryRelationship = 'Doctor / Relative',
    required this.updatedAt,
    this.isCloudSynced = false,
  });

  EmergencySettingsData copyWith({
    String? primaryNumber,
    String? secondaryNumber,
    String? primaryName,
    String? secondaryName,
    String? primaryRelationship,
    String? secondaryRelationship,
    DateTime? updatedAt,
    bool? isCloudSynced,
  }) {
    return EmergencySettingsData(
      primaryNumber: primaryNumber ?? this.primaryNumber,
      secondaryNumber: secondaryNumber ?? this.secondaryNumber,
      primaryName: primaryName ?? this.primaryName,
      secondaryName: secondaryName ?? this.secondaryName,
      primaryRelationship: primaryRelationship ?? this.primaryRelationship,
      secondaryRelationship:
          secondaryRelationship ?? this.secondaryRelationship,
      updatedAt: updatedAt ?? this.updatedAt,
      isCloudSynced: isCloudSynced ?? this.isCloudSynced,
    );
  }

  Map<String, dynamic> toMap() => {
        'primaryNumber': primaryNumber,
        'secondaryNumber': secondaryNumber,
        'primaryPhone': primaryNumber,
        'secondaryPhone': secondaryNumber,
        'primaryName': primaryName,
        'secondaryName': secondaryName,
        'primaryRelationship': primaryRelationship,
        'secondaryRelationship': secondaryRelationship,
        'updatedAt': updatedAt.toIso8601String(),
        'isCloudSynced': isCloudSynced,
      };

  factory EmergencySettingsData.fromMap(Map<String, dynamic> map) =>
      EmergencySettingsData(
        primaryNumber: (map['primaryPhone'] as String?) ??
            (map['primaryNumber'] as String?) ??
            '+91 98765 43210',
        secondaryNumber: (map['secondaryPhone'] as String?) ??
            (map['secondaryNumber'] as String?) ??
            '+91 91234 56780',
        primaryName: (map['primaryName'] as String?) ?? 'Rahul Das',
        secondaryName: (map['secondaryName'] as String?) ?? 'Dr. Ananya Bora',
        primaryRelationship: (map['primaryRelationship'] as String?) ?? 'Son',
        secondaryRelationship:
            (map['secondaryRelationship'] as String?) ?? 'Family Doctor',
        updatedAt: map['updatedAt'] != null
            ? (map['updatedAt'] is Timestamp
                ? (map['updatedAt'] as Timestamp).toDate()
                : DateTime.tryParse(map['updatedAt'].toString()) ??
                    DateTime.now())
            : DateTime.now(),
        isCloudSynced: (map['isCloudSynced'] as bool?) ?? false,
      );
}

class SaveEmergencyResult {
  final bool isSuccess;
  final bool isLocalSaved;
  final bool isCloudSynced;
  final String statusMessage;

  const SaveEmergencyResult({
    required this.isSuccess,
    required this.isLocalSaved,
    required this.isCloudSynced,
    required this.statusMessage,
  });
}

class EmergencyService extends ChangeNotifier {
  EmergencyService._();
  static final EmergencyService instance = EmergencyService._();

  // Active emergency settings with default initial numbers
  EmergencySettingsData _settings = EmergencySettingsData(
    primaryNumber: '+91 98765 43210',
    secondaryNumber: '+91 91234 56780',
    primaryName: 'Rahul Das',
    secondaryName: 'Dr. Ananya Bora',
    primaryRelationship: 'Son',
    secondaryRelationship: 'Family Doctor',
    updatedAt: DateTime.now(),
    isCloudSynced: false,
  );

  bool _isInitialized = false;

  final ValueNotifier<EmergencySettingsData> settingsNotifier =
      ValueNotifier<EmergencySettingsData>(EmergencySettingsData(
    primaryNumber: '+91 98765 43210',
    secondaryNumber: '+91 91234 56780',
    primaryName: 'Rahul Das',
    secondaryName: 'Dr. Ananya Bora',
    primaryRelationship: 'Son',
    secondaryRelationship: 'Family Doctor',
    updatedAt: DateTime.now(),
    isCloudSynced: false,
  ));

  EmergencySettingsData get settings => _settings;
  String get primaryNumber => _settings.primaryNumber;
  String get secondaryNumber => _settings.secondaryNumber;
  String get primaryPhone => _settings.primaryNumber;
  String get secondaryPhone => _settings.secondaryNumber;

  /// Load cached emergency numbers on startup
  // FIX: Use shared SOS contacts for caregiver and patient
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final file = await _getStorageFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final decoded = jsonDecode(content) as Map<String, dynamic>;
          _settings = EmergencySettingsData.fromMap(decoded);
          settingsNotifier.value = _settings;
          notifyListeners();
        }
      } else {
        // Check alternate file
        final altFile = await _getAltStorageFile();
        if (await altFile.exists()) {
          final content = await altFile.readAsString();
          if (content.isNotEmpty) {
            final decoded = jsonDecode(content) as Map<String, dynamic>;
            _settings = EmergencySettingsData.fromMap(decoded);
            settingsNotifier.value = _settings;
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('[EmergencyService] Init notice: $e');
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
    return File('${dir.path}/smriti_care_emergency_contacts.json');
  }

  Future<File> _getAltStorageFile() async {
    Directory dir;
    try {
      dir = await getApplicationDocumentsDirectory();
    } catch (_) {
      dir = Directory.systemTemp;
    }
    return File('${dir.path}/smriti_care_emergency_settings.json');
  }

  Future<void> _persistLocally() async {
    try {
      final file = await _getStorageFile();
      await file.writeAsString(jsonEncode(_settings.toMap()));
      final altFile = await _getAltStorageFile();
      await altFile.writeAsString(jsonEncode(_settings.toMap()));
    } catch (e) {
      debugPrint('[EmergencyService] Local persist error: $e');
    }
  }

  // ── Validation Helpers ──────────────────────────────────────────────────────

  /// Validates phone number format
  static String? validatePhoneNumber(String? value,
      {String label = 'Phone number'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label cannot be empty.';
    }
    final clean = value.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (clean.length < 8 ||
        clean.length > 15 ||
        !RegExp(r'^[0-9]+$').hasMatch(clean)) {
      return 'Enter a valid phone number (8-15 digits).';
    }
    return null;
  }

  /// Checks if primary and secondary numbers are identical (including country-code prefix variations)
  static bool areNumbersDuplicate(String p1, String p2) {
    final c1 = p1.replaceAll(RegExp(r'[^0-9]'), '');
    final c2 = p2.replaceAll(RegExp(r'[^0-9]'), '');
    if (c1.isEmpty || c2.isEmpty) return false;
    if (c1 == c2) return true;
    // Compare last 10 digits to catch e.g. 919876543210 and 9876543210
    if (c1.length >= 10 && c2.length >= 10) {
      return c1.substring(c1.length - 10) == c2.substring(c2.length - 10);
    }
    return false;
  }

  // ── Caregiver Edit Numbers ─────────────────────────────────────────────────

  /// Updates emergency numbers for the linked patient.
  ///
  /// SECURITY:
  /// Enforces that only an authenticated caregiver can edit emergency numbers.
  /// Unauthenticated patient mode is denied permission.
  Future<SaveEmergencyResult> updateEmergencyNumbers({
    required String primaryNumber,
    required String secondaryNumber,
    String? primaryName,
    String? secondaryName,
    String? primaryRelationship,
    String? secondaryRelationship,
    String patientId = 'MC-2048',
  }) async {
    // Security check: Only caregiver role can edit
    final isCaregiver = CaregiverAuthService.instance.isCaregiverAuthenticated;
    if (!isCaregiver) {
      return const SaveEmergencyResult(
        isSuccess: false,
        isLocalSaved: false,
        isCloudSynced: false,
        statusMessage:
            'Permission denied: Only verified caregivers can edit emergency numbers.',
      );
    }

    final p1 = primaryNumber.trim();
    final p2 = secondaryNumber.trim();

    // Validation
    final v1 = validatePhoneNumber(p1, label: 'Primary emergency number');
    if (v1 != null) {
      return SaveEmergencyResult(
        isSuccess: false,
        isLocalSaved: false,
        isCloudSynced: false,
        statusMessage: v1,
      );
    }

    final v2 = validatePhoneNumber(p2, label: 'Secondary emergency number');
    if (v2 != null) {
      return SaveEmergencyResult(
        isSuccess: false,
        isLocalSaved: false,
        isCloudSynced: false,
        statusMessage: v2,
      );
    }

    final now = DateTime.now();
    _settings = _settings.copyWith(
      primaryNumber: p1,
      secondaryNumber: p2,
      primaryName: primaryName?.trim().isNotEmpty == true
          ? primaryName!.trim()
          : _settings.primaryName,
      secondaryName: secondaryName?.trim().isNotEmpty == true
          ? secondaryName!.trim()
          : _settings.secondaryName,
      primaryRelationship: primaryRelationship?.trim().isNotEmpty == true
          ? primaryRelationship!.trim()
          : _settings.primaryRelationship,
      secondaryRelationship: secondaryRelationship?.trim().isNotEmpty == true
          ? secondaryRelationship!.trim()
          : _settings.secondaryRelationship,
      updatedAt: now,
      isCloudSynced: false,
    );

    // 1. Save locally immediately (guaranteed offline access)
    settingsNotifier.value = _settings;
    await _persistLocally();
    notifyListeners();

    // 2. Attempt Firestore sync
    // FIX: Use shared SOS contacts for caregiver and patient
    // FIX: Use caregiver-controlled SOS contacts
    bool cloudSynced = false;
    try {
      if (Firebase.apps.isNotEmpty) {
        final payload = {
          'primaryPhone': p1,
          'primaryNumber': p1,
          'secondaryPhone': p2,
          'secondaryNumber': p2,
          'primaryName': _settings.primaryName,
          'secondaryName': _settings.secondaryName,
          'primaryRelationship': _settings.primaryRelationship,
          'secondaryRelationship': _settings.secondaryRelationship,
          'updatedAt': Timestamp.fromDate(now),
        };

        // Primary location specified by architecture: patients/{patientId}/emergencyContacts/config
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(patientId)
            .collection('emergencyContacts')
            .doc('config')
            .set(payload, SetOptions(merge: true));

        // Also update legacy/mirror path for maximum backwards compatibility
        await FirebaseFirestore.instance
            .collection('patients')
            .doc(patientId)
            .collection('emergency_settings')
            .doc('main')
            .set(payload, SetOptions(merge: true));

        cloudSynced = true;
      }
    } catch (firestoreError) {
      debugPrint(
          '[EmergencyService] Firestore sync notice (offline/placeholder): $firestoreError');
    }

    _settings = _settings.copyWith(isCloudSynced: cloudSynced);
    settingsNotifier.value = _settings;
    await _persistLocally();
    notifyListeners();

    if (cloudSynced) {
      return const SaveEmergencyResult(
        isSuccess: true,
        isLocalSaved: true,
        isCloudSynced: true,
        statusMessage: 'Emergency numbers saved locally and synced to cloud.',
      );
    } else {
      return const SaveEmergencyResult(
        isSuccess: true,
        isLocalSaved: true,
        isCloudSynced: false,
        statusMessage: 'Saved locally on device (cloud sync pending).',
      );
    }
  }

  // ── SOS Message Construction ────────────────────────────────────────────────

  /// Builds a human-readable emergency SOS text with raw coordinates and optional map link
  String buildSosMessage({
    required SosLocation location,
    String patientName = 'Mr. Ramesh Das',
  }) {
    final status =
        location.isLastKnown ? 'Last Known Location' : 'Current GPS Fix';
    final accuracyStr = location.accuracy > 0
        ? '${location.accuracy.toStringAsFixed(1)}m'
        : 'Standard';

    final buffer = StringBuffer();
    buffer.writeln('EMERGENCY SOS from SmritiCare.');
    buffer.writeln('Patient: $patientName needs immediate assistance.');
    buffer.writeln('Location Details ($status):');
    buffer.writeln('Latitude: ${location.latitude.toStringAsFixed(6)}');
    buffer.writeln('Longitude: ${location.longitude.toStringAsFixed(6)}');
    buffer.writeln('Accuracy: $accuracyStr');
    buffer.writeln(
        'Time: ${location.timestamp.toLocal().toString().split('.').first}');
    buffer.writeln('Google Maps: ${location.mapsUrl}');

    return buffer.toString();
  }

  // ── Native Phone Dialer & SMS Launcher ──────────────────────────────────────

  /// Launches the native device dialer with the provided phone number.
  /// Does not require internet.
  Future<bool> launchCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        debugPrint(
            '[EmergencyService] Cannot launch phone dialer for: $cleanPhone');
        return false;
      }
    } catch (e) {
      debugPrint('[EmergencyService] Call launch error: $e');
      return false;
    }
  }

  /// Launches the native SMS composer with the phone number and pre-filled emergency message.
  /// Does not send silently in background; opens user composer safely.
  Future<bool> launchSms(String phoneNumber, String message) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(
      scheme: 'sms',
      path: cleanPhone,
      queryParameters: <String, String>{
        'body': message,
      },
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        // Fallback without query params if device SMS app restricts URI parameters
        final fallbackUri = Uri(scheme: 'sms', path: cleanPhone);
        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
          return true;
        }
        return false;
      }
    } catch (e) {
      debugPrint('[EmergencyService] SMS launch error: $e');
      return false;
    }
  }
}
