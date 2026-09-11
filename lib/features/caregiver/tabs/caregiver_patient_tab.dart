// lib/features/caregiver/tabs/caregiver_patient_tab.dart
//
// Patient Details & Linked Patients Switcher Tab:
// - Detailed profile of currently selected patient
// - Switch between multiple linked patients
// - Link a new patient via code / profile
// - Caregiver daily clinical notes & observations

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/caregiver_models.dart';
import '../../../core/services/caregiver_service.dart';

class CaregiverPatientTab extends StatefulWidget {
  final VoidCallback onPatientChanged;

  const CaregiverPatientTab({super.key, required this.onPatientChanged});

  @override
  State<CaregiverPatientTab> createState() => _CaregiverPatientTabState();
}

class _CaregiverPatientTabState extends State<CaregiverPatientTab> {
  late TextEditingController _notesController;
  bool _isNotesSaved = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text:
          'Patient responded very well to morning memory match. Prefers listening to old Assamese folk songs before bed. Ensure afternoon hydration reminder is acknowledged.',
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPatient = CaregiverService.instance.getPatientProfile();
    final allPatients = CaregiverService.instance.getLinkedPatients();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Patient Profile & Linking',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manage and switch between patients linked to your caregiver account.',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 18),

          // Primary Selected Patient Detail Card
          _buildSelectedPatientCard(currentPatient),

          const SizedBox(height: 24),

          // Linked Patients Switcher List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Linked Patients ()',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              TextButton.icon(
                onPressed: () => _openLinkPatientDialog(context),
                icon: const Icon(Icons.add_rounded,
                    size: 18, color: AppColors.teal),
                label: const Text(
                  'Link Patient',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.teal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ...allPatients.map(
            (p) => _buildLinkedPatientTile(
              patient: p,
              isSelected: p.id == currentPatient.id,
              onSelect: () async {
                await CaregiverService.instance.selectPatient(p.id);
                setState(() {});
                widget.onPatientChanged();
              },
            ),
          ),

          const SizedBox(height: 24),

          // Clinical Observations & Daily Care Notes
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.notes_rounded,
                            color: AppColors.teal, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Caregiver Notes & Daily Log',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                    if (_isNotesSaved)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.tealPale,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Saved',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.tealDark,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        'Add clinical notes or routine observations for this patient...',
                    filled: true,
                    fillColor: AppColors.softSection,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  style: const TextStyle(fontSize: 13, color: AppColors.ink),
                  onChanged: (_) {
                    if (_isNotesSaved) setState(() => _isNotesSaved = false);
                  },
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _isNotesSaved = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                              'Caregiver notes saved offline successfully.'),
                          backgroundColor: AppColors.tealDark,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Save Notes',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSelectedPatientCard(PatientProfile patient) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  patient.avatarInitials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            patient.fullName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.tealPale,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.tealDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'ID:  •  yrs • Blood Group: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 14),

          // Vitals & Clinical Attributes Grid
          _buildInfoRow(
              Icons.location_on_outlined, 'Home Location', patient.location),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.medical_services_outlined, 'Attending Physician',
              patient.physician),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.psychology_outlined, 'Dementia Stage',
              ' (Screening Support)'),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.translate_rounded, 'Primary Languages',
              patient.primaryLanguage),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.teal),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.inkSoft,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLinkedPatientTile({
    required PatientProfile patient,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.teal : AppColors.borderLight,
          width: isSelected ? 2 : 1.2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: isSelected ? AppColors.teal : AppColors.softSection,
          child: Text(
            patient.avatarInitials,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.inkSoft,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
        title: Text(
          patient.fullName,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        subtitle: const Text(
          ' yrs • ID:  •  Stage',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle_rounded,
                color: AppColors.teal, size: 24)
            : OutlinedButton(
                onPressed: onSelect,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Switch',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink),
                ),
              ),
      ),
    );
  }

  void _openLinkPatientDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final ageCtrl = TextEditingController(text: '70');
    final codeCtrl = TextEditingController(text: 'MC-');
    final physicianCtrl = TextEditingController(text: 'Dr. Bora');
    final bloodCtrl = TextEditingController(text: 'B+');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Link New Patient',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the patient details or link code from the patient application.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Patient Full Name',
                  hintText: 'e.g. Maya Sharma',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Patient Code / ID',
                  hintText: 'e.g. MC-4022',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Age'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: bloodCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Blood Group'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: physicianCtrl,
                decoration:
                    const InputDecoration(labelText: 'Attending Physician'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final initials = nameCtrl.text
                  .trim()
                  .split(' ')
                  .map((e) => e.isNotEmpty ? e[0] : '')
                  .take(2)
                  .join()
                  .toUpperCase();
              final newP = PatientProfile(
                id: codeCtrl.text.trim().isNotEmpty
                    ? codeCtrl.text.trim()
                    : 'MC-',
                fullName: nameCtrl.text.trim(),
                age: int.tryParse(ageCtrl.text) ?? 70,
                location: 'Guwahati, Assam',
                bloodGroup: bloodCtrl.text.trim().isNotEmpty
                    ? bloodCtrl.text.trim()
                    : 'B+',
                physician: physicianCtrl.text.trim(),
                dementiaLevel: 'Mild',
                primaryLanguage: 'Assamese & English',
                avatarInitials: initials.isNotEmpty ? initials : 'PT',
                lastUpdated: DateTime.now(),
              );

              await CaregiverService.instance.linkPatient(newP);
              if (mounted && ctx.mounted) {
                Navigator.pop(ctx);
                setState(() {});
                widget.onPatientChanged();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
            child: const Text('Link Patient',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
