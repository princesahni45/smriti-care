// lib/features/doctor/tabs/doctor_alerts_tab.dart
//
// Smart Alerts Tab for Doctor Portal.
// Displays actionable clinical alerts derived strictly from real patient data.

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/doctor_models.dart';
import '../services/doctor_service.dart';
import '../screens/patient_clinical_overview_screen.dart';

class DoctorAlertsTab extends StatefulWidget {
  const DoctorAlertsTab({super.key});

  @override
  State<DoctorAlertsTab> createState() => _DoctorAlertsTabState();
}

class _DoctorAlertsTabState extends State<DoctorAlertsTab> {
  bool _isLoading = true;
  List<DoctorSmartAlert> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    try {
      await DoctorService.instance.init();
      final alerts = await DoctorService.instance.generateSmartAlerts();
      if (mounted) {
        setState(() {
          _alerts = alerts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.teal),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAlerts,
      color: AppColors.teal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clinical Alerts',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Real-time automated alerts based on patient activity',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _alerts.isNotEmpty ? const Color(0xFFC62828).withValues(alpha: 0.12) : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _alerts.isNotEmpty ? const Color(0xFFC62828).withValues(alpha: 0.3) : AppColors.cardBorder,
                    ),
                  ),
                  child: Text(
                    '${_alerts.length} Active',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _alerts.isNotEmpty ? const Color(0xFFC62828) : AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Alerts List or Empty State
          Expanded(
            child: _alerts.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 48,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No patients currently require review.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'All cognitive assessment scores and MRI scans across your linked patients are stable and reviewed.',
                            style: TextStyle(fontSize: 13, color: AppColors.muted),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    itemCount: _alerts.length,
                    itemBuilder: (context, index) {
                      final alert = _alerts[index];
                      return _buildAlertCard(alert);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(DoctorSmartAlert alert) {
    Color iconColor = AppColors.teal;
    IconData iconData = Icons.notifications_active_rounded;
    Color borderColor = AppColors.cardBorder;

    if (alert.type == 'score_drop') {
      iconColor = const Color(0xFFC62828);
      iconData = Icons.trending_down_rounded;
      borderColor = const Color(0xFFC62828).withValues(alpha: 0.3);
    } else if (alert.type == 'mri_pending') {
      iconColor = const Color(0xFFE65100);
      iconData = Icons.biotech_rounded;
      borderColor = const Color(0xFFE65100).withValues(alpha: 0.3);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => PatientClinicalOverviewScreen(patientId: alert.patientId),
              ),
            ).then((_) => _loadAlerts());
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(iconData, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              alert.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          Text(
                            _formatTime(alert.timestamp),
                            style: const TextStyle(fontSize: 11, color: AppColors.muted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Patient: ${alert.patientName} (${alert.patientId})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.tealDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alert.message,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.ink,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Row(
                        children: [
                          Text(
                            'Review Patient Records',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.tealDark,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 13, color: AppColors.tealDark),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
