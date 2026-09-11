// lib/features/doctor/doctor_dashboard_screen.dart
//
// Complete Multi-Patient Doctor Dashboard Shell for SmritiCare.
// Features 4 Dedicated Tabs:
// 0. Home: Clinical greeting, summary cards, attention queue, search, activity
// 1. Patients: Multi-patient list, search, sorting, filtering, add patient
// 2. Alerts: Real-time clinical alerts from actual patient metrics
// 3. Profile: Physician credentials, verification disclaimer, security info, sign out

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/caregiver_auth_service.dart';
import '../../widgets/dashboard_role_switcher.dart';
import 'services/doctor_service.dart';
import 'tabs/doctor_home_tab.dart';
import 'tabs/doctor_patients_tab.dart';
import 'tabs/doctor_alerts_tab.dart';
import 'tabs/doctor_profile_tab.dart';

class DoctorDashboardScreen extends StatefulWidget {
  final int initialTab;
  final VoidCallback? onBackToPatient;

  const DoctorDashboardScreen({
    super.key,
    this.initialTab = 0,
    this.onBackToPatient,
  });

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  late int _currentIndex;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _initData();
  }

  Future<void> _initData() async {
    await DoctorService.instance.init();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _handleBackToPatient() {
    if (widget.onBackToPatient != null) {
      widget.onBackToPatient!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/dashboard');
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

    final authService = CaregiverAuthService.instance;
    final isOffline = authService.isTestMode;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Header Bar with Role Switcher & Offline Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.cardBorder),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.tealLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.health_and_safety_rounded,
                          color: AppColors.tealDark,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SmritiCare Clinical',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2E7D32),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                'Doctor Portal',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.tealDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Role Switcher & Back Button
                  Row(
                    children: [
                      DashboardRoleSwitcher(
                        onSwitchToPatient: _handleBackToPatient,
                        onSwitchToCaregiver: () => context.go('/caregiver'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Offline Sync Banner (Section 18: Preserves offline architecture)
            if (isOffline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: const Color(0xFFE0F2F1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off_rounded, size: 14, color: Colors.teal.shade800),
                    const SizedBox(width: 6),
                    Text(
                      'Offline - showing last synced data',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal.shade900,
                      ),
                    ),
                  ],
                ),
              ),

            // ── Tab Body
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  DoctorHomeTab(
                    onNavigateTab: (index) => setState(() => _currentIndex = index),
                  ),
                  const DoctorPatientsTab(),
                  const DoctorAlertsTab(),
                  const DoctorProfileTab(),
                ],
              ),
            ),
          ],
        ),
      ),

      // ── Bottom Navigation Bar (Section 7)
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.cardBorder),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.tealDark,
          unselectedItemColor: AppColors.muted,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_rounded),
              label: 'Patients',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_rounded),
              label: 'Alerts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medical_information_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
