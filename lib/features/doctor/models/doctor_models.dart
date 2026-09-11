// lib/features/doctor/models/doctor_models.dart
//
// Data models for the SmritiCare Doctor Portal.
// Enforces:
// 1. One Doctor to Many Patients relationship via DoctorPatientLink.
// 2. Strict privacy: doctor only accesses authorized patients.
// 3. Clear disclaimers for self-registered credentials and AI screenings.

import 'package:flutter/material.dart';

// FIX: Added doctor role support - DoctorProfile model
class DoctorProfile {
  final String doctorId;
  final String name;
  final String email;
  final String phone;
  final String specialization;
  final String hospitalOrClinic;
  final String registrationNumber;
  final String? profilePhoto;
  final DateTime createdAt;
  final bool isVerified; // Medical credential verification status

  const DoctorProfile({
    required this.doctorId,
    required this.name,
    required this.email,
    required this.phone,
    required this.specialization,
    required this.hospitalOrClinic,
    required this.registrationNumber,
    this.profilePhoto,
    required this.createdAt,
    this.isVerified = false,
  });

  String get verificationDisclaimer => isVerified
      ? 'Credential verified by health authority.'
      : 'Self-registered medical practitioner. Official institutional verification pending.';

  Map<String, dynamic> toMap() => {
    'doctorId': doctorId,
    'name': name,
    'email': email,
    'phone': phone,
    'specialization': specialization,
    'hospitalOrClinic': hospitalOrClinic,
    'registrationNumber': registrationNumber,
    'profilePhoto': profilePhoto,
    'createdAt': createdAt.toIso8601String(),
    'isVerified': isVerified,
  };

  factory DoctorProfile.fromMap(Map<String, dynamic> map) => DoctorProfile(
    doctorId: map['doctorId'] ?? 'DOC-001',
    name: map['name'] ?? 'Dr. Ananya Bora',
    email: map['email'] ?? 'doctor@smriti.care',
    phone: map['phone'] ?? '+91 98765 11223',
    specialization: map['specialization'] ?? 'Neurologist & Dementia Specialist',
    hospitalOrClinic: map['hospitalOrClinic'] ?? 'Guwahati Neurological Institute',
    registrationNumber: map['registrationNumber'] ?? 'NMC-2018-094827',
    profilePhoto: map['profilePhoto'],
    createdAt: map['createdAt'] != null
        ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
        : DateTime.now(),
    isVerified: map['isVerified'] == true,
  );

  factory DoctorProfile.defaultProfile() => DoctorProfile(
    doctorId: 'DOC-001',
    name: 'Dr. Ananya Bora',
    email: 'doctor@smriti.care',
    phone: '+91 98765 11223',
    specialization: 'Neurologist & Dementia Specialist',
    hospitalOrClinic: 'Guwahati Neurological Institute',
    registrationNumber: 'NMC-2018-094827',
    createdAt: DateTime(2025, 1, 15),
    isVerified: false,
  );
}

// FIX: Added secure doctor-patient linking - DoctorPatientLink relationship
enum DoctorLinkStatus {
  pending,
  approved,
  revoked;

  static DoctorLinkStatus fromString(String value) {
    switch (value.toLowerCase().trim()) {
      case 'approved':
        return DoctorLinkStatus.approved;
      case 'revoked':
        return DoctorLinkStatus.revoked;
      default:
        return DoctorLinkStatus.pending;
    }
  }
}

class DoctorPatientLink {
  final String linkId;
  final String doctorId;
  final String patientId;
  final DoctorLinkStatus status;
  final String linkCode;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? revokedAt;
  final String? notes;

  const DoctorPatientLink({
    required this.linkId,
    required this.doctorId,
    required this.patientId,
    required this.status,
    required this.linkCode,
    required this.createdAt,
    this.approvedAt,
    this.revokedAt,
    this.notes,
  });

  bool get isApproved => status == DoctorLinkStatus.approved;
  bool get isPending => status == DoctorLinkStatus.pending;
  bool get isRevoked => status == DoctorLinkStatus.revoked;

  DoctorPatientLink copyWith({
    DoctorLinkStatus? status,
    DateTime? approvedAt,
    DateTime? revokedAt,
    String? notes,
  }) => DoctorPatientLink(
    linkId: linkId,
    doctorId: doctorId,
    patientId: patientId,
    status: status ?? this.status,
    linkCode: linkCode,
    createdAt: createdAt,
    approvedAt: approvedAt ?? this.approvedAt,
    revokedAt: revokedAt ?? this.revokedAt,
    notes: notes ?? this.notes,
  );

  Map<String, dynamic> toMap() => {
    'linkId': linkId,
    'doctorId': doctorId,
    'patientId': patientId,
    'status': status.name,
    'linkCode': linkCode,
    'createdAt': createdAt.toIso8601String(),
    'approvedAt': approvedAt?.toIso8601String(),
    'revokedAt': revokedAt?.toIso8601String(),
    'notes': notes,
  };

  factory DoctorPatientLink.fromMap(Map<String, dynamic> map) => DoctorPatientLink(
    linkId: map['linkId'] ?? '',
    doctorId: map['doctorId'] ?? '',
    patientId: map['patientId'] ?? '',
    status: DoctorLinkStatus.fromString(map['status'] ?? 'pending'),
    linkCode: map['linkCode'] ?? '',
    createdAt: map['createdAt'] != null
        ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
        : DateTime.now(),
    approvedAt: map['approvedAt'] != null
        ? DateTime.tryParse(map['approvedAt'])
        : null,
    revokedAt: map['revokedAt'] != null
        ? DateTime.tryParse(map['revokedAt'])
        : null,
    notes: map['notes'],
  );
}

// FIX: Added multi-patient doctor dashboard - DoctorNote model
class DoctorNote {
  final String noteId;
  final String doctorId;
  final String doctorName;
  final String patientId;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DoctorNote({
    required this.noteId,
    required this.doctorId,
    required this.doctorName,
    required this.patientId,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
  });

  DoctorNote copyWith({
    String? text,
    DateTime? updatedAt,
  }) => DoctorNote(
    noteId: noteId,
    doctorId: doctorId,
    doctorName: doctorName,
    patientId: patientId,
    text: text ?? this.text,
    createdAt: createdAt,
    updatedAt: updatedAt ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'noteId': noteId,
    'doctorId': doctorId,
    'doctorName': doctorName,
    'patientId': patientId,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory DoctorNote.fromMap(Map<String, dynamic> map) => DoctorNote(
    noteId: map['noteId'] ?? '',
    doctorId: map['doctorId'] ?? '',
    doctorName: map['doctorName'] ?? 'Doctor',
    patientId: map['patientId'] ?? '',
    text: map['text'] ?? '',
    createdAt: map['createdAt'] != null
        ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
        : DateTime.now(),
    updatedAt: map['updatedAt'] != null
        ? DateTime.tryParse(map['updatedAt']) ?? DateTime.now()
        : DateTime.now(),
  );
}

// FIX: Added deterministic Attention Indicator logic
enum PatientAttentionLevel {
  stable,
  monitor,
  reviewSuggested,
  insufficientData,
}

class PatientAttentionStatus {
  final PatientAttentionLevel level;
  final String label;
  final String reason;
  final Color color;
  final IconData icon;

  const PatientAttentionStatus({
    required this.level,
    required this.label,
    required this.reason,
    required this.color,
    required this.icon,
  });

  factory PatientAttentionStatus.stable({String reason = 'Cognitive performance is consistent with baseline.'}) =>
      PatientAttentionStatus(
        level: PatientAttentionLevel.stable,
        label: 'Stable',
        reason: reason,
        color: const Color(0xFF2E7D32),
        icon: Icons.check_circle_outline_rounded,
      );

  factory PatientAttentionStatus.monitor({required String reason}) =>
      PatientAttentionStatus(
        level: PatientAttentionLevel.monitor,
        label: 'Monitor',
        reason: reason,
        color: const Color(0xFFE65100),
        icon: Icons.info_outline_rounded,
      );

  factory PatientAttentionStatus.reviewSuggested({required String reason}) =>
      PatientAttentionStatus(
        level: PatientAttentionLevel.reviewSuggested,
        label: 'Review Suggested',
        reason: reason,
        color: const Color(0xFFC62828),
        icon: Icons.warning_amber_rounded,
      );

  factory PatientAttentionStatus.insufficientData({String reason = 'Not enough assessment data yet to determine trend.'}) =>
      PatientAttentionStatus(
        level: PatientAttentionLevel.insufficientData,
        label: 'Insufficient Data',
        reason: reason,
        color: const Color(0xFF757575),
        icon: Icons.help_outline_rounded,
      );
}

// FIX: Added smart doctor alerts based on real data
class DoctorSmartAlert {
  final String id;
  final String patientId;
  final String patientName;
  final String title;
  final String message;
  final String type; // 'score_drop', 'mri_pending', 'sos_trigger', 'routine_change'
  final DateTime timestamp;
  final bool isRead;

  const DoctorSmartAlert({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  DoctorSmartAlert copyWith({bool? isRead}) => DoctorSmartAlert(
    id: id,
    patientId: patientId,
    patientName: patientName,
    title: title,
    message: message,
    type: type,
    timestamp: timestamp,
    isRead: isRead ?? this.isRead,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'patientId': patientId,
    'patientName': patientName,
    'title': title,
    'message': message,
    'type': type,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
  };

  factory DoctorSmartAlert.fromMap(Map<String, dynamic> map) => DoctorSmartAlert(
    id: map['id'] ?? '',
    patientId: map['patientId'] ?? '',
    patientName: map['patientName'] ?? 'Patient',
    title: map['title'] ?? 'Clinical Alert',
    message: map['message'] ?? '',
    type: map['type'] ?? 'general',
    timestamp: map['timestamp'] != null
        ? DateTime.tryParse(map['timestamp']) ?? DateTime.now()
        : DateTime.now(),
    isRead: map['isRead'] == true,
  );
}
