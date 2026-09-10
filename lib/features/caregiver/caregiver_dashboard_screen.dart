// lib/features/caregiver/caregiver_dashboard_screen.dart
//
// Full Caregiver Portal Dashboard for SmritiCare.
// Separated strictly from the elderly patient interface.
// Features:
// - Overview tab: Patient Banner, Stat Grid, Weekly Chart, Health Snapshot, Insights, Timeline
// - Cognitive & Games tab: Live performance tracking from GameStorageService
// - Reminders tab: Full reminder monitoring, category filters, toggle switches, add reminder
// - Safety & Location tab: Primary Caregiver contact, Safe Home Location, 112 Emergency Hotline
// - Mobile-first navigation with bottom navigation bar

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/caregiver_models.dart';
import '../../core/services/caregiver_service.dart';
import 'widgets/caregiver_header_bar.dart';
import 'widgets/patient_banner_card.dart';
import 'widgets/caregiver_stat_grid.dart';
import 'widgets/weekly_engagement_chart.dart';
import 'widgets/health_snapshot_card.dart';
import 'widgets/cognitive_performance_section.dart';
import 'widgets/reminder_management_section.dart';
import 'widgets/emergency_safety_section.dart';
import 'widgets/activity_timeline_section.dart';

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

    final patient = CaregiverService.instance.getPatientProfile();
    final caregiver = CaregiverService.instance.getCaregiverProfile();
    final metrics = CaregiverService.instance.getOverviewMetrics();
    final weeklyData = CaregiverService.instance.getWeeklyEngagement();
    final contact = CaregiverService.instance.getEmergencyContact();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Sticky Header with Caregiver profile & Exit button
          CaregiverHeaderBar(
            profile: caregiver,
            onSwitchToPatient: _handleBackToPatient,
          ),

          // ── Tab Body
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                // Tab 0: Care Overview
                _buildOverviewTab(patient, metrics, weeklyData, contact),

                // Tab 1: Cognitive & Games Activity
                _buildCognitiveTab(),

                // Tab 2: Reminders Monitoring
                _buildRemindersTab(),

                // Tab 3: Safety & Location
                _buildSafetyTab(),
              ],
            ),
          ),
        ],
      ),

      // ── Caregiver Bottom Navigation
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.borderLight, width: 1.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
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
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Overview',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.psychology_outlined),
              activeIcon: Icon(Icons.psychology_rounded),
              label: 'Cognitive',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.alarm_outlined),
              activeIcon: Icon(Icons.alarm_rounded),
              label: 'Reminders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shield_outlined),
              activeIcon: Icon(Icons.shield_rounded),
              label: 'Safety',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(
    PatientProfile patient,
    Map<String, String> metrics,
    List<Map<String, dynamic>> weeklyData,
    EmergencyContact contact,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PatientBannerCard(patient: patient),
          const SizedBox(height: 18),
          CaregiverStatGrid(metrics: metrics),
          const SizedBox(height: 18),
          WeeklyEngagementChart(data: weeklyData),
          const SizedBox(height: 18),
          HealthSnapshotCard(patient: patient, emergencyContact: contact),
          const SizedBox(height: 18),
          const CareInsightCard(),
          const SizedBox(height: 18),
          const ActivityTimelineSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCognitiveTab() {
    return const SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: CognitivePerformanceSection(),
    );
  }

  Widget _buildRemindersTab() {
    return const SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ReminderManagementSection(),
    );
  }

  Widget _buildSafetyTab() {
    return const SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: EmergencySafetySection(),
    );
  }
}
