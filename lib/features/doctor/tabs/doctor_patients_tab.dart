// lib/features/doctor/tabs/doctor_patients_tab.dart
//
// My Patients Tab for Doctor Portal.
// Features multi-patient list, search, sorting, category filtering, and [Add Patient] linking.

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/caregiver_models.dart';
import '../models/doctor_models.dart';
import '../services/doctor_service.dart';
import '../widgets/doctor_patient_card.dart';
import '../screens/patient_clinical_overview_screen.dart';
import '../screens/add_patient_screen.dart';

class DoctorPatientsTab extends StatefulWidget {
  const DoctorPatientsTab({super.key});

  @override
  State<DoctorPatientsTab> createState() => _DoctorPatientsTabState();
}

class _DoctorPatientsTabState extends State<DoctorPatientsTab> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter =
      'All'; // 'All', 'Needs Review', 'MRI Pending', 'Recent Assessment'
  String _sortBy = 'Name'; // 'Name', 'Score', 'Last Assessed'

  List<PatientProfile> _patients = [];
  Map<String, PatientClinicalSummary> _summaries = {};

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    try {
      await DoctorService.instance.init();
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
          _patients = patients;
          _summaries = summaryMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<PatientProfile> _getFilteredAndSortedPatients() {
    List<PatientProfile> list = _patients.where((p) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final match = p.fullName.toLowerCase().contains(q) ||
            p.id.toLowerCase().contains(q) ||
            p.location.toLowerCase().contains(q);
        if (!match) return false;
      }

      // Category filter
      final summary = _summaries[p.id];
      switch (_selectedFilter) {
        case 'Needs Review':
          return summary?.attentionStatus.level ==
              PatientAttentionLevel.reviewSuggested;
        case 'MRI Pending':
          return summary?.mriScans
                  .any((m) => !m.isReviewed && m.status == 'completed') ??
              false;
        case 'Recent Assessment':
          if (summary?.lastAssessedAt == null) return false;
          final weekAgo = DateTime.now().subtract(const Duration(days: 7));
          return summary!.lastAssessedAt!.isAfter(weekAgo);
        case 'All':
        default:
          return true;
      }
    }).toList();

    // Sorting
    switch (_sortBy) {
      case 'Score':
        list.sort((a, b) {
          final scoreA = _summaries[a.id]?.latestScore ?? -1;
          final scoreB = _summaries[b.id]?.latestScore ?? -1;
          return scoreB.compareTo(scoreA); // Highest first
        });
        break;
      case 'Last Assessed':
        list.sort((a, b) {
          final dateA = _summaries[a.id]?.lastAssessedAt ?? DateTime(2000);
          final dateB = _summaries[b.id]?.lastAssessedAt ?? DateTime(2000);
          return dateB.compareTo(dateA); // Newest first
        });
        break;
      case 'Name':
      default:
        list.sort((a, b) => a.fullName.compareTo(b.fullName));
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.teal),
      );
    }

    final filteredList = _getFilteredAndSortedPatients();

    return RefreshIndicator(
      onRefresh: _loadPatients,
      color: AppColors.teal,
      child: Column(
        children: [
          // ── Top Bar: Title & [Add Patient] action
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Patients',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      '${_patients.length} authorized patient${_patients.length == 1 ? '' : 's'}',
                      style:
                          const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _openAddPatient,
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                  label: const Text('Add Patient'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Search & Sort controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) =>
                          setState(() => _searchQuery = val.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search patients...',
                        hintStyle: const TextStyle(
                            fontSize: 13, color: AppColors.muted),
                        prefixIcon: const Icon(Icons.search_rounded,
                            size: 18, color: AppColors.muted),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Sort Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      icon: const Icon(Icons.sort_rounded,
                          size: 18, color: AppColors.ink),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink),
                      items: const [
                        DropdownMenuItem(
                            value: 'Name', child: Text('Sort: Name')),
                        DropdownMenuItem(
                            value: 'Score', child: Text('Sort: Score')),
                        DropdownMenuItem(
                            value: 'Last Assessed',
                            child: Text('Sort: Recent')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _sortBy = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Filter Chips Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Needs Review'),
                const SizedBox(width: 8),
                _buildFilterChip('MRI Pending'),
                const SizedBox(width: 8),
                _buildFilterChip('Recent Assessment'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Patient List or Empty State
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _patients.isEmpty
                                ? Icons.group_off_rounded
                                : Icons.filter_alt_off_rounded,
                            size: 54,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _patients.isEmpty
                                ? 'No patients linked yet.'
                                : 'No patients match this filter.',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _patients.isEmpty
                                ? 'Obtain a secure Patient Link Code from the patient\'s caregiver to connect.'
                                : 'Try changing your search query or selecting a different category filter.',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.muted),
                            textAlign: TextAlign.center,
                          ),
                          if (_patients.isEmpty) ...[
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _openAddPatient,
                              icon: const Icon(Icons.add_link_rounded),
                              label: const Text('Add Patient'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.teal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final patient = filteredList[index];
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
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return InkWell(
      onTap: () {
        if (!isSelected) setState(() => _selectedFilter = label);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.teal : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.teal : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.ink,
          ),
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
        .then((_) => _loadPatients());
  }

  void _openAddPatient() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (ctx) => const AddPatientScreen(),
          ),
        )
        .then((_) => _loadPatients());
  }
}
