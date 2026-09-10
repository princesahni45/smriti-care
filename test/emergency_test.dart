// test/emergency_test.dart
//
// Unit tests for SmritiCare Emergency SOS & Contacts System:
// - Primary & Secondary emergency number configuration
// - Validation & duplicate checking
// - Caregiver edit permissions vs Patient edit denial
// - Offline local storage persistence
// - Structured SOS message generation (Lat, Lng, Accuracy, Timestamp, Maps URL)

import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_care/core/services/caregiver_auth_service.dart';
import 'package:smriti_care/services/emergency_service.dart';
import 'package:smriti_care/services/location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await EmergencyService.instance.init();
    await CaregiverAuthService.instance.exitCaregiverMode(); // default to patient mode
  });

  tearDown(() async {
    await CaregiverAuthService.instance.exitCaregiverMode();
  });

  // ---------------------------------------------------------------------------
  test('TEST 1: Unauthenticated Patient cannot edit emergency numbers', () async {
    expect(CaregiverAuthService.instance.isCaregiverAuthenticated, isFalse);

    final result = await EmergencyService.instance.updateEmergencyNumbers(
      primaryNumber: '+91 99999 11111',
      secondaryNumber: '+91 88888 22222',
    );

    expect(result.isSuccess, isFalse, reason: 'Patient mode must be denied permission to edit numbers.');
    expect(result.statusMessage, contains('Permission denied'));
  });

  // ---------------------------------------------------------------------------
  test('TEST 2: Authenticated Caregiver can edit primary and secondary numbers', () async {
    CaregiverAuthService.instance.enableTestMode();
    final login = await CaregiverAuthService.instance.loginCaregiver(
      email: 'caregiver@smriti.care',
      password: 'password123',
    );
    expect(login.isSuccess, isTrue);
    expect(CaregiverAuthService.instance.isCaregiverAuthenticated, isTrue);

    final result = await EmergencyService.instance.updateEmergencyNumbers(
      primaryNumber: '+91 98765 43210',
      secondaryNumber: '+91 91234 56780',
      primaryName: 'Rahul Das',
      secondaryName: 'Dr. Ananya Bora',
    );

    expect(result.isSuccess, isTrue, reason: 'Caregiver must be permitted to save emergency numbers.');
    expect(result.isLocalSaved, isTrue, reason: 'Must be saved locally on device.');
    expect(EmergencyService.instance.primaryNumber, '+91 98765 43210');
    expect(EmergencyService.instance.secondaryNumber, '+91 91234 56780');
  });

  // ---------------------------------------------------------------------------
  test('TEST 3: Phone number validation rejects empty and invalid numbers', () {
    expect(EmergencyService.validatePhoneNumber(''), isNotNull);
    expect(EmergencyService.validatePhoneNumber('   '), isNotNull);
    expect(EmergencyService.validatePhoneNumber('abc123'), isNotNull);
    expect(EmergencyService.validatePhoneNumber('123'), isNotNull); // too short

    // Valid formats
    expect(EmergencyService.validatePhoneNumber('+91 98765 43210'), isNull);
    expect(EmergencyService.validatePhoneNumber('9876543210'), isNull);
    expect(EmergencyService.validatePhoneNumber('+1 (555) 234-5678'), isNull);
  });

  // ---------------------------------------------------------------------------
  test('TEST 4: Duplicate numbers are correctly detected', () {
    expect(
      EmergencyService.areNumbersDuplicate('+91 98765 43210', '+91 98765 43210'),
      isTrue,
      reason: 'Identical numbers must be flagged as duplicate.',
    );
    expect(
      EmergencyService.areNumbersDuplicate('9876543210', '+91 98765 43210'),
      isTrue,
      reason: 'Normalized digits must match.',
    );
    expect(
      EmergencyService.areNumbersDuplicate('+91 98765 43210', '+91 91234 56780'),
      isFalse,
      reason: 'Different numbers must not be flagged.',
    );
  });

  // ---------------------------------------------------------------------------
  test('TEST 5: SOS emergency message builder formats coordinates and map link', () {
    final loc = SosLocation(
      latitude: 26.1856,
      longitude: 91.7539,
      accuracy: 12.4,
      timestamp: DateTime(2026, 9, 11, 3, 20),
      isLastKnown: false,
    );

    final msg = EmergencyService.instance.buildSosMessage(
      location: loc,
      patientName: 'Mr. Ramesh Das',
    );

    expect(msg, contains('EMERGENCY SOS from SmritiCare.'));
    expect(msg, contains('Mr. Ramesh Das'));
    expect(msg, contains('26.185600'));
    expect(msg, contains('91.753900'));
    expect(msg, contains('12.4m'));
    expect(msg, contains('https://maps.google.com/?q=26.1856,91.7539'));
  });

  // ---------------------------------------------------------------------------
  test('TEST 6: SOS emergency message labels Last Known Location correctly', () {
    final loc = SosLocation(
      latitude: 28.6139,
      longitude: 77.2090,
      accuracy: 25.0,
      timestamp: DateTime(2026, 9, 11, 2, 45),
      isLastKnown: true,
    );

    final msg = EmergencyService.instance.buildSosMessage(
      location: loc,
    );

    expect(msg, contains('Last Known Location'));
    expect(msg, contains('28.613900'));
  });
}
