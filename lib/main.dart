// lib/main.dart
//
// App entry point.

import 'package:flutter/material.dart';
// FIX: Firebase initialization added here
import 'package:firebase_core/firebase_core.dart';
// FIX: Import DefaultFirebaseOptions for proper platform-aware Firebase config
import 'firebase_options.dart';
import 'core/services/caregiver_auth_service.dart';
import 'core/localization/app_localizations.dart';
import 'app.dart';

// FIX: main() made async to allow awaiting Firebase.initializeApp()
Future<void> main() async {
  // FIX: ensureInitialized() must be called before any async native code
  WidgetsFlutterBinding.ensureInitialized();

  // FIX: Initialize Firebase BEFORE runApp().
  // Gracefully handles both native Android initialization and Dart initialization.
  // When placeholder options are detected, enables offline test mode so the app
  // runs smoothly without network failures on device.
  bool firebaseReady = false;
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    if (DefaultFirebaseOptions.currentPlatform.apiKey
        .startsWith('PLACEHOLDER')) {
      debugPrint(
          '[SmritiCare] Placeholder Firebase detected — running in offline test mode.');
    } else {
      firebaseReady = true;
      debugPrint('[SmritiCare] Firebase initialized successfully.');
    }
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      if (!DefaultFirebaseOptions.currentPlatform.apiKey
          .startsWith('PLACEHOLDER')) {
        firebaseReady = true;
        debugPrint(
            '[SmritiCare] Firebase [DEFAULT] app already initialized natively.');
      } else {
        debugPrint(
            '[SmritiCare] Native Firebase placeholder detected — running in offline test mode.');
      }
    } else {
      debugPrint('[SmritiCare] Firebase initialization notice: $e');
    }
  } catch (e) {
    debugPrint(
        '[SmritiCare] Firebase not configured — using offline test mode. ($e)');
  }

  // FIX: Tell CaregiverAuthService whether Firebase is available.
  // When firebaseReady == false the service auto-enables test-mode credentials
  // so caregiver login works reliably without a live Firebase backend.
  if (!firebaseReady) {
    CaregiverAuthService.instance.enableTestMode();
  }

  // Load persisted regional language preference
  await LocalizationService.instance.init();

  runApp(const SmritiCareApp());
}
