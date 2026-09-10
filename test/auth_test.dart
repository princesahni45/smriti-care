// test/auth_test.dart
//
// Authentication flow tests for SmritiCare Patient/Caregiver role switching.
// Uses CaregiverAuthService test-mode accounts:
//   caregiver@smriti.care / password123  (role: caregiver)
//   patient@smriti.care   / password123  (role: patient — must be rejected)
//
// Run:  flutter test test/auth_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_care/core/services/caregiver_auth_service.dart';

void main() {
  setUpAll(() {
    CaregiverAuthService.instance.enableTestMode();
  });

  tearDown(() async {
    // Reset to patient mode + clear session after every test.
    await CaregiverAuthService.instance.exitCaregiverMode();
  });

  // ---------------------------------------------------------------------------
  test('TEST 1: App starts in patient mode by default', () {
    expect(
      CaregiverAuthService.instance.currentMode,
      DashboardMode.patient,
      reason: 'App must open in Patient mode without any login.',
    );
  });

  // ---------------------------------------------------------------------------
  test('TEST 2: Patient is not authenticated as caregiver at startup', () {
    expect(
      CaregiverAuthService.instance.isCaregiverAuthenticated,
      isFalse,
      reason: 'Caregiver session must not exist at startup.',
    );
  });

  // ---------------------------------------------------------------------------
  test('TEST 3: Correct caregiver credentials succeed', () async {
    final result = await CaregiverAuthService.instance.loginCaregiver(
      email: 'caregiver@smriti.care',
      password: 'password123',
    );
    expect(result.isSuccess, isTrue,
        reason: 'Valid caregiver credentials must authenticate successfully.');
    expect(result.errorMessage, isNull,
        reason: 'No error message on successful login.');
  });

  // ---------------------------------------------------------------------------
  test('TEST 4: Wrong password fails authentication', () async {
    final result = await CaregiverAuthService.instance.loginCaregiver(
      email: 'caregiver@smriti.care',
      password: 'wrongpassword',
    );
    expect(result.isSuccess, isFalse,
        reason: 'Wrong password must not authenticate.');
    expect(result.errorMessage, isNotNull,
        reason: 'An error message must be returned on failure.');
  });

  // ---------------------------------------------------------------------------
  test('TEST 5: Non-caregiver (patient) account is rejected', () async {
    final result = await CaregiverAuthService.instance.loginCaregiver(
      email: 'patient@smriti.care',
      password: 'password123',
    );
    expect(result.isSuccess, isFalse,
        reason: 'Patient accounts must not be allowed in caregiver mode.');
    expect(result.errorMessage, contains('caregiver access'),
        reason: 'Error message must mention caregiver access denied.');
  });

  // ---------------------------------------------------------------------------
  test('TEST 6: Mode switches to caregiver after successful authentication',
      () async {
    final result = await CaregiverAuthService.instance.loginCaregiver(
      email: 'caregiver@smriti.care',
      password: 'password123',
    );
    expect(result.isSuccess, isTrue);
    expect(CaregiverAuthService.instance.currentMode, DashboardMode.caregiver,
        reason: 'Mode must be caregiver after successful login.');
    expect(CaregiverAuthService.instance.isCaregiverAuthenticated, isTrue);
  });

  // ---------------------------------------------------------------------------
  test('TEST 7: exitCaregiverMode() returns to patient mode', () async {
    await CaregiverAuthService.instance.loginCaregiver(
      email: 'caregiver@smriti.care',
      password: 'password123',
    );
    expect(CaregiverAuthService.instance.currentMode, DashboardMode.caregiver);

    await CaregiverAuthService.instance.exitCaregiverMode();

    expect(CaregiverAuthService.instance.currentMode, DashboardMode.patient,
        reason: 'exitCaregiverMode() must return mode to patient.');
    expect(CaregiverAuthService.instance.isCaregiverAuthenticated, isFalse);
  });

  // ---------------------------------------------------------------------------
  test('TEST 8: switchToPatientMode() works from caregiver mode', () async {
    await CaregiverAuthService.instance.loginCaregiver(
      email: 'caregiver@smriti.care',
      password: 'password123',
    );
    CaregiverAuthService.instance.switchToPatientMode();
    expect(CaregiverAuthService.instance.currentMode, DashboardMode.patient,
        reason: 'switchToPatientMode() must switch mode to patient.');
  });

  // ---------------------------------------------------------------------------
  test(
      'TEST 9: switchToCaregiverModeIfAuthenticated() returns false when not logged in',
      () {
    final switched =
        CaregiverAuthService.instance.switchToCaregiverModeIfAuthenticated();
    expect(switched, isFalse,
        reason: 'Must return false if no active caregiver session exists, '
            'so the login screen is shown.');
    expect(CaregiverAuthService.instance.currentMode, DashboardMode.patient,
        reason: 'Mode must remain patient when no session is active.');
  });

  // ---------------------------------------------------------------------------
  test(
      'TEST 10: switchToCaregiverModeIfAuthenticated() returns true when session is active',
      () async {
    // Login to establish a session.
    await CaregiverAuthService.instance.loginCaregiver(
      email: 'caregiver@smriti.care',
      password: 'password123',
    );
    // Drop to patient WITHOUT clearing session.
    CaregiverAuthService.instance.switchToPatientMode();
    expect(CaregiverAuthService.instance.currentMode, DashboardMode.patient);

    // Now try the fast-switch (session still active).
    final switched =
        CaregiverAuthService.instance.switchToCaregiverModeIfAuthenticated();
    expect(switched, isTrue,
        reason: 'Must return true and skip login when session already exists.');
    expect(CaregiverAuthService.instance.currentMode, DashboardMode.caregiver);
  });
}
