// lib/core/models/caregiver_models.dart
//
// Data models for the SmritiCare Caregiver Portal.
// Faithful to the web implementation in src/App.jsx, src/reminders/, and src/emergency/.

import 'dart:convert';

/// Patient Profile represented in the Caregiver Portal
class PatientProfile {
  final String id;
  final String fullName;
  final int age;
  final String location;
  final String bloodGroup;
  final String physician;
  final String dementiaLevel;
  final String primaryLanguage;
  final String avatarInitials;
  final DateTime lastUpdated;

  const PatientProfile({
    required this.id,
    required this.fullName,
    required this.age,
    required this.location,
    required this.bloodGroup,
    required this.physician,
    required this.dementiaLevel,
    required this.primaryLanguage,
    required this.avatarInitials,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'age': age,
      'location': location,
      'bloodGroup': bloodGroup,
      'physician': physician,
      'dementiaLevel': dementiaLevel,
      'primaryLanguage': primaryLanguage,
      'avatarInitials': avatarInitials,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory PatientProfile.fromMap(Map<String, dynamic> map) {
    return PatientProfile(
      id: map['id'] ?? 'MC-2048',
      fullName: map['fullName'] ?? 'Mr. Ramesh Das',
      age: map['age'] ?? 72,
      location: map['location'] ?? 'Guwahati, Assam',
      bloodGroup: map['bloodGroup'] ?? 'B+',
      physician: map['physician'] ?? 'Dr. Ananya Bora',
      dementiaLevel: map['dementiaLevel'] ?? 'Moderate',
      primaryLanguage: map['primaryLanguage'] ?? 'English',
      avatarInitials: map['avatarInitials'] ?? 'RD',
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.tryParse(map['lastUpdated']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Caregiver Profile
class CaregiverProfile {
  final String name;
  final String email;
  final String initials;
  final String role;
  final String connectedPatientId;

  const CaregiverProfile({
    required this.name,
    required this.email,
    required this.initials,
    required this.role,
    required this.connectedPatientId,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'initials': initials,
      'role': role,
      'connectedPatientId': connectedPatientId,
    };
  }

  factory CaregiverProfile.fromMap(Map<String, dynamic> map) {
    return CaregiverProfile(
      name: map['name'] ?? 'Mohak Singh',
      email: map['email'] ?? 'singhmohak360@gmail.com',
      initials: map['initials'] ?? 'MS',
      role: map['role'] ?? 'Caregiver',
      connectedPatientId: map['connectedPatientId'] ?? 'MC-2048',
    );
  }
}

/// Caregiver Reminder model matching reminderModel.js & mockReminders.js
class CaregiverReminder {
  final String id;
  final String patientId;
  final String type; // medication, hydration, appointment, cognitive_activity, daily_routine
  final String title;
  final String message;
  final String scheduledTime; // e.g. '09:00 AM'
  final String repeat; // daily, weekdays, weekends, once
  final bool enabled;
  final String status; // acknowledged, upcoming, not_acknowledged
  final DateTime? acknowledgedAt;

  const CaregiverReminder({
    required this.id,
    required this.patientId,
    required this.type,
    required this.title,
    required this.message,
    required this.scheduledTime,
    required this.repeat,
    required this.enabled,
    required this.status,
    this.acknowledgedAt,
  });

  CaregiverReminder copyWith({
    String? id,
    String? patientId,
    String? type,
    String? title,
    String? message,
    String? scheduledTime,
    String? repeat,
    bool? enabled,
    String? status,
    DateTime? acknowledgedAt,
  }) {
    return CaregiverReminder(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      repeat: repeat ?? this.repeat,
      enabled: enabled ?? this.enabled,
      status: status ?? this.status,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'type': type,
      'title': title,
      'message': message,
      'scheduledTime': scheduledTime,
      'repeat': repeat,
      'enabled': enabled,
      'status': status,
      'acknowledgedAt': acknowledgedAt?.toIso8601String(),
    };
  }

  factory CaregiverReminder.fromMap(Map<String, dynamic> map) {
    return CaregiverReminder(
      id: map['id'] ?? 'rem_',
      patientId: map['patientId'] ?? 'MC-2048',
      type: map['type'] ?? 'daily_routine',
      title: map['title'] ?? 'Scheduled Reminder',
      message: map['message'] ?? '',
      scheduledTime: map['scheduledTime'] ?? '09:00 AM',
      repeat: map['repeat'] ?? 'daily',
      enabled: map['enabled'] ?? true,
      status: map['status'] ?? 'upcoming',
      acknowledgedAt: map['acknowledgedAt'] != null
          ? DateTime.tryParse(map['acknowledgedAt'])
          : null,
    );
  }
}

/// Primary Caregiver Emergency Contact matching emergencyContactService.js
class EmergencyContact {
  final String name;
  final String relationship;
  final String phone;
  final String secondaryPhone;
  final DateTime updatedAt;

  const EmergencyContact({
    required this.name,
    required this.relationship,
    required this.phone,
    required this.secondaryPhone,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'relationship': relationship,
      'phone': phone,
      'secondaryPhone': secondaryPhone,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      name: map['name'] ?? 'Rahul Das',
      relationship: map['relationship'] ?? 'Son',
      phone: map['phone'] ?? '+91 98765 43210',
      secondaryPhone: map['secondaryPhone'] ?? '+91 98765 01234',
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Safe Home Location for Take Me Home matching emergencyContactService.js
class HomeLocation {
  final String address;
  final double latitude;
  final double longitude;
  final DateTime updatedAt;

  const HomeLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory HomeLocation.fromMap(Map<String, dynamic> map) {
    return HomeLocation(
      address: map['address'] ?? 'Ambari, Guwahati, Assam',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 26.1856,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 91.7539,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// National Emergency Response configuration
class EmergencyConfig {
  final String emergencyNumber;
  final String label;
  final String country;

  const EmergencyConfig({
    required this.emergencyNumber,
    required this.label,
    required this.country,
  });

  Map<String, dynamic> toMap() {
    return {
      'emergencyNumber': emergencyNumber,
      'label': label,
      'country': country,
    };
  }

  factory EmergencyConfig.fromMap(Map<String, dynamic> map) {
    return EmergencyConfig(
      emergencyNumber: map['emergencyNumber'] ?? '112',
      label: map['label'] ?? 'National Emergency Response Support System',
      country: map['country'] ?? 'India',
    );
  }
}

/// Caregiver notification alert item
class CaregiverAlert {
  final String id;
  final String type; // 'missed_reminder', 'emergency_sos', 'routine'
  final String title;
  final String message;
  final DateTime timestamp;
  final bool acknowledged;

  const CaregiverAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.acknowledged = false,
  });

  CaregiverAlert copyWith({bool? acknowledged}) {
    return CaregiverAlert(
      id: id,
      type: type,
      title: title,
      message: message,
      timestamp: timestamp,
      acknowledged: acknowledged ?? this.acknowledged,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'acknowledged': acknowledged,
    };
  }

  factory CaregiverAlert.fromMap(Map<String, dynamic> map) {
    return CaregiverAlert(
      id: map['id'] ?? '',
      type: map['type'] ?? 'routine',
      title: map['title'] ?? 'Alert',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      acknowledged: map['acknowledged'] ?? false,
    );
  }
}

/// Caregiver Activity Stream Item
class CaregiverActivityItem {
  final String title;
  final String subtitle;
  final String timeAgo;
  final String iconType; // 'game', 'medication', 'walk', 'water', 'alert'
  final bool isCompleted;

  const CaregiverActivityItem({
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    required this.iconType,
    required this.isCompleted,
  });
}
