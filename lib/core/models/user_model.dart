// lib/core/models/user_model.dart
//
// Simple user models ported from the React session/auth system.
// TODO: Replace with proper backend models when Firebase/FastAPI is integrated.

// FIX: Added doctor role support
enum UserRole { patient, caregiver, doctor }

class PatientUser {
  final String patientId;
  final String displayName;
  final String fullName;
  final String email;
  final String preferredLanguage;
  final bool isSessionActive;
  final DateTime sessionStartedAt;

  const PatientUser({
    required this.patientId,
    required this.displayName,
    required this.fullName,
    required this.email,
    this.preferredLanguage = 'en',
    this.isSessionActive = true,
    required this.sessionStartedAt,
  });

  factory PatientUser.prototype() => PatientUser(
        patientId: 'MC-2048',
        displayName: 'Ramesh',
        fullName: 'Mr. Ramesh Das',
        email: 'patient@example.com',
        preferredLanguage: 'en',
        isSessionActive: true,
        sessionStartedAt: DateTime.now(),
      );

  PatientUser copyWith({
    String? patientId,
    String? displayName,
    String? fullName,
    String? email,
    String? preferredLanguage,
    bool? isSessionActive,
    DateTime? sessionStartedAt,
  }) =>
      PatientUser(
        patientId: patientId ?? this.patientId,
        displayName: displayName ?? this.displayName,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        preferredLanguage: preferredLanguage ?? this.preferredLanguage,
        isSessionActive: isSessionActive ?? this.isSessionActive,
        sessionStartedAt: sessionStartedAt ?? this.sessionStartedAt,
      );
}

class CaregiverUser {
  final String email;
  final String name;
  final String initials;

  const CaregiverUser({
    required this.email,
    required this.name,
    required this.initials,
  });

  factory CaregiverUser.prototype() => const CaregiverUser(
        email: 'singhmohak360@gmail.com',
        name: 'Mohak Singh',
        initials: 'MS',
      );
}

// FIX: Added doctor role support - DoctorUser profile model
class DoctorUser {
  final String doctorId;
  final String email;
  final String name;
  final String specialization;
  final String hospitalOrClinic;
  final String registrationNumber;
  final String? phone;

  const DoctorUser({
    required this.doctorId,
    required this.email,
    required this.name,
    required this.specialization,
    required this.hospitalOrClinic,
    required this.registrationNumber,
    this.phone,
  });

  factory DoctorUser.prototype() => const DoctorUser(
        doctorId: 'DOC-001',
        email: 'doctor@smriti.care',
        name: 'Dr. Ananya Bora',
        specialization: 'Neurologist & Dementia Specialist',
        hospitalOrClinic: 'Guwahati Neurological Institute',
        registrationNumber: 'NMC-2018-094827',
        phone: '+91 98765 11223',
      );
}

/// Simple prototype authentication — mirrors authConfig.js logic.
/// TODO: Replace with secure backend auth (JWT / Firebase) before production.
class AuthService {
  AuthService._();

  static ({bool success, PatientUser? user, String? error}) authenticatePatient(
    String email,
    String password,
  ) {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      return (
        success: false,
        user: null,
        error: 'Please enter both email and password.'
      );
    }

    final normalizedEmail = email.trim().toLowerCase();
    final trimmedPassword = password.trim();

    const acceptedEmails = [
      'patient@example.com',
      'ramesh@example.com',
      'ramesh.das@example.com',
      'rameshdas@gmail.com',
      'you@example.com',
      'singhmohak360@gmail.com',
    ];
    const acceptedPasswords = ['Hello@123', 'Patient@123'];

    final emailOk = acceptedEmails.contains(normalizedEmail);
    final passwordOk = acceptedPasswords.contains(trimmedPassword);

    if (emailOk && passwordOk) {
      return (success: true, user: PatientUser.prototype(), error: null);
    }
    return (
      success: false,
      user: null,
      error: 'Email or password is incorrect. Please try again.'
    );
  }

  static ({bool success, CaregiverUser? user, String? error})
      authenticateCaregiver(
    String email,
    String password,
  ) {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      return (
        success: false,
        user: null,
        error: 'Please enter both email and password.'
      );
    }
    if (email.trim() == 'singhmohak360@gmail.com' &&
        password.trim() == 'Hello@123') {
      return (success: true, user: CaregiverUser.prototype(), error: null);
    }
    return (
      success: false,
      user: null,
      error: 'Please enter the sample caregiver credentials shown below.',
    );
  }

  // FIX: Added doctor role support - doctor prototype authentication
  static ({bool success, DoctorUser? user, String? error}) authenticateDoctor(
    String email,
    String password,
  ) {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      return (
        success: false,
        user: null,
        error: 'Please enter both email and password.'
      );
    }
    final cleanEmail = email.trim().toLowerCase();
    if ((cleanEmail == 'doctor@smriti.care' ||
            cleanEmail == 'ananya.bora@smriti.care') &&
        (password.trim() == 'password123' || password.trim() == 'Doctor@123')) {
      return (success: true, user: DoctorUser.prototype(), error: null);
    }
    return (
      success: false,
      user: null,
      error:
          'Invalid doctor credentials. Use doctor@smriti.care / password123 for test mode.',
    );
  }

  /// Validates caregiver PIN for patient session exit. PIN: 1234
  static ({bool success, String? error}) validateCaregiverPin(String pin) {
    if (pin.trim() == '1234') return (success: true, error: null);
    return (success: false, error: "That PIN isn't correct. Please try again.");
  }
}

/// Global session state manager for active role
class UserSessionService {
  UserSessionService._();
  static final UserSessionService instance = UserSessionService._();

  UserRole _activeRole = UserRole.patient;
  UserRole get activeRole => _activeRole;

  bool get isCaregiver => _activeRole == UserRole.caregiver;
  bool get isPatient => _activeRole == UserRole.patient;
  // FIX: Added doctor role support
  bool get isDoctor => _activeRole == UserRole.doctor;

  void setActiveRole(UserRole role) {
    _activeRole = role;
  }
}
