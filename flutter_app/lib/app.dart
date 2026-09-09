// lib/app.dart
//
// Root app widget with go_router navigation.
// Defines all routes matching the React view states from AppRoot.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
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
    // ── Splash (entry point)
    GoRoute(
      path: '/',
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
