// lib/core/errors/app_exceptions.dart
//
// Core exception definitions for MindCare NER.

class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException(this.message, {this.code, this.details});

  @override
  String toString() => 'AppException: [$code] $message';
}

class StorageException extends AppException {
  const StorageException(super.message, {super.code, super.details});
}

class ServiceUnavailableException extends AppException {
  const ServiceUnavailableException(super.message, {super.code, super.details});
}

class SafetyException extends AppException {
  const SafetyException(super.message, {super.code, super.details});
}
