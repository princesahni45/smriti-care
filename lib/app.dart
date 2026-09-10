// lib/app.dart
//
// Root app widget with go_router navigation.
// Launches directly into the SmritiCare Mobile Dashboard with Bottom Navigation.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'screens/main_shell_screen.dart';
import 'screens/placeholder_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/role_selection_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/patient/patient_dashboard_screen.dart';
import 'features/caregiver/caregiver_dashboard_screen.dart';
import 'features/games/games_hub_screen.dart';
import 'features/games/memory_match/memory_match_screen.dart';
import 'features/games/word_recall/word_recall_screen.dart';
import 'features/games/different_object/different_object_screen.dart';

final _router = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: false,
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
        final moduleId = state.pathParameters['moduleId'] ?? 'general';
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

    // ── Prototype Splash (preserved for future onboarding flow)
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

    // ── Login (accepts 'patient' or 'caregiver' as path param)
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

    // ── Patient Dashboard (legacy prototype view)
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
  ],
);

class SmritiCareApp extends StatelessWidget {
  const SmritiCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Smriti Care',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
