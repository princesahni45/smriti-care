````dart
// lib/services/auth_service.dart
//
// SmritiCare — Centralized Firebase Authentication Service
//
// Responsibilities:
//  1. Caregiver email/password login via Firebase Auth
//  2. Doctor email/password login via Firebase Auth
//  3. Firestore role verification:
//       users/{uid}/role == "caregiver"
//       users/{uid}/role == "doctor"
//  4. Sign out using FirebaseAuth.instance.signOut()
//  5. Expose the current Firebase user
//  6. Provide clean FirebaseAuthException messages
//
// NOTE:
// - Passwords are never stored in Firestore.
// - Firebase.initializeApp() must complete before using this service.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Result wrapper for authentication operations.
class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final String? uid;
  final String? email;
  final String? displayName;

  const AuthResult._({
    required this.isSuccess,
    this.errorMessage,
    this.uid,
    this.email,
    this.displayName,
  });

  factory AuthResult.success({
    required String uid,
    required String email,
    String? displayName,
  }) {
    return AuthResult._(
      isSuccess: true,
      uid: uid,
      email: email,
      displayName: displayName,
    );
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

/// Centralized Firebase Authentication Service.
///
/// Access the singleton using:
///
/// ```dart
/// AuthService.instance
/// ```
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  FirebaseAuth get _auth => FirebaseAuth.instance;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// The currently signed-in Firebase user, or null.
  User? get currentUser => _auth.currentUser;

  /// Stream of Firebase authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ---------------------------------------------------------------------------
  // Caregiver Login
  // ---------------------------------------------------------------------------

  /// Logs in a caregiver using Firebase email/password authentication.
  ///
  /// The user's Firestore document must contain:
  ///
  /// ```text
  /// users/{uid}/role = caregiver
  /// ```
  Future<AuthResult> loginCaregiver({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      return AuthResult.failure(
        'Please enter both email and password.',
      );
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      final user = credential.user;

      if (user == null) {
        return AuthResult.failure(
          'Authentication failed. Please try again.',
        );
      }

      final profile = await _getUserProfile(user.uid);

      if (profile == null) {
        await _safeSignOut();

        return AuthResult.failure(
          'Could not verify caregiver permissions. '
          'Please check your connection and try again.',
        );
      }

      final role = _readRole(profile);
      final name = _readName(profile);

      if (role != 'caregiver') {
        await _safeSignOut();

        if (role == 'patient') {
          return AuthResult.failure(
            'This account belongs to a patient, not a caregiver. '
            'Please use your caregiver credentials.',
          );
        }

        if (role == 'doctor') {
          return AuthResult.failure(
            'This account belongs to a doctor. '
            'Please use the doctor login screen.',
          );
        }

        return AuthResult.failure(
          'This account does not have caregiver access. '
          'Contact your administrator.',
        );
      }

      debugPrint(
        '[AuthService] Caregiver login successful: ${user.uid}',
      );

      return AuthResult.success(
        uid: user.uid,
        email: user.email ?? cleanEmail,
        displayName: name ?? user.displayName ?? 'Caregiver',
      );
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(
        _mapFirebaseError(error),
      );
    } catch (error) {
      debugPrint(
        '[AuthService] Unexpected caregiver login error: $error',
      );

      return AuthResult.failure(
        'An unexpected error occurred. Please try again.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Doctor Login
  // ---------------------------------------------------------------------------

  /// Logs in a doctor using Firebase email/password authentication.
  ///
  /// The user's Firestore document must contain:
  ///
  /// ```text
  /// users/{uid}/role = doctor
  /// ```
  Future<AuthResult> loginDoctor({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      return AuthResult.failure(
        'Please enter both email and password.',
      );
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      final user = credential.user;

      if (user == null) {
        return AuthResult.failure(
          'Authentication failed. Please try again.',
        );
      }

      final profile = await _getUserProfile(user.uid);

      if (profile == null) {
        await _safeSignOut();

        return AuthResult.failure(
          'Could not verify doctor permissions. '
          'Please check your connection and try again.',
        );
      }

      final role = _readRole(profile);
      final name = _readName(profile);

      if (role != 'doctor') {
        await _safeSignOut();

        if (role == 'caregiver') {
          return AuthResult.failure(
            'This account belongs to a caregiver. '
            'Please use the caregiver login screen.',
          );
        }

        if (role == 'patient') {
          return AuthResult.failure(
            'This account belongs to a patient. '
            'Please use the patient login screen.',
          );
        }

        return AuthResult.failure(
          'This account does not have doctor access. '
          'Please use your medical credentials.',
        );
      }

      debugPrint(
        '[AuthService] Doctor login successful: ${user.uid}',
      );

      return AuthResult.success(
        uid: user.uid,
        email: user.email ?? cleanEmail,
        displayName: name ?? user.displayName ?? 'Doctor',
      );
    } on FirebaseAuthException catch (error) {
      return AuthResult.failure(
        _mapFirebaseError(error),
      );
    } catch (error) {
      debugPrint(
        '[AuthService] Unexpected doctor login error: $error',
      );

      return AuthResult.failure(
        'An unexpected error occurred. Please try again.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // User Profile and Role Helpers
  // ---------------------------------------------------------------------------

  /// Reads the Firestore user profile.
  ///
  /// Returns null when the document cannot be read.
  Future<Map<String, dynamic>?> _getUserProfile(String uid) async {
    try {
      final document = await _db.collection('users').doc(uid).get();

      if (!document.exists) {
        debugPrint(
          '[AuthService] User profile does not exist for uid: $uid',
        );
        return <String, dynamic>{};
      }

      return document.data();
    } catch (error) {
      debugPrint(
        '[AuthService] Firestore profile read error: $error',
      );

      return null;
    }
  }

  String? _readRole(Map<String, dynamic> profile) {
    final value = profile['role'];

    if (value is! String) {
      return null;
    }

    return value.trim().toLowerCase();
  }

  String? _readName(Map<String, dynamic> profile) {
    final value = profile['name'];

    if (value is! String) {
      return null;
    }

    final cleanName = value.trim();

    return cleanName.isEmpty ? null : cleanName;
  }

  // ---------------------------------------------------------------------------
  // Sign Out
  // ---------------------------------------------------------------------------

  /// Signs out the currently authenticated Firebase user.
  ///
  /// Sign-out errors are treated as non-fatal.
  Future<void> signOut() async {
    await _safeSignOut();
  }

  Future<void> _safeSignOut() async {
    try {
      await _auth.signOut();

      debugPrint(
        '[AuthService] Firebase user signed out successfully.',
      );
    } catch (error) {
      debugPrint(
        '[AuthService] Sign-out error: $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Firebase Error Mapping
  // ---------------------------------------------------------------------------

  /// Converts Firebase authentication errors into user-friendly messages.
  String _mapFirebaseError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-email':
        return 'Invalid email or password. Please check your credentials.';

      case 'user-disabled':
        return 'This account has been disabled. '
            'Contact your administrator.';

      case 'too-many-requests':
        return 'Too many failed attempts. '
            'Please wait a few minutes and try again.';

      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      case 'operation-not-allowed':
        return 'Email/password login is not enabled. '
            'Contact your administrator.';

      case 'email-already-in-use':
        return 'This email is already registered.';

      case 'weak-password':
        return 'The password is too weak. '
            'Please choose a stronger password.';

      case 'requires-recent-login':
        return 'Please sign in again to continue this action.';

      case 'invalid-api-key':
      case 'app-not-authorized':
        return 'Firebase configuration is invalid. '
            'Please contact your administrator.';

      default:
        debugPrint(
          '[AuthService] Unhandled Firebase error code: '
          '${error.code}; message: ${error.message}',
        );

        return error.message ??
            'Authentication failed. Please try again.';
    }
  }
}
````
