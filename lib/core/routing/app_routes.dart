// lib/core/routing/app_routes.dart
//
// Central route path constants for MindCare NER.

class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String dashboard = '/dashboard';
  static const String placeholder = '/placeholder/:moduleId';
  static const String splash = '/splash';
  static const String roleSelect = '/role-select';
  static const String login = '/login/:role';
  static const String register = '/register';
  static const String patientDashboard = '/patient-dashboard';
  static const String caregiverDashboard = '/caregiver-dashboard';

  // Games
  static const String gamesHub = '/games';
  static const String memoryMatch = '/games/memory-match';
  static const String wordRecall = '/games/word-recall';
  static const String differentObject = '/games/different-object';

  // Planned Features
  static const String reminders = '/reminders';
  static const String voiceAssistant = '/voice-assistant';
  static const String safetySos = '/safety/sos';
  static const String safeReturn = '/safety/safe-return';
}
