// lib/features/caregiver/caregiver_dashboard_screen.dart
//
// Full Caregiver Portal Dashboard Shell for SmritiCare.
// Separated strictly from the elderly patient interface.
// Features 5 Dedicated Tabs:
// 0. Home / Overview (Greeting, Patient banner, 6 Summary Cards, Shortcuts, Activity)
// 1. Patient Details & Switcher (Detailed patient profile, multi-patient switcher, link patient)
// 2. Cognitive Progress & Reports (Charts, Response Speed, Accuracy, 7 Game Reports)
// 3. Alerts & Reminders (Screening Risk Indicator, Intelligent Alerts, Reminders CRUD)
// 4. Profile & Safety (Caregiver profile, Family Memories CRUD, SOS log, Location)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/services/caregiver_service.dart';
import 'widgets/caregiver_header_bar.dart';
import 'tabs/caregiver_home_tab.dart';
import 'tabs/caregiver_patient_tab.dart';
import 'tabs/caregiver_progress_tab.dart';
import 'tabs/caregiver_alerts_reminders_tab.dart';
import 'tabs/caregiver_profile_safety_tab.dart';

class CaregiverDashboardScreen extends StatefulWidget {
  final int initialTab;
  final VoidCallback? onBackToPatient;

  const CaregiverDashboardScreen({
    super.key,
    this.initialTab = 0,
    this.onBackToPatient,
  });

  @override
  State<CaregiverDashboardScreen> createState() => _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  late int _currentIndex;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _initData();
  }

  Future<void> _initData() async {
    await CaregiverService.instance.init();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleBackToPatient() {
    if (widget.onBackToPatient != null) {
      widget.onBackToPatient!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/');
    }
  }

  void _navigateToTab(int tabIndex) {
    if (tabIndex >= 0 && tabIndex <= 4) {
      setState(() {
        _currentIndex = tabIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.teal),
        ),
      );
    }

    final caregiver = CaregiverService.instance.getCaregiverProfile();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Sticky Header with Caregiver profile & Patient View button
          CaregiverHeaderBar(
            profile: caregiver,
            onSwitchToPatient: _handleBackToPatient,
          ),

          // ── Tab Body (5 Dedicated Tabs)
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                // Tab 0: Home / Overview
                CaregiverHomeTab(
                  onSwitchPatientTap: () => _navigateToTab(1),
                  onNavigateTab: _navigateToTab,
                ),

                // Tab 1: Patient Details & Switcher
                CaregiverPatientTab(
                  onPatientChanged: () => setState(() {}),
                ),

                // Tab 2: Cognitive Progress & Reports
                const CaregiverProgressTab(),

                // Tab 3: Alerts & Reminders Management
                const CaregiverAlertsRemindersTab(),

                // Tab 4: Profile, Family Memories & Safety Hub
                CaregiverProfileSafetyTab(
                  onSwitchToPatient: _handleBackToPatient,
                ),
              ],
            ),
          ),
        ],
      ),

      // ── Caregiver 5-Item Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.borderLight, width: 1.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          elevation: 0,
          currentIndex: _currentIndex,
          onTap: (idx) => setState(() => _currentIndex = idx),
          selectedItemColor: AppColors.teal,
          unselectedItemColor: AppColors.muted,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.2),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home_rounded),
              label: context.tr('common.home', defaultText: 'Home'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_pin_outlined),
              activeIcon: const Icon(Icons.person_pin_rounded),
              label: context.tr('caregiver.yourPatient', defaultText: 'Patient'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.bar_chart_outlined),
              activeIcon: const Icon(Icons.bar_chart_rounded),
              label: context.tr('nav.progress', defaultText: 'Progress'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.notifications_none_rounded),
              activeIcon: const Icon(Icons.notifications_rounded),
              label: context.tr('reminders.title', defaultText: 'Alerts'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.shield_outlined),
              activeIcon: const Icon(Icons.shield_rounded),
              label: context.tr('nav.profile', defaultText: 'Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
