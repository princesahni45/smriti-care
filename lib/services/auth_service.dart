// lib/services/auth_service.dart
//
// SmritiCare — Centralized Firebase Authentication Service
//
// Responsibilities:
//  1. Caregiver email/password login via Firebase Auth
//  2. Firestore role verification: users/{uid}/role == "caregiver"
//  3. Sign out (FirebaseAuth.instance.signOut())
//  4. Expose current Firebase user
//  5. Clean FirebaseAuthException error messages
//  6. Integrates with CaregiverAuthService for mode/session state
//
// FLOW:
//  Patient Dashboard
//    → Caregiver Login Screen
//    → AuthService.loginCaregiver()
//    → Firebase Auth signInWithEmailAndPassword
//    → Firestore users/{uid} role check
//    → Success: CaregiverAuthService sets mode = caregiver
//    → Failure: returns human-readable error
//
// NOTE: Passwords are NEVER stored in Firestore.
// NOTE: Do NOT call this before Firebase.initializeApp() completes.

import "package:firebase_auth/firebase_auth.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/foundation.dart";

// Result wrapper for caregiver login
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
  }) =>
      AuthResult._(
        isSuccess: true,
        uid: uid,
        email: email,
        displayName: displayName,
      );

  factory AuthResult.failure(String message) =>
      AuthResult._(isSuccess: false, errorMessage: message);
}

/// Centralized Firebase Authentication Service for SmritiCare.
///
/// Use [AuthService.instance] to access the singleton.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// The currently signed-in Firebase user, or null.
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes. Listen to this to react to login/logout.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Caregiver Login ─────────────────────────────────────────────────────────

  /// Attempt caregiver login using Firebase Email + Password Authentication.
  ///
  /// Steps:
  /// 1. Validate inputs
  /// 2. Sign in with Firebase Auth (signInWithEmailAndPassword)
  /// 3. Read Firestore: users/{uid} → check role == "caregiver"
  /// 4. If role is not caregiver → sign out and return failure
  /// 5. If successful → return [AuthResult.success]
  ///
  /// Passwords are NEVER written to Firestore.
  Future<AuthResult> loginCaregiver({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      return AuthResult.failure("Please enter both email and password.");
    }

    try {
      // Step 1: Firebase Auth — email + password sign in
      final credential = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      final user = credential.user;
      if (user == null) {
        return AuthResult.failure("Authentication failed. Please try again.");
      }

      // Step 2: Firestore role verification — users/{uid}
      // Do NOT allow access if role is not "caregiver"
      String? role;
      String? name;
      try {
        final doc = await _db.collection("users").doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          role = (data["role"] as String?)?.trim().toLowerCase();
          name = data["name"] as String?;
        }
      } catch (firestoreError) {
        debugPrint("[AuthService] Firestore role check error: $firestoreError");
        // If Firestore is unreachable, deny access for security
        await _auth.signOut();
        return AuthResult.failure(
          "Could not verify caregiver permissions. Please check your connection.",
        );
      }

      // Step 3: Role check — must be exactly "caregiver"
      if (role == null || role != "caregiver") {
        await _auth.signOut();
        if (role == "patient") {
          return AuthResult.failure(
            "This account belongs to a patient, not a caregiver. "
            "Please use your caregiver credentials.",
          );
        }
        return AuthResult.failure(
          "This account does not have caregiver access. "
          "Contact your administrator.",
        );
      }

      // Step 4: Success
      debugPrint("[AuthService] Caregiver login success: ${user.uid}");
      return AuthResult.success(
        uid: user.uid,
        email: user.email ?? cleanEmail,
        displayName: name ?? user.displayName ?? "Caregiver",
      );
    } on FirebaseAuthException catch (e) {
      // Step 5: Clean, user-friendly error messages for all Firebase error codes
      return AuthResult.failure(_mapFirebaseError(e));
    } catch (e) {
      debugPrint("[AuthService] Unexpected login error: $e");
      return AuthResult.failure("An unexpected error occurred. Please try again.");
    }
  }

  // ── Sign Out ────────────────────────────────────────────────────────────────

  /// Sign out the current Firebase user and return to Patient Dashboard.
  ///
  /// This is called when:
  ///  - Caregiver taps "Exit Caregiver Mode"
  ///  - Caregiver switches back to Patient mode
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint("[AuthService] Caregiver signed out successfully.");
    } catch (e) {
      debugPrint("[AuthService] Sign out error (non-fatal): $e");
    }
  }

  // ── FirebaseAuthException → Human-Readable Messages ─────────────────────────

  /// Maps Firebase error codes to clean, user-friendly messages.
  /// Avoids exposing internal Firebase error codes to users.
  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case "user-not-found":
      case "wrong-password":
      case "invalid-credential":
      case "invalid-email":
        return "Invalid email or password. Please check your credentials.";
      case "user-disabled":
        return "This caregiver account has been disabled. Contact your administrator.";
      case "too-many-requests":
        return "Too many failed attempts. Please wait a few minutes and try again.";
      case "network-request-failed":
        return "Network error. Please check your internet connection.";
      case "operation-not-allowed":
        return "Email/password login is not enabled. Contact your administrator.";
      case "email-already-in-use":
        return "This email is already registered.";
      default:
        debugPrint("[AuthService] Unhandled Firebase error code: ${e.code} — ${e.message}");
        return e.message ?? "Authentication failed. Please try again.";
    }
  }
}
