```dart
// lib/app.dart
//
// Root app widget with go_router navigation.
// Launches directly into the SmritiCare Mobile Dashboard with Bottom Navigation.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'screens/main_shell_screen.dart';
import 'screens/placeholder_screen.dart';
import 'screens/language_select_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/role_selection_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/caregiver_login_screen.dart';
import 'features/auth/register_screen.dart';
import 'core/services/caregiver_auth_service.dart';

import 'features/patient/patient_dashboard_screen.dart';
import 'features/caregiver/caregiver_dashboard_screen.dart';
import 'features/patient/caregiver_confirmation_screen.dart';
import 'features/patient/patient_profile_screen.dart';
import 'features/patient/patient_reminders_screen.dart';
import 'features/patient/patient_progress_screen.dart';

import 'features/games/games_hub_screen.dart';
import 'features/games/memory_match/memory_match_screen.dart';
import 'features/games/word_recall/word_recall_screen.dart';
import 'features/games/different_object/different_object_screen.dart';
import 'features/games/orientation/day_time_orientation_screen.dart';
import 'features/games/routine/routine_sequence_screen.dart';
import 'features/games/family_memories/family_memories_game_screen.dart';

import 'features/mri/mri_screening_screen.dart';
import 'features/emergency/take_me_home_screen.dart';
import 'features/assessment/cognitive_assessment_screen.dart';

import 'features/auth/doctor_login_screen.dart';
import 'features/doctor/doctor_dashboard_screen.dart';
import 'features/doctor/screens/patient_clinical_overview_screen.dart';

import 'core/voice/voice.dart';

GoRouter createAppRouter({
  String initialLocation = '/',
  List<NavigatorObserver>? observers,
}) =>
    GoRouter(
      initialLocation: initialLocation,
      debugLogDiagnostics: false,
      observers: [
        VoiceRouteTracker.instance,
        if (observers != null) ...observers,
      ],
      routes: [
        // ── Primary Entry Point: SmritiCare Mobile Dashboard Shell
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const MainShellScreen(),
        ),

        // ── Dedicated Dashboard Route
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const MainShellScreen(initialTab: 0),
        ),

        // ── Dynamic Placeholder Route for Upcoming Modules
        GoRoute(
          path: '/placeholder/:moduleId',
          name: 'placeholder',
          builder: (context, state) {
            final moduleId =
                state.pathParameters['moduleId'] ?? 'general';

            return PlaceholderScreen.forModule(
              moduleId,
              onBack: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go('/');
                }
              },
            );
          },
        ),

        // ── Prototype Splash
        GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),

        // ── Role Selection
        GoRoute(
          path: '/role-select',
          name: 'roleSelect',
          builder: (context, state) => const RoleSelectionScreen(),
        ),

        // ── Login
        GoRoute(
          path: '/login/:role',
          name: 'login',
          builder: (context, state) {
            final role = state.pathParameters['role'] ?? 'patient';

            return LoginScreen(role: role);
          },
        ),

        // ── Register
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),

        // ── Patient Dashboard
        GoRoute(
          path: '/patient-dashboard',
          name: 'patientDashboard',
          builder: (context, state) => const PatientDashboardScreen(),
        ),

        // ── Caregiver Dashboard
        GoRoute(
          path: '/caregiver-dashboard',
          name: 'caregiverDashboard',
          builder: (context, state) => const CaregiverDashboardScreen(),
        ),

        // ── Caregiver Login
        GoRoute(
          path: '/caregiver-login',
          name: 'caregiverLogin',
          builder: (context, state) => CaregiverLoginScreen(
            onSuccess: () => context.go('/caregiver'),
            onCancel: () => context.go('/dashboard'),
          ),
        ),

        // ── Caregiver Dashboard (auth guarded)
        GoRoute(
          path: '/caregiver',
          name: 'caregiver',
          redirect: (context, state) {
            if (!CaregiverAuthService.instance.isCaregiverAuthenticated) {
              return '/dashboard';
            }

            return null;
          },
          builder: (context, state) => CaregiverDashboardScreen(
            onBackToPatient: () {
              CaregiverAuthService.instance.exitCaregiverMode();
              context.go('/dashboard');
            },
          ),
        ),

        // ── Cognitive Games
        GoRoute(
          path: '/games',
          name: 'gamesHub',
          builder: (context, state) => const GamesHubScreen(),
        ),

        GoRoute(
          path: '/games/memory-match',
          name: 'memoryMatch',
          builder: (context, state) => const MemoryMatchScreen(),
        ),

        GoRoute(
          path: '/games/word-recall',
          name: 'wordRecall',
          builder: (context, state) => const WordRecallScreen(),
        ),

        GoRoute(
          path: '/games/different-object',
          name: 'differentObject',
          builder: (context, state) => const DifferentObjectScreen(),
        ),

        GoRoute(
          path: '/games/orientation',
          name: 'dayTimeOrientation',
          builder: (context, state) => const DayTimeOrientationScreen(),
        ),

        GoRoute(
          path: '/games/routine',
          name: 'routineSequence',
          builder: (context, state) => const RoutineSequenceScreen(),
        ),

        GoRoute(
          path: '/games/family-memories',
          name: 'familyMemories',
          builder: (context, state) => const FamilyMemoriesGameScreen(),
        ),

        // ── MRI Screening (Caregiver-only)
        GoRoute(
          path: '/mri-screening',
          name: 'mriScreening',
          redirect: (context, state) {
            if (!CaregiverAuthService.instance.isCaregiverAuthenticated) {
              return '/caregiver-login';
            }

            return null;
          },
          builder: (context, state) => const MriScreeningScreen(),
        ),

        // ── Take Me Home & Emergency SOS
        GoRoute(
          path: '/take-me-home',
          name: 'takeMeHome',
          builder: (context, state) => const TakeMeHomeScreen(),
        ),

        GoRoute(
          path: '/emergency',
          name: 'emergency',
          builder: (context, state) => const TakeMeHomeScreen(),
        ),

        // ── Cognitive Assessment
        GoRoute(
          path: '/assessment',
          name: 'assessment',
          builder: (context, state) => const CognitiveAssessmentScreen(),
        ),

        // ── Caregiver Call Confirmation
        GoRoute(
          path: '/caregiver-confirm',
          name: 'caregiverConfirm',
          builder: (context, state) => const CaregiverConfirmationScreen(),
        ),

        // ── Doctor Login
        GoRoute(
          path: '/doctor-login',
          name: 'doctorLogin',
          builder: (context, state) => DoctorLoginScreen(
            onSuccess: () => context.go('/doctor'),
            onCancel: () => context.go('/dashboard'),
          ),
        ),

        // ── Doctor Dashboard (auth guarded)
        GoRoute(
          path: '/doctor',
          name: 'doctor',
          redirect: (context, state) {
            if (!CaregiverAuthService.instance.isDoctorAuthenticated) {
              return '/doctor-login';
            }

            return null;
          },
          builder: (context, state) => DoctorDashboardScreen(
            onBackToPatient: () {
              CaregiverAuthService.instance.exitDoctorMode();
              context.go('/dashboard');
            },
          ),
        ),

        // ── Doctor Patient Clinical Overview
        GoRoute(
          path: '/doctor/patient/:id',
          name: 'doctorPatientOverview',
          redirect: (context, state) {
            if (!CaregiverAuthService.instance.isDoctorAuthenticated) {
              return '/doctor-login';
            }

            return null;
          },
          builder: (context, state) {
            final patientId = state.pathParameters['id'] ?? '';

            return PatientClinicalOverviewScreen(
              patientId: patientId,
            );
          },
        ),

        // ── Patient Profile
        GoRoute(
          path: '/patient-profile',
          name: 'patientProfile',
          builder: (context, state) => const PatientProfileScreen(),
        ),

        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const PatientProfileScreen(),
        ),

        // ── Patient Reminders
        GoRoute(
          path: '/reminders',
          name: 'reminders',
          builder: (context, state) => const PatientRemindersScreen(),
        ),

        // ── Patient Progress
        GoRoute(
          path: '/progress',
          name: 'progress',
          builder: (context, state) => const PatientProgressScreen(),
        ),

        // ── Language Selection
        GoRoute(
          path: '/language-select',
          name: 'languageSelect',
          builder: (context, state) => const LanguageSelectScreen(),
        ),
      ],
    );

class SmritiCareApp extends StatefulWidget {
  final GoRouter? router;

  const SmritiCareApp({
    super.key,
    this.router,
  });

  @override
  State<SmritiCareApp> createState() => _SmritiCareAppState();
}

class _SmritiCareAppState extends State<SmritiCareApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = widget.router ?? createAppRouter();
  }

  @override
  void dispose() {
    if (widget.router == null) {
      _router.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable:
          LocalizationService.instance.currentLocaleNotifier,
      builder: (context, currentLocale, _) {
        return MaterialApp.router(
          title: 'Smriti Care',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: _router,
          locale: currentLocale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            AppLocalizations.fallbackMaterialDelegate,
            AppLocalizations.fallbackCupertinoDelegate,
          ],
          builder: (context, child) => GlobalPatientVoiceAssistant(
            onNavigate: (route, {arguments}) {
              if (route == '..' || route == 'pop') {
                if (_router.canPop()) {
                  _router.pop();
                } else {
                  _router.go('/dashboard');
                }
              } else {
                _router.go(route);
              }
            },
            child: child,
          ),
        );
      },
    );
  }
}
```
