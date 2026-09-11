// lib/screens/main_shell_screen.dart
//
// Root mobile shell featuring an accessible BottomNavigationBar.
//
// Tabs:
// 0. Home
// 1. Games
// 2. Reminders
// 3. Progress
// 4. Profile

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/localization/app_localizations.dart';
import '../core/services/caregiver_auth_service.dart';
import '../core/theme/app_theme.dart';
import '../core/voice/voice.dart';

import '../features/assessment/cognitive_assessment_screen.dart';
import '../features/emergency/take_me_home_screen.dart';
import '../features/games/games_hub_screen.dart';
import '../features/mri/mri_screening_screen.dart';
import '../features/patient/patient_profile_screen.dart';
import '../features/patient/patient_progress_screen.dart';
import '../features/patient/patient_reminders_screen.dart';

import 'dashboard_screen.dart';
import 'language_select_screen.dart';
import 'placeholder_screen.dart';

class MainShellScreen extends StatefulWidget {
  final int initialTab;

  const MainShellScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _currentIndex;

  static const int _totalTabs = 5;

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialTab.clamp(0, _totalTabs - 1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _syncRouteTracker(_currentIndex);
    });
  }

  void _syncRouteTracker(int index) {
    switch (index) {
      case 1:
        VoiceRouteTracker.instance.setCurrentRoute('/games');
        break;

      case 2:
        VoiceRouteTracker.instance.setCurrentRoute(
          '/dashboard/reminders',
        );
        break;

      case 3:
        VoiceRouteTracker.instance.setCurrentRoute(
          '/dashboard/progress',
        );
        break;

      case 4:
        VoiceRouteTracker.instance.setCurrentRoute(
          '/dashboard/profile',
        );
        break;

      case 0:
      default:
        VoiceRouteTracker.instance.setCurrentRoute('/dashboard');
        break;
    }
  }

  void _onTabTapped(int index) {
    if (index < 0 || index >= _totalTabs) return;

    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });

    _syncRouteTracker(index);
  }

  void _handleDashboardNavigate(String moduleId) {
    final normalizedModuleId = moduleId.trim().toLowerCase();

    switch (normalizedModuleId) {
      case 'games':
        _onTabTapped(1);
        break;

      case 'reminders':
        _onTabTapped(2);
        break;

      case 'progress':
        _onTabTapped(3);
        break;

      case 'profile':
        _onTabTapped(4);
        break;

      case 'caregiver':
        final authService = CaregiverAuthService.instance;

        if (authService.switchToCaregiverModeIfAuthenticated()) {
          context.go('/caregiver');
        } else {
          context.push('/caregiver-login');
        }
        break;

      case 'doctor':
        final authService = CaregiverAuthService.instance;

        if (authService.switchToDoctorModeIfAuthenticated()) {
          context.go('/doctor');
        } else {
          context.push('/doctor-login');
        }
        break;

      case 'emergency':
      case 'sos':
      case 'location':
        Navigator.of(context).push(
          MaterialPageRoute(
            settings: const RouteSettings(
              name: '/take-me-home',
            ),
            builder: (routeContext) {
              return TakeMeHomeScreen(
                onBack: () {
                  Navigator.of(routeContext).pop();
                },
              );
            },
          ),
        );
        break;

      case 'mri':
      case 'mri-screening':
        Navigator.of(context).push(
          MaterialPageRoute(
            settings: const RouteSettings(
              name: '/mri-screening',
            ),
            builder: (routeContext) {
              return MriScreeningScreen(
                onBack: () {
                  Navigator.of(routeContext).pop();
                },
              );
            },
          ),
        );
        break;

      case 'assessment':
      case 'cognitive-assessment':
        Navigator.of(context).push(
          MaterialPageRoute(
            settings: const RouteSettings(
              name: '/assessment',
            ),
            builder: (routeContext) {
              return CognitiveAssessmentScreen(
                onBack: () {
                  Navigator.of(routeContext).pop();
                },
              );
            },
          ),
        );
        break;

      case 'language':
      case 'lang':
      case 'language-select':
        Navigator.of(context).push(
          MaterialPageRoute(
            settings: const RouteSettings(
              name: '/language-select',
            ),
            builder: (routeContext) {
              return LanguageSelectScreen(
                onBack: () {
                  Navigator.of(routeContext).pop();
                },
              );
            },
          ),
        );
        break;

      default:
        Navigator.of(context).push(
          MaterialPageRoute(
            settings: RouteSettings(
              name: '/placeholder/$normalizedModuleId',
            ),
            builder: (routeContext) {
              return PlaceholderScreen.forModule(
                moduleId,
                onBack: () {
                  Navigator.of(routeContext).pop();
                },
              );
            },
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      DashboardScreen(
        onNavigateModule: _handleDashboardNavigate,
      ),

      GamesHubScreen(
        onBack: () {
          _onTabTapped(0);
        },
      ),

      PatientRemindersScreen(
        onBack: () {
          _onTabTapped(0);
        },
      ),

      PatientProgressScreen(
        onBack: () {
          _onTabTapped(0);
        },
      ),

      PatientProfileScreen(
        onBack: () {
          _onTabTapped(0);
        },
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(
            top: BorderSide(
              color: AppColors.borderLight,
              width: 1.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          elevation: 0,
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          selectedItemColor: AppColors.teal,
          unselectedItemColor: AppColors.muted,
          selectedFontSize: 13,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
          iconSize: 26,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(
                Icons.home_outlined,
              ),
              activeIcon: const Icon(
                Icons.home_rounded,
              ),
              label: context.tr(
                'common.home',
                defaultText: 'Home',
              ),
            ),
            BottomNavigationBarItem(
              icon: const Icon(
                Icons.psychology_outlined,
              ),
              activeIcon: const Icon(
                Icons.psychology_rounded,
              ),
              label: context.tr(
                'nav.games',
                defaultText: 'Games',
              ),
            ),
            BottomNavigationBarItem(
              icon: const Icon(
                Icons.access_time_rounded,
              ),
              activeIcon: const Icon(
                Icons.access_time_filled_rounded,
              ),
              label: context.tr(
                'nav.reminders',
                defaultText: 'Reminders',
              ),
            ),
            BottomNavigationBarItem(
              icon: const Icon(
                Icons.bar_chart_outlined,
              ),
              activeIcon: const Icon(
                Icons.bar_chart_rounded,
              ),
              label: context.tr(
                'nav.progress',
                defaultText: 'Progress',
              ),
            ),
            BottomNavigationBarItem(
              icon: const Icon(
                Icons.person_outline_rounded,
              ),
              activeIcon: const Icon(
                Icons.person_rounded,
              ),
              label: context.tr(
                'nav.profile',
                defaultText: 'Profile',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
