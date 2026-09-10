// lib/firebase_options.dart
//
// FIX: Firebase Options — generated stub for SmritiCare.
//
// THIS FILE IS A PLACEHOLDER.
// Replace the values below with your real Firebase project configuration.
//
// HOW TO GENERATE THE REAL FILE:
// ─────────────────────────────────────────────────────────────────────────────
// Step 1: Install FlutterFire CLI
//         dart pub global activate flutterfire_cli
//
// Step 2: Log in to Firebase
//         firebase login
//
// Step 3: Configure your Flutter project
//         flutterfire configure
//
// Step 4: Select your Firebase project (smriti-care or create new)
//
// Step 5: FlutterFire will auto-generate this file with real values.
// ─────────────────────────────────────────────────────────────────────────────
//
// Until then, main.dart gracefully catches Firebase.initializeApp() failures
// and auto-enables offline test mode (caregiver@smriti.care / password123).

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Replace PLACEHOLDER values with your actual Firebase project settings
/// from: https://console.firebase.google.com → Project Settings → General
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux. '
          'Run flutterfire configure to generate new options.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ── ANDROID (replace with real values from google-services.json) ────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'PLACEHOLDER_REPLACE_WITH_REAL_API_KEY',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'smriti-care-placeholder',
    storageBucket: 'smriti-care-placeholder.appspot.com',
  );

  // ── WEB (replace with real values from Firebase Console) ───────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'PLACEHOLDER_REPLACE_WITH_REAL_API_KEY',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'smriti-care-placeholder',
    storageBucket: 'smriti-care-placeholder.appspot.com',
    authDomain: 'smriti-care-placeholder.firebaseapp.com',
  );

  // ── iOS (replace with real values from GoogleService-Info.plist) ────────────
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'PLACEHOLDER_REPLACE_WITH_REAL_API_KEY',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'smriti-care-placeholder',
    storageBucket: 'smriti-care-placeholder.appspot.com',
    iosBundleId: 'com.smriticare.smritiCare',
  );

  // ── macOS (same as iOS usually) ─────────────────────────────────────────────
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'PLACEHOLDER_REPLACE_WITH_REAL_API_KEY',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'smriti-care-placeholder',
    storageBucket: 'smriti-care-placeholder.appspot.com',
    iosBundleId: 'com.smriticare.smritiCare',
  );

  // ── Windows ─────────────────────────────────────────────────────────────────
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'PLACEHOLDER_REPLACE_WITH_REAL_API_KEY',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'smriti-care-placeholder',
    storageBucket: 'smriti-care-placeholder.appspot.com',
    authDomain: 'smriti-care-placeholder.firebaseapp.com',
  );
}
