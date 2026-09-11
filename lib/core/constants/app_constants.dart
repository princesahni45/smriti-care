// lib/core/constants/app_constants.dart
//
// Prototype demo credentials and static data ported from React authConfig.js.
//
// TODO: Replace demo authentication with secure backend authentication
// before production.

class AppConstants {
  AppConstants._();

  // ── App Identity ─────────────────────────────────────────────────────────

  static const String appName = 'Smriti Care';

  static const String appTagline =
      'AI-powered cognitive care for elderly minds.';

  static const String appVersion = '1.0.0';

  // ── API Base URLs ─────────────────────────────────────────────────────────
  //
  // Android Emulator:
  //   http://10.0.2.2:8000
  //
  // Physical Android Device over Wi-Fi:
  //   Replace the IP address with your computer's IPv4 address.
  //
  // Physical Android Device over USB:
  //   Run:
  //   adb reverse tcp:8000 tcp:8000
  //
  // Then use:
  //   http://127.0.0.1:8000
  //
  // Find your computer's IP address on Windows with:
  //   ipconfig

  static const String kApiBaseUrlAndroidEmulator =
      'http://10.0.2.2:8000';

  static const String kApiBaseUrlPhysicalDevice =
      'http://192.168.9.221:8000';

  static const String kApiBaseUrlUsbReverse =
      'http://127.0.0.1:8000';

  static const String kApiBaseUrlWeb =
      'http://localhost:8000';

  // Active API URL.
  //
  // Current configuration uses USB ADB reverse.
  // Change this when testing with another connection method.

  static const String kApiBaseUrl =
      kApiBaseUrlUsbReverse;

  // ── API Endpoint Paths ────────────────────────────────────────────────────

  static const String kEndpointHealth =
      '/health';

  static const String kEndpointMriAnalyze =
      '/api/v1/mri/analyze';

  static const String kEndpointCognitiveBatch =
      '/api/v1/cognitive/telemetry/batch';

  static const String kEndpointCognitiveRisk =
      '/api/v1/cognitive/risk-analysis';

  static const String kEndpointCognitivePredict =
      '/api/cognitive/predict';

  static const String kEndpointMriPredict =
      '/api/mri/predict';

  // ── Patient Demo Credentials ──────────────────────────────────────────────

  static const String patientEmail =
      'patient@example.com';

  static const String patientPassword =
      'Hello@123';

  static const String patientId =
      'MC-2048';

  static const String patientName =
      'Ramesh';

  static const String patientFullName =
      'Mr. Ramesh Das';

  static const int patientAge =
      72;

  static const String patientLocation =
      'Guwahati, Assam';

  static const String patientBloodGroup =
      'B+';

  static const String patientPhysician =
      'Dr. Ananya Bora';

  static const String patientDementiaLevel =
      'Moderate';

  // ── Caregiver Demo Credentials ────────────────────────────────────────────

  static const String caregiverEmail =
      'singhmohak360@gmail.com';

  static const String caregiverPassword =
      'Hello@123';

  static const String caregiverName =
      'Mohak Singh';

  static const String caregiverInitials =
      'MS';

  // ── Caregiver PIN ─────────────────────────────────────────────────────────
  //
  // Used by the prototype to protect patient-session exit.
  //
  // TODO: Store and validate the PIN securely before production.

  static const String caregiverPin =
      '1234';

  // ── Accepted Patient Email Aliases ─────────────────────────────────────────

  static const List<String> acceptedPatientEmails = [
    'patient@example.com',
    'ramesh@example.com',
    'ramesh.das@example.com',
    'rameshdas@gmail.com',
    'you@example.com',
    'singhmohak360@gmail.com',
  ];

  static const List<String> acceptedPatientPasswords = [
    'Hello@123',
    'Patient@123',
  ];

  // ── Activity Definitions ─────────────────────────────────────────────────

  static const List<Map<String, String>> activityCards = [
    {
      'id': 'brain-games',
      'title': 'Brain Games',
      'subtitle': 'Train your memory',
      'color': 'blue',
    },
    {
      'id': 'memory-activity',
      'title': 'Memory Activity',
      'subtitle': 'Practice remembering',
      'color': 'teal',
    },
    {
      'id': 'music-memories',
      'title': 'Music & Memories',
      'subtitle': 'Listen and remember',
      'color': 'violet',
    },
    {
      'id': 'talk-recall',
      'title': 'Talk & Recall',
      'subtitle': 'Talk about familiar things',
      'color': 'coral',
    },
  ];

  // ── Caregiver Statistics ──────────────────────────────────────────────────

  static const List<Map<String, String>> caregiverStats = [
    {
      'label': "Today's activity",
      'value': '42 min',
      'color': 'teal',
      'icon': 'clock',
    },
    {
      'label': 'Cognitive score',
      'value': '72 / 100',
      'color': 'violet',
      'icon': 'trending',
    },
    {
      'label': 'Medication',
      'value': '2 of 3 taken',
      'color': 'coral',
      'icon': 'pill',
    },
    {
      'label': 'Next appointment',
      'value': '12 Sep',
      'color': 'blue',
      'icon': 'calendar',
    },
  ];

  // ── Weekly Cognitive Engagement ───────────────────────────────────────────

  static const List<Map<String, dynamic>> weeklyEngagement = [
    {
      'day': 'Mon',
      'score': 58,
    },
    {
      'day': 'Tue',
      'score': 71,
    },
    {
      'day': 'Wed',
      'score': 64,
    },
    {
      'day': 'Thu',
      'score': 82,
    },
    {
      'day': 'Fri',
      'score': 76,
    },
    {
      'day': 'Sat',
      'score': 88,
    },
    {
      'day': 'Sun',
      'score': 72,
    },
  ];

  // ── Care Tasks ─────────────────────────────────────────────────────────────

  static const List<Map<String, dynamic>> careTasks = [
    {
      'task': 'Morning medicine',
      'time': '8:00 AM',
      'done': true,
    },
    {
      'task': 'Memory matching activity',
      'time': '10:30 AM',
      'done': true,
    },
    {
      'task': 'Afternoon medicine',
      'time': '2:00 PM',
      'done': false,
    },
    {
      'task': 'Evening walk',
      'time': '5:30 PM',
      'done': false,
    },
  ];
}
