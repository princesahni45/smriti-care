// lib/features/doctor/tabs/doctor_home_tab.dart
//
// Doctor Dashboard Home Tab.
// Features summary cards, search bar, attention queue, recent patients, and activity stream.

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/caregiver_models.dart';
import '../models/doctor_models.dart';
import '../services/doctor_service.dart';
import '../widgets/doctor_summary_card.dart';
import '../widgets/doctor_patient_card.dart';
import '../screens/patient_clinical_overview_screen.dart';

class DoctorHomeTab extends StatefulWidget {
  final Function(int tabIndex)? onNavigateTab;

  const DoctorHomeTab({super.key, this.onNavigateTab});

  @override
  State<DoctorHomeTab> createState() => _DoctorHomeTabState();
}

class _DoctorHomeTabState extends State<DoctorHomeTab> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  String _searchQuery = '';

  int _totalPatients = 0;
  int _needsReview = 0;
  int _mriPending = 0;
  int _recentAssessments = 0;

  List<PatientProfile> _patients = [];
  Map<String, PatientClinicalSummary> _summaries = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      await DoctorService.instance.init();
      final summary = await DoctorService.instance.getDashboardSummary();
      final patients = await DoctorService.instance.getAuthorizedPatients();

      final Map<String, PatientClinicalSummary> summaryMap = {};
      for (final p in patients) {
        final clinSummary =
            await DoctorService.instance.getPatientClinicalSummary(p.id);
        if (clinSummary != null) {
          summaryMap[p.id] = clinSummary;
        }
      }

      if (mounted) {
        setState(() {
          _totalPatients = summary.totalPatients;
          _needsReview = summary.needsReview;
          _mriPending = summary.mriPending;
          _recentAssessments = summary.recentAssessments;
          _patients = patients;
          _summaries = summaryMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.teal),
      );
    }

    final doctor = DoctorService.instance.doctorProfile;
    final doctorName = DoctorService.instance.currentDoctorName;

    // Filter patients by search query
    final filteredPatients = _patients.where((p) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return p.fullName.toLowerCase().contains(q) ||
          p.id.toLowerCase().contains(q) ||
          p.location.toLowerCase().contains(q);
    }).toList();

    // Attention list: patients with Review Suggested or Monitor
    final attentionPatients = _patients.where((p) {
      final s = _summaries[p.id];
      return s != null &&
          (s.attentionStatus.level == PatientAttentionLevel.reviewSuggested ||
              s.attentionStatus.level == PatientAttentionLevel.monitor);
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: AppColors.teal,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting & Doctor Profile Banner
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doctorName.startsWith('Dr.')
                            ? doctorName
                            : 'Dr. $doctorName',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.local_hospital_rounded,
                              size: 13, color: AppColors.tealDark),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${doctor.specialization} • ${doctor.hospitalOrClinic}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.tealDark,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.tealLight,
                  child: Icon(Icons.medical_services_rounded,
                      color: AppColors.teal, size: 26),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Dashboard Summary 2x2 Grid
            Row(
              children: [
                Expanded(
                  child: DoctorSummaryCard(
                    title: 'Total Patients',
                    value: '$_totalPatients',
                    subtitle: 'Linked & active',
                    icon: Icons.people_alt_rounded,
                    color: AppColors.teal,
                    onTap: () => widget.onNavigateTab?.call(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DoctorSummaryCard(
                    title: 'Needs Review',
                    value: '$_needsReview',
                    subtitle: 'Score variance/alerts',
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFC62828),
                    onTap: () => widget.onNavigateTab?.call(1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DoctorSummaryCard(
                    title: 'MRI Pending',
                    value: '$_mriPending',
                    subtitle: 'Awaiting doctor review',
                    icon: Icons.biotech_rounded,
                    color: const Color(0xFFE65100),
                    onTap: () => widget.onNavigateTab?.call(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DoctorSummaryCard(
                    title: 'Recent Tests',
                    value: '$_recentAssessments',
                    subtitle: 'Completed last 7 days',
                    icon: Icons.psychology_rounded,
                    color: const Color(0xFF1565C0),
                    onTap: () => widget.onNavigateTab?.call(1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // ── Search Patients Bar
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                decoration: InputDecoration(
                  hintText: 'Search patients by name, ID or location...',
                  hintStyle:
                      const TextStyle(fontSize: 13, color: AppColors.muted),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.muted, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // ── Patients Requiring Attention (if any)
            if (_searchQuery.isEmpty && attentionPatients.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFC62828),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Requires Attention',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${attentionPatients.length} patient${attentionPatients.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...attentionPatients.map((patient) {
                final summary = _summaries[patient.id];
                final mriPending =
                    summary?.mriScans.any((m) => !m.isReviewed) ?? false;
                final mriStatus = summary?.mriScans.isEmpty ?? true
                    ? 'No MRI'
                    : (mriPending ? 'Review Pending' : 'Reviewed');

                return DoctorPatientCard(
                  patient: patient,
                  latestScore: summary?.latestScore,
                  trendPercent: summary?.trendPercent,
                  lastAssessedAt: summary?.lastAssessedAt,
                  mriStatus: mriStatus,
                  attentionStatus: summary?.attentionStatus ??
                      PatientAttentionStatus.insufficientData(),
                  onViewPatient: () => _openPatientOverview(patient),
                );
              }),
              const SizedBox(height: 14),
            ],

            // ── Recent / All Patients Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Search Results (${filteredPatients.length})'
                      : 'My Patients',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                TextButton(
                  onPressed: () => widget.onNavigateTab?.call(1),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tealDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (filteredPatients.isEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Icon(Icons.person_search_rounded,
                        size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 10),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'No patients matching "$_searchQuery"'
                          : 'No patients linked yet.',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted),
                    ),
                    if (_searchQuery.isEmpty) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Use the Patients tab to connect your first patient via caregiver link code.',
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              )
            else
              ...filteredPatients.take(3).map((patient) {
                final summary = _summaries[patient.id];
                final mriPending =
                    summary?.mriScans.any((m) => !m.isReviewed) ?? false;
                final mriStatus = summary?.mriScans.isEmpty ?? true
                    ? 'No MRI'
                    : (mriPending ? 'Review Pending' : 'Reviewed');

                return DoctorPatientCard(
                  patient: patient,
                  latestScore: summary?.latestScore,
                  trendPercent: summary?.trendPercent,
                  lastAssessedAt: summary?.lastAssessedAt,
                  mriStatus: mriStatus,
                  attentionStatus: summary?.attentionStatus ??
                      PatientAttentionStatus.insufficientData(),
                  onViewPatient: () => _openPatientOverview(patient),
                );
              }),

            const SizedBox(height: 16),

            // ── Recent Clinical Activity Stream
            const Text(
              'Recent Clinical Activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  _buildActivityItem(
                    icon: Icons.biotech_rounded,
                    color: const Color(0xFFE65100),
                    title: 'MRI Screening Submitted',
                    subtitle: 'Mr. Ramesh Das (MC-2048) • Awaiting Review',
                    timeAgo: '3 hours ago',
                  ),
                  const Divider(height: 20, color: AppColors.cardBorder),
                  _buildActivityItem(
                    icon: Icons.psychology_rounded,
                    color: AppColors.teal,
                    title: 'Cognitive Session Completed',
                    subtitle: 'Mrs. Maya Sharma (MC-3109) • Score 82/100',
                    timeAgo: '5 hours ago',
                  ),
                  const Divider(height: 20, color: AppColors.cardBorder),
                  _buildActivityItem(
                    icon: Icons.note_alt_rounded,
                    color: const Color(0xFF1565C0),
                    title: 'Doctor Clinical Note Saved',
                    subtitle: 'Dr. Ananya Bora • Care plan updated',
                    timeAgo: 'Yesterday',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _openPatientOverview(PatientProfile patient) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (ctx) =>
                PatientClinicalOverviewScreen(patientId: patient.id),
          ),
        )
        .then((_) => _loadDashboardData());
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String timeAgo,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
        Text(
          timeAgo,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}
