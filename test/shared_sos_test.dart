// test/shared_sos_test.dart
//
// FIX: Use shared SOS contacts for caregiver and patient
//
// Tests for EmergencyService two-number configuration, format validation,
// caregiver permission control, and shared reactivity via settingsNotifier.

import 'package:flutter_test/flutter_test.dart';
import 'package:smriti_care/services/emergency_service.dart';
import 'package:smriti_care/core/services/caregiver_auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Shared SOS Contacts Tests', () {
    test('EmergencySettingsData calculates aliases and serialization correctly',
        () {
      final now = DateTime(2026, 9, 11, 12, 0);
      final settings = EmergencySettingsData(
        primaryNumber: '+91 98765 43210',
        secondaryNumber: '+91 91234 56780',
        primaryName: 'Rahul Das',
        secondaryName: 'Dr. Ananya Bora',
        primaryRelationship: 'Son',
        secondaryRelationship: 'Doctor',
        updatedAt: now,
        isCloudSynced: true,
      );

      // FIX: Use shared SOS contacts for caregiver and patient
      expect(settings.primaryPhone, equals('+91 98765 43210'));
      expect(settings.secondaryPhone, equals('+91 91234 56780'));
      expect(settings.isCloudSynced, isTrue);

      final map = settings.toMap();
      final fromMap = EmergencySettingsData.fromMap(map);

      expect(fromMap.primaryNumber, equals('+91 98765 43210'));
      expect(fromMap.primaryPhone, equals('+91 98765 43210'));
      expect(fromMap.secondaryNumber, equals('+91 91234 56780'));
      expect(fromMap.secondaryPhone, equals('+91 91234 56780'));
      expect(fromMap.primaryName, equals('Rahul Das'));
    });

    test('PhoneNumber validation and duplicate detection works correctly', () {
      expect(EmergencyService.validatePhoneNumber(''), isNotNull);
      expect(EmergencyService.validatePhoneNumber('123'), isNotNull);
      expect(EmergencyService.validatePhoneNumber('+91 98765 43210'), isNull);
      expect(EmergencyService.validatePhoneNumber('9876543210'), isNull);

      expect(
        EmergencyService.areNumbersDuplicate('+91 98765 43210', '9876543210'),
        isTrue,
      );
      expect(
        EmergencyService.areNumbersDuplicate(
            '+91 98765 43210', '+91 91234 56780'),
        isFalse,
      );
    });

    test('Patient cannot edit emergency numbers without caregiver auth',
        () async {
      final auth = CaregiverAuthService.instance;
      auth.switchToPatientMode();

      final service = EmergencyService.instance;
      final res = await service.updateEmergencyNumbers(
        primaryNumber: '+91 99999 88888',
        secondaryNumber: '+91 77777 66666',
      );

      expect(res.isSuccess, isFalse);
      expect(res.statusMessage.contains('Permission denied'), isTrue);
    });

    test('Caregiver can update emergency numbers and settingsNotifier updates',
        () async {
      final auth = CaregiverAuthService.instance;
      auth.enableTestMode();
      // Authenticate as caregiver
      await auth.loginCaregiver(
        email: 'caregiver@smriti.care',
        password: 'password123',
      );

      final service = EmergencyService.instance;
      final res = await service.updateEmergencyNumbers(
        primaryNumber: '+91 98888 77777',
        secondaryNumber: '+91 96666 55555',
        primaryName: 'Amit Das',
        secondaryName: 'Dr. Sen',
        primaryRelationship: 'Brother',
        secondaryRelationship: 'Consultant',
        patientId: 'MC-2048',
      );

      expect(res.isSuccess, isTrue);
      expect(service.primaryNumber, equals('+91 98888 77777'));
      expect(service.primaryPhone, equals('+91 98888 77777'));
      expect(service.settingsNotifier.value.primaryPhone,
          equals('+91 98888 77777'));
      expect(service.settingsNotifier.value.secondaryPhone,
          equals('+91 96666 55555'));
    });
  });
}
