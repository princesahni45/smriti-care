// lib/screens/main_shell_screen.dart
//
// Root mobile shell featuring an accessible BottomNavigationBar.
// Tabs:
// 0. Home (SmritiCare Dashboard)
// 1. Games (Cognitive Games Placeholder)
// 2. Reminders (Smart Reminders Placeholder)
// 3. Progress (Your Progress Placeholder)
// 4. Profile (Patient Profile & Settings Placeholder)

import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'placeholder_screen.dart';
import '../features/games/games_hub_screen.dart';
import '../features/caregiver/caregiver_dashboard_screen.dart';

class MainShellScreen extends StatefulWidget {
  final int initialTab;

  const MainShellScreen({super.key, this.initialTab = 0});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _handleDashboardNavigate(String moduleId) {
    switch (moduleId.toLowerCase()) {
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
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => CaregiverDashboardScreen(
              onBackToPatient: () => Navigator.of(ctx).pop(),
            ),
          ),
        );
        break;
      default:
        // For Emergency, Location, Caregiver, push the dedicated PlaceholderScreen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => PlaceholderScreen.forModule(
              moduleId,
              onBack: () => Navigator.of(ctx).pop(),
            ),
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
        onBack: () => _onTabTapped(0),
      ),
      PlaceholderScreen.forModule(
        'reminders',
        onBack: () => _onTabTapped(0),
      ),
      PlaceholderScreen.forModule(
        'progress',
        onBack: () => _onTabTapped(0),
      ),
      PlaceholderScreen.forModule(
        'profile',
        onBack: () => _onTabTapped(0),
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
            top: BorderSide(color: AppColors.borderLight, width: 1.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology_outlined),
              activeIcon: Icon(Icons.psychology_rounded),
              label: 'Games',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.access_time_rounded),
              activeIcon: Icon(Icons.access_time_filled_rounded),
              label: 'Reminders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart_rounded),
              label: 'Progress',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
