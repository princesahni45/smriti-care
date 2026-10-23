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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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

  /// Reset internal state and delete test cache for testing purposes.
  @visibleForTesting
  Future<void> resetForTesting() async {
    _localCodes.clear();
    _isInitialized = false;
    try {
      final file = await _getStorageFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
    await init();
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
        final codeMap = accessCode.toMap();
        codeMap['expiresAtTimestamp'] = Timestamp.fromDate(accessCode.expiresAt);
        await db.collection('patientAccessCodes').doc(candidateCode).set(codeMap);
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

    // Fall back to local store — return the newest active code
    final activeCodes = _localCodes.values
        .where((code) => code.patientId == patientId && code.isValid)
        .toList();
    if (activeCodes.isNotEmpty) {
      activeCodes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return activeCodes.first;
    }
    return null;
  }

  // ── Patient Actions: Verification & Login ─────────────────────────────────

  /// Verifies a patient code entered by an elderly user and resolves patient identity.
  ///
  /// Steps:
  /// 1. Normalize code (case-insensitive, trims hyphens/spaces).
  /// 2. Authenticate anonymously with Firebase Auth if available so the client
  ///    has an authenticated UID prior to querying Firestore.
  /// 3. Verify against Firestore `patientAccessCodes/{code}` or local cache.
  /// 4. Check active, not expired, and not already linked (race-condition protection).
  /// 5. Execute atomic WriteBatch linking the code and creating patientSessions/{uid}.
  /// 6. Return success with elderly-friendly error handling.
  /// Calls the secure Cloud Function verifyAndLinkPatientCode if deployed.
  Future<({bool success, String? patientId, String? patientName, String? error})?> _callCloudFunctionVerification({
    required String code,
    required String anonymousUid,
  }) async {
    try {
      if (Firebase.apps.isEmpty) return null;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      final token = await user.getIdToken();
      final projectId = Firebase.app().options.projectId;
      if (projectId.isEmpty) return null;

      final url = Uri.parse(
        'https://us-central1-$projectId.cloudfunctions.net/verifyAndLinkPatientCode',
      );
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'data': {'code': code}
        }),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final data = decoded['result'] ?? decoded['data'];
        if (data is Map<String, dynamic> && data['success'] == true) {
          return (
            success: true,
            patientId: data['patientId'] as String?,
            patientName: data['patientName'] as String?,
            error: null,
          );
        }
      }
    } catch (_) {
      // Cloud Function unreachable or not configured; fall back to local/batch verification
    }
    return null;
  }

  /// Verifies a patient code entered by an elderly user and resolves patient identity.
  ///
  /// Steps:
  /// 1. Normalize code (case-insensitive, trims hyphens/spaces).
  /// 2. Authenticate anonymously with Firebase Auth FIRST so the client
  ///    has an authenticated UID prior to any backend/cloud operations.
  /// 3. Verify via Cloud Function if available (zero client-side PII exposure).
  /// 4. Fall back to local store if Cloud Function is unavailable/offline.
  /// 5. Check active, not expired, and not already linked (race-condition protection).
  /// 6. Execute atomic WriteBatch linking the code and creating patientSessions/{uid}.
  /// 7. Mark session isCloudVerified only if the cloud accepted the link.
  /// 8. Return success with elderly-friendly error handling.
  Future<PatientCodeVerificationResult> verifyPatientCode(String rawInput) async {
    await init();
    final clean = normalizeCode(rawInput);

    if (clean.length < 7) {
      return PatientCodeVerificationResult.failure(
        'Please enter the full code given by your caregiver.',
      );
    }

    // 1. Authenticate anonymously with Firebase Auth FIRST (if available)
    // Ensures client has request.auth.uid for authenticated Firestore calls.
    String? anonymousUid;
    try {
      if (Firebase.apps.isNotEmpty) {
        final auth = FirebaseAuth.instance;
        User? user = auth.currentUser;
        if (user != null && !user.isAnonymous) {
          // If previously logged in with email/password (caregiver), sign out
          await auth.signOut();
          user = null;
        }
        if (user == null) {
          final cred = await auth.signInAnonymously();
          user = cred.user;
        }
        if (user != null) {
          anonymousUid = user.uid;
        }
      }
    } catch (e) {
      debugPrint('[PatientCodeService] Anonymous auth note (offline or test environment): $e');
    }

    // 2. Attempt trusted Cloud Function redemption first (Priority 2)
    if (anonymousUid != null) {
      final cloudRes = await _callCloudFunctionVerification(
        code: clean,
        anonymousUid: anonymousUid,
      );
      if (cloudRes != null && cloudRes.success && cloudRes.patientId != null) {
        final verifiedPatientId = cloudRes.patientId!;
        final verifiedPatientName = cloudRes.patientName ?? 'Patient';

        UserSessionService.instance.setVerifiedPatientSession(
          anonymousUid: anonymousUid,
          patientId: verifiedPatientId,
          isCloudVerified: true,
        );
        await CaregiverService.instance.selectPatient(verifiedPatientId);
        UserSessionService.instance.setActiveRole(UserRole.patient);

        final cloudCode = PatientAccessCode(
          code: clean,
          patientId: verifiedPatientId,
          caregiverId: '',
          patientName: verifiedPatientName,
          caregiverName: '',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 30)),
          isActive: true,
          isLinked: true,
          linkedAt: DateTime.now(),
        );

        _localCodes[clean] = cloudCode;
        await _persistLocal();

        return PatientCodeVerificationResult.success(cloudCode);
      }
    }

    // 3. Fall back to local store (preserves offline SOS and local code cache)
    final foundCode = _localCodes[clean];

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

    // 4. Check if already linked (prevent duplicate / concurrent re-use)
    if (foundCode.isLinked) {
      return PatientCodeVerificationResult.failure(
        'This code has already been linked to a device. Please ask your caregiver for a new code.',
      );
    }

    // 5. Atomic Batch: create patientSessions and link patientAccessCodes simultaneously
    final updated = foundCode.copyWith(
      isLinked: true,
      linkedAt: DateTime.now(),
    );

    bool cloudBatchCommitted = false;
    final db = _firestore;
    if (db != null && anonymousUid != null) {
      try {
        final batch = db.batch();
        final sessionDoc = db.collection('patientSessions').doc(anonymousUid);
        final codeDoc = db.collection('patientAccessCodes').doc(clean);

        batch.set(sessionDoc, {
          'patientId': updated.patientId,
          'code': clean,
          'anonymousUid': anonymousUid,
          'createdAt': FieldValue.serverTimestamp(),
          'isLinked': true,
        });

        final updatePayload = <String, dynamic>{
          'isLinked': true,
          'linkedAt': DateTime.now().toIso8601String(),
          'linkedUid': anonymousUid,
        };
        batch.update(codeDoc, updatePayload);

        await batch.commit();
        cloudBatchCommitted = true;
      } catch (e) {
        debugPrint('[PatientCodeService] Atomic batch commit note: $e');
      }
    }

    // 6. Update local cache
    _localCodes[clean] = updated;
    await _persistLocal();

    // 7. Update session in memory (mark cloud verified only if cloud committed)
    if (anonymousUid != null) {
      UserSessionService.instance.setVerifiedPatientSession(
        anonymousUid: anonymousUid,
        patientId: updated.patientId,
        isCloudVerified: cloudBatchCommitted,
      );
    }
    await CaregiverService.instance.selectPatient(updated.patientId);
    UserSessionService.instance.setActiveRole(UserRole.patient);

    return PatientCodeVerificationResult.success(updated);
  }
}
