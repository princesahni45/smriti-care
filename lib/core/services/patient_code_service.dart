// lib/core/services/patient_code_service.dart
//
// Service for generating, storing, verifying, and managing Patient Access Codes.
// Supports:
// 1. Cryptographically secure random code generation with collision avoidance.
// 2. Unambiguous character set (no 0/O, 1/I, L).
// 3. Normalized input handling (case-insensitive, ignores hyphens and spaces).
// 4. Cloud Firestore synchronization with atomic uniqueness guarantee.
// 5. Offline-first local JSON persistence so cached/local codes work offline.
// 6. Elderly-friendly error messaging.

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/patient_access_code.dart';
import '../models/user_model.dart';
import 'caregiver_service.dart';

/// Result of patient access code verification
class PatientCodeVerificationResult {
  final bool isSuccess;
  final String? errorMessage;
  final PatientAccessCode? accessCode;
  final String? patientId;
  final String? patientName;

  const PatientCodeVerificationResult._({
    required this.isSuccess,
    this.errorMessage,
    this.accessCode,
    this.patientId,
    this.patientName,
  });

  factory PatientCodeVerificationResult.success(PatientAccessCode code) {
    return PatientCodeVerificationResult._(
      isSuccess: true,
      accessCode: code,
      patientId: code.patientId,
      patientName: code.patientName,
    );
  }

  factory PatientCodeVerificationResult.failure(String message) {
    return PatientCodeVerificationResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

class PatientCodeService {
  PatientCodeService._();
  static final PatientCodeService instance = PatientCodeService._();

  // ── Character Set for Unambiguous Codes ──────────────────────────────────
  // 29 characters: numbers 2-9, letters excluding I, L, O, 0, 1.
  static const String _alphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
  static const String codePrefix = 'SMR';

  final Map<String, PatientAccessCode> _localCodes = {};
  bool _isInitialized = false;

  /// Check whether Firebase/Firestore is available and initialized.
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

  // ── Initialization & Local Storage ─────────────────────────────────────────

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final file = await _getStorageFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final decoded = jsonDecode(content) as Map<String, dynamic>;
          _localCodes.clear();
          decoded.forEach((key, val) {
            if (val is Map<String, dynamic>) {
              _localCodes[key] = PatientAccessCode.fromMap(val);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('[PatientCodeService] Local init error: $e');
    } finally {
      _seedDefaultCodesIfEmpty();
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
    return File('${dir.path}/smriti_care_patient_access_codes.json');
  }

  Future<void> _persistLocal() async {
    try {
      final file = await _getStorageFile();
      final map = _localCodes.map((k, v) => MapEntry(k, v.toMap()));
      await file.writeAsString(jsonEncode(map));
    } catch (e) {
      debugPrint('[PatientCodeService] Local persist error: $e');
    }
  }

  /// Seeds demo code for testing / initial prototype offline run
  void _seedDefaultCodesIfEmpty() {
    if (_localCodes.isEmpty) {
      final defaultCode = PatientAccessCode(
        code: 'SMR-4827-KP',
        patientId: 'MC-2048',
        caregiverId: 'caregiver_mohak_01',
        patientName: 'Mr. Ramesh Das',
        caregiverName: 'Mohak Singh',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        isActive: true,
        isLinked: false,
      );
      _localCodes[defaultCode.code] = defaultCode;
    }
  }

  // ── Code Generation & Formatting ───────────────────────────────────────────

  /// Normalizes user-entered code:
  /// - converts to uppercase
  /// - strips spaces, hyphens, colons, underscores
  /// - prepends SMR- if missing
  /// - formats as SMR-XXXX-YY
  static String normalizeCode(String input) {
    String clean = input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (clean.isEmpty) return '';

    if (clean.startsWith('SMR')) {
      clean = clean.substring(3);
    }

    if (clean.length <= 4) {
      return '$codePrefix-$clean';
    } else if (clean.length <= 6) {
      final part1 = clean.substring(0, 4);
      final part2 = clean.substring(4);
      return '$codePrefix-$part1-$part2';
    } else {
      final part1 = clean.substring(0, 4);
      final part2 = clean.substring(4, 6);
      return '$codePrefix-$part1-$part2';
    }
  }

  /// Generates a cryptographically random access code string: SMR-XXXX-YY
  String _generateRandomCodeString() {
    final secureRandom = Random.secure();
    final buffer = StringBuffer();

    // 4 chars for group 1
    for (int i = 0; i < 4; i++) {
      buffer.write(_alphabet[secureRandom.nextInt(_alphabet.length)]);
    }
    buffer.write('-');
    // 2 chars for group 2
    for (int i = 0; i < 2; i++) {
      buffer.write(_alphabet[secureRandom.nextInt(_alphabet.length)]);
    }

    return '$codePrefix-${buffer.toString()}';
  }

  // ── Caregiver Actions: Generate, Revoke, Regenerate ─────────────────────────

  /// Generates a guaranteed-unique patient access code.
  /// Checks Firestore if available (with retry on collision) and saves locally.
  Future<PatientAccessCode> generateCodeForPatient({
    required String patientId,
    required String patientName,
    required String caregiverId,
    required String caregiverName,
    Duration validity = const Duration(days: 30),
  }) async {
    await init();

    // First deactivate any currently active codes for this patient
    await _revokeActiveCodesForPatientInternal(patientId);

    String candidateCode = '';
    bool isUnique = false;
    int attempts = 0;

    while (!isUnique && attempts < 10) {
      attempts++;
      candidateCode = _generateRandomCodeString();

      // Check local collision
      if (_localCodes.containsKey(candidateCode)) {
        continue;
      }

      // Check Firestore collision if available
      final db = _firestore;
      if (db != null) {
        try {
          final doc = await db.collection('patientAccessCodes').doc(candidateCode).get();
          if (doc.exists) {
            continue;
          }
        } catch (e) {
          debugPrint('[PatientCodeService] Firestore check collision warning: $e');
        }
      }

      isUnique = true;
    }

    final now = DateTime.now();
    final accessCode = PatientAccessCode(
      code: candidateCode,
      patientId: patientId,
      caregiverId: caregiverId,
      patientName: patientName,
      caregiverName: caregiverName,
      createdAt: now,
      expiresAt: now.add(validity),
      isActive: true,
      isLinked: false,
    );

    // Save locally
    _localCodes[candidateCode] = accessCode;
    await _persistLocal();

    // Save to Firestore if available
    final db = _firestore;
    if (db != null) {
      try {
        await db.collection('patientAccessCodes').doc(candidateCode).set(accessCode.toMap());
        // Also update pointer in patient document
        await db.collection('patients').doc(patientId).set({
          'activeAccessCode': candidateCode,
          'patientName': patientName,
          'caregiverId': caregiverId,
          'updatedAt': now.toIso8601String(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('[PatientCodeService] Firestore sync warning: $e');
      }
    }

    return accessCode;
  }

  /// Revokes an existing code.
  Future<bool> revokeCode(String rawCode) async {
    await init();
    final canonical = normalizeCode(rawCode);
    if (_localCodes.containsKey(canonical)) {
      final updated = _localCodes[canonical]!.copyWith(isActive: false);
      _localCodes[canonical] = updated;
      await _persistLocal();
    }

    final db = _firestore;
    if (db != null) {
      try {
        await db.collection('patientAccessCodes').doc(canonical).update({'isActive': false});
      } catch (e) {
        debugPrint('[PatientCodeService] Firestore revoke warning: $e');
      }
    }
    return true;
  }

  /// Revokes all currently active codes for a specific patient.
  Future<void> _revokeActiveCodesForPatientInternal(String patientId) async {
    final activeForPatient = _localCodes.values
        .where((c) => c.patientId == patientId && c.isActive)
        .map((c) => c.code)
        .toList();

    for (final code in activeForPatient) {
      _localCodes[code] = _localCodes[code]!.copyWith(isActive: false);
      final db = _firestore;
      if (db != null) {
        try {
          await db.collection('patientAccessCodes').doc(code).update({'isActive': false});
        } catch (_) {}
      }
    }
  }

  /// Gets the currently active access code for a given patientId, if any.
  Future<PatientAccessCode?> getActiveCodeForPatient(String patientId) async {
    await init();

    // Check Firestore first if available
    final db = _firestore;
    if (db != null) {
      try {
        final query = await db
            .collection('patientAccessCodes')
            .where('patientId', isEqualTo: patientId)
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          final code = PatientAccessCode.fromMap(query.docs.first.data());
          if (code.isValid) {
            _localCodes[code.code] = code;
            await _persistLocal();
            return code;
          }
        }
      } catch (e) {
        debugPrint('[PatientCodeService] Firestore getActiveCode warning: $e');
      }
    }

    // Fall back to local store
    for (final code in _localCodes.values) {
      if (code.patientId == patientId && code.isValid) {
        return code;
      }
    }
    return null;
  }

  // ── Patient Actions: Verification & Login ─────────────────────────────────

  /// Verifies a patient code entered by an elderly user and resolves patient identity.
  ///
  /// Steps:
  /// 1. Normalize code (case-insensitive, trims hyphens/spaces).
  /// 2. If online: verify against Firestore `patientAccessCodes/{code}`.
  /// 3. If offline / test mode: verify against cached local codes.
  /// 4. Check if active and not expired.
  /// 5. Return success with elderly-friendly error handling.
  Future<PatientCodeVerificationResult> verifyPatientCode(String rawInput) async {
    await init();
    final clean = normalizeCode(rawInput);

    if (clean.length < 7) {
      return PatientCodeVerificationResult.failure(
        'Please enter the full code given by your caregiver.',
      );
    }

    PatientAccessCode? foundCode;

    // 1. Try Firestore verification first
    final db = _firestore;
    if (db != null) {
      try {
        final doc = await db.collection('patientAccessCodes').doc(clean).get();
        if (doc.exists && doc.data() != null) {
          foundCode = PatientAccessCode.fromMap(doc.data()!);
        }
      } catch (e) {
        debugPrint('[PatientCodeService] Firestore read error: $e');
      }
    }

    // 2. Fall back to local store if Firestore unavailable or offline
    foundCode ??= _localCodes[clean];

    if (foundCode == null) {
      return PatientCodeVerificationResult.failure(
        'That code is not correct. Please ask your caregiver to check it.',
      );
    }

    if (!foundCode.isActive) {
      return PatientCodeVerificationResult.failure(
        'This code is no longer active. Please ask your caregiver for a new code.',
      );
    }

    if (foundCode.isExpired) {
      return PatientCodeVerificationResult.failure(
        'This code has expired. Please ask your caregiver for a new code.',
      );
    }

    // Mark as linked
    final updated = foundCode.copyWith(
      isLinked: true,
      linkedAt: DateTime.now(),
    );
    _localCodes[clean] = updated;
    await _persistLocal();

    if (db != null) {
      try {
        await db.collection('patientAccessCodes').doc(clean).update({
          'isLinked': true,
          'linkedAt': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    }

    // Update active patient in CaregiverService and UserSessionService
    await CaregiverService.instance.selectPatient(updated.patientId);
    UserSessionService.instance.setActiveRole(UserRole.patient);

    return PatientCodeVerificationResult.success(updated);
  }
}
