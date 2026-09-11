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
import '../features/voice_assistant/widgets/voice_assistant_sheet.dart';
import '../core/models/user_model.dart';

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
        _openCaregiverWithPin();
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

  Future<void> _openCaregiverWithPin() async {
    final pinController = TextEditingController();
    String? pinError;

    final authorized = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setStateDlg) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          contentPadding: const EdgeInsets.all(24),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.tealLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.shield_rounded,
                      color: AppColors.teal, size: 28),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Caregiver Authorization',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter caregiver PIN to access administrative portal and diagnostics.',
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8),
                  decoration: InputDecoration(
                    hintText: '••••',
                    counterText: '',
                    errorText: pinError,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.teal, width: 2),
                    ),
                  ),
                  onChanged: (_) => setStateDlg(() => pinError = null),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogCtx, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final result = AuthService.validateCaregiverPin(
                              pinController.text);
                          if (result.success) {
                            Navigator.pop(dialogCtx, true);
                          } else {
                            setStateDlg(() => pinError = result.error);
                            pinController.clear();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Unlock'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (authorized == true && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => CaregiverDashboardScreen(
            onBackToPatient: () => Navigator.of(ctx).pop(),
          ),
        ),
      );
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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'voiceAssistantFab',
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.mic_rounded, size: 26),
        label: const Text(
          'Voice Help',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        onPressed: () => VoiceAssistantSheet.show(context),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(
            top: BorderSide(color: AppColors.borderLight, width: 1.5),
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
