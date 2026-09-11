// lib/core/services/caregiver_auth_service.dart
//
// Manages Caregiver Authentication with Firebase Auth & Firestore role checks.
// Enforces:
// 1. Patient mode is the default and never requires login.
// 2. Caregiver mode is strictly protected and requires email/password verification.
// 3. Firestore users/{uid} must have role == 'caregiver'.
// 4. Role == 'patient' is rejected with 'This account does not have caregiver access.'
// 5. Session is in-memory and resets to Patient on app restart.
// 6. Explicit 'Exit Caregiver Mode' clears the caregiver session.

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

// FIX: Added doctor role support
enum DashboardMode {
  patient,
  caregiver,
  doctor,
}

class CaregiverAuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final String? uid;
  final String? email;
  final String? name;

  const CaregiverAuthResult({
    required this.isSuccess,
    this.errorMessage,
    this.uid,
    this.email,
    this.name,
  });

  factory CaregiverAuthResult.success({
    required String uid,
    required String email,
    String? name,
  }) {
    return CaregiverAuthResult(
      isSuccess: true,
      uid: uid,
      email: email,
      name: name,
    );
  }

  factory CaregiverAuthResult.failure(String message) {
    return CaregiverAuthResult(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

// FIX: Added doctor role support - DoctorAuthResult wrapper
class DoctorAuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final String? uid;
  final String? email;
  final String? name;

  const DoctorAuthResult({
    required this.isSuccess,
    this.errorMessage,
    this.uid,
    this.email,
    this.name,
  });

  factory DoctorAuthResult.success({
    required String uid,
    required String email,
    String? name,
  }) {
    return DoctorAuthResult(
      isSuccess: true,
      uid: uid,
      email: email,
      name: name,
    );
  }

  factory DoctorAuthResult.failure(String message) {
    return DoctorAuthResult(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

class CaregiverAuthService extends ChangeNotifier {
  CaregiverAuthService._();
  static final CaregiverAuthService instance = CaregiverAuthService._();

  // Active dashboard mode — ALWAYS starts in patient mode on app launch
  DashboardMode _currentMode = DashboardMode.patient;

  // In-memory caregiver session (not persisted across app restarts)
  bool _isCaregiverAuthenticated = false;
  String? _caregiverUid;
  String? _caregiverEmail;
  String? _caregiverName;

  // FIX: Added doctor role support - In-memory doctor session
  bool _isDoctorAuthenticated = false;
  String? _doctorUid;
  String? _doctorEmail;
  String? _doctorName;

  // FIX: Test mode — enabled automatically by main.dart when Firebase is not
  // configured (no google-services.json), and also used directly in unit tests.
  bool _isTestMode = false;
  final Map<String, Map<String, String>> _testAccounts = {
    'caregiver@smriti.care': {
      'password': 'password123',
      'role': 'caregiver',
      'name': 'Dr. Aditi Sharma',
      'uid': 'test_caregiver_uid_01',
    },
    'patient@smriti.care': {
      'password': 'password123',
      'role': 'patient',
      'name': 'Mr. Ramesh Das',
      'uid': 'test_patient_uid_02',
    },
    // FIX: Added doctor role support - Doctor test account
    'doctor@smriti.care': {
      'password': 'password123',
      'role': 'doctor',
      'name': 'Dr. Ananya Bora',
      'uid': 'test_doctor_uid_01',
    },
  };

  DashboardMode get currentMode => _currentMode;
  bool get isCaregiverAuthenticated => _isCaregiverAuthenticated;
  String? get caregiverUid => _caregiverUid;
  String? get caregiverEmail => _caregiverEmail;
  String? get caregiverName => _caregiverName;

  // FIX: Added doctor role support - Doctor state getters
  bool get isDoctorAuthenticated => _isDoctorAuthenticated;
  String? get doctorUid => _doctorUid;
  String? get doctorEmail => _doctorEmail;
  String? get doctorName => _doctorName;

  bool get isTestMode => _isTestMode;

  // FIX: enableTestMode() is now called by main.dart (not just tests) when
  // Firebase.initializeApp() fails due to missing google-services.json.
  void enableTestMode({bool enabled = true}) {
    _isTestMode = enabled;
  }

  @visibleForTesting
  void registerTestAccount({
    required String email,
    required String password,
    required String role,
    required String name,
    required String uid,
  }) {
    _testAccounts[email.toLowerCase().trim()] = {
      'password': password,
      'role': role,
      'name': name,
      'uid': uid,
    };
  }

  @visibleForTesting
  void resetForTest() {
    _currentMode = DashboardMode.patient;
    _isCaregiverAuthenticated = false;
    _caregiverUid = null;
    _caregiverEmail = null;
    _caregiverName = null;
    _isDoctorAuthenticated = false;
    _doctorUid = null;
    _doctorEmail = null;
    _doctorName = null;
    notifyListeners();
  }

  /// Ensure Firebase is safely initialized
  Future<void> ensureFirebaseInitialized() async {
    if (_isTestMode) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (e) {
      debugPrint('CaregiverAuthService: Firebase init notice: $e');
    }
  }

  /// Attempt caregiver login via Firebase Authentication and Firestore role check
  Future<CaregiverAuthResult> loginCaregiver({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      return CaregiverAuthResult.failure('Please enter both email and password.');
    }

    // ── Test Mode Handling (For automated widget and unit tests) ───────────
    if (_isTestMode) {
      final acc = _testAccounts[cleanEmail];
      if (acc == null || acc['password'] != cleanPassword) {
        return CaregiverAuthResult.failure('Invalid email or password.');
      }

      final role = acc['role'] ?? 'patient';
      if (role != 'caregiver') {
        return CaregiverAuthResult.failure(
          'This account does not have caregiver access.',
        );
      }

      _isCaregiverAuthenticated = true;
      _currentMode = DashboardMode.caregiver;
      _caregiverUid = acc['uid'];
      _caregiverEmail = cleanEmail;
      _caregiverName = acc['name'];
      notifyListeners();

      return CaregiverAuthResult.success(
        uid: acc['uid']!,
        email: cleanEmail,
        name: acc['name'],
      );
    }

    // ── Production Firebase Auth & Firestore verification ─────────────────
    try {
      await ensureFirebaseInitialized();

      // FIX: Centralized Firebase Auth service used here
      final authResult = await AuthService.instance.loginCaregiver(
        email: cleanEmail,
        password: cleanPassword,
      );

      if (!authResult.isSuccess) {
        return CaregiverAuthResult.failure(
          authResult.errorMessage ?? 'Authentication failed.',
        );
      }

      // Successful caregiver verification
      _isCaregiverAuthenticated = true;
      _currentMode = DashboardMode.caregiver;
      _caregiverUid = authResult.uid;
      _caregiverEmail = authResult.email;
      _caregiverName = authResult.displayName ?? 'Caregiver';
      notifyListeners();

      return CaregiverAuthResult.success(
        uid: authResult.uid!,
        email: _caregiverEmail!,
        name: _caregiverName,
      );
    } catch (e) {
      return CaregiverAuthResult.failure('Login error: $e');
    }
  }

  /// Switch to Patient mode without logging out caregiver (session retained for current app run)
  void switchToPatientMode() {
    _currentMode = DashboardMode.patient;
    notifyListeners();
  }

  /// Switch to Caregiver mode if session is already active
  bool switchToCaregiverModeIfAuthenticated() {
    if (_isCaregiverAuthenticated) {
      _currentMode = DashboardMode.caregiver;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Explicit caregiver sign out / Exit Caregiver Mode
  Future<void> exitCaregiverMode() async {
    try {
      if (!_isTestMode && Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (_) {}

    _isCaregiverAuthenticated = false;
    _caregiverUid = null;
    _caregiverEmail = null;
    _caregiverName = null;
    _currentMode = DashboardMode.patient;
    notifyListeners();
  }

  // ── Doctor Authentication ──────────────────────────────────────────────────

  // FIX: Added doctor role support - loginDoctor
  Future<DoctorAuthResult> loginDoctor({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      return DoctorAuthResult.failure('Please enter both email and password.');
    }

    // ── Test Mode Handling
    if (_isTestMode) {
      final acc = _testAccounts[cleanEmail];
      if (acc == null || acc['password'] != cleanPassword) {
        return DoctorAuthResult.failure('Invalid email or password.');
      }

      final role = acc['role'] ?? 'patient';
      if (role != 'doctor') {
        return DoctorAuthResult.failure(
          'This account does not have doctor access.',
        );
      }

      _isDoctorAuthenticated = true;
      _currentMode = DashboardMode.doctor;
      _doctorUid = acc['uid'];
      _doctorEmail = cleanEmail;
      _doctorName = acc['name'];
      notifyListeners();

      return DoctorAuthResult.success(
        uid: acc['uid']!,
        email: cleanEmail,
        name: acc['name'],
      );
    }

    // ── Production Firebase Auth & Firestore verification
    try {
      await ensureFirebaseInitialized();

      final authResult = await AuthService.instance.loginDoctor(
        email: cleanEmail,
        password: cleanPassword,
      );

      if (!authResult.isSuccess) {
        return DoctorAuthResult.failure(
          authResult.errorMessage ?? 'Authentication failed.',
        );
      }

      _isDoctorAuthenticated = true;
      _currentMode = DashboardMode.doctor;
      _doctorUid = authResult.uid;
      _doctorEmail = authResult.email;
      _doctorName = authResult.displayName ?? 'Doctor';
      notifyListeners();

      return DoctorAuthResult.success(
        uid: authResult.uid!,
        email: _doctorEmail!,
        name: _doctorName,
      );
    } catch (e) {
      return DoctorAuthResult.failure('Login error: $e');
    }
  }

  /// Switch to Doctor mode if session is already active
  bool switchToDoctorModeIfAuthenticated() {
    if (_isDoctorAuthenticated) {
      _currentMode = DashboardMode.doctor;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Explicit doctor sign out / Exit Doctor Mode
  Future<void> exitDoctorMode() async {
    try {
      if (!_isTestMode && Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (_) {}

    _isDoctorAuthenticated = false;
    _doctorUid = null;
    _doctorEmail = null;
    _doctorName = null;
    _currentMode = DashboardMode.patient;
    notifyListeners();
  }
}
