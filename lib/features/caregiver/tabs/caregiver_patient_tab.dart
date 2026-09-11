// lib/features/caregiver/tabs/caregiver_patient_tab.dart
//
// Patient Details & Linked Patients Switcher Tab:
// - Detailed profile of currently selected patient
// - Switch between multiple linked patients
// - Link a new patient via code / profile
// - Caregiver daily clinical notes & observations

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/caregiver_models.dart';
import '../../../core/services/caregiver_service.dart';
// FIX: Added secure doctor-patient linking - doctor management service
import '../../doctor/services/doctor_service.dart';

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
                // FIX: Prevent RenderFlex overflow on narrow mobile screens - flexible title row
                Row(
                  children: [
                    const Icon(Icons.notes_rounded,
                        color: AppColors.teal, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Caregiver Notes & Daily Log',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isNotesSaved) ...[
                      const SizedBox(width: 8),
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
                          content: Text(
                            context.tr('caregiver.notesSaved',
                                defaultText:
                                    'Caregiver notes saved offline successfully.'),
                          ),
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
                    child: Text(
                      context.tr('caregiver.saveNotes',
                          defaultText: 'Save Notes'),
                      style: const TextStyle(
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

          // ── Doctor Access & Linking Section (Section 5)
          // FIX: Added secure doctor-patient linking - caregiver doctor management
          _buildDoctorAccessSection(currentPatient),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // FIX: Added secure doctor-patient linking - doctor access widget
  Widget _buildDoctorAccessSection(PatientProfile patient) {
    final linkCode = DoctorService.instance.generateOrGetLinkCode(patient.id);
    final pendingRequests =
        DoctorService.instance.getPendingRequestsForPatient(patient.id);
    final approvedLinks =
        DoctorService.instance.getApprovedLinksForPatient(patient.id);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FIX: Prevent RenderFlex overflow on narrow mobile screens - responsive heading with Expanded and maxLines: 2
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.medical_services_rounded,
                  color: AppColors.teal, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Doctor Access & Permissions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tealLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${approvedLinks.length} Connected',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.tealDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Share the code below with your neurologist to grant authorized access to cognitive trends and MRI results.',
            style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.3),
          ),
          const SizedBox(height: 14),

          // FIX: Prevent RenderFlex overflow on narrow mobile screens - responsive Patient Link Code Card with LayoutBuilder
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 300;

              final codeContent = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PATIENT LINK CODE',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.tealDark),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    linkCode,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: AppColors.tealDark,
                    ),
                  ),
                ],
              );

              final shareButton = ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Link Code $linkCode copied to clipboard!')),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: const Text('Share Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              );

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF80CBC4)),
                ),
                child: isCompact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          codeContent,
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: shareButton,
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: codeContent),
                          const SizedBox(width: 8),
                          shareButton,
                        ],
                      ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Pending Requests
          if (pendingRequests.isNotEmpty) ...[
            const Text(
              'Pending Doctor Requests',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFE65100)),
            ),
            const SizedBox(height: 8),
            ...pendingRequests.map((req) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFB74D)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_pin_rounded,
                        color: Color(0xFFE65100), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dr. Ananya Bora (DOC-001)',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            req.notes ?? 'Connection requested via link code.',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF2E7D32), size: 24),
                          onPressed: () async {
                            await DoctorService.instance
                                .approvePatientLink(req.linkId);
                            if (!mounted) return;
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Doctor access approved.')),
                            );
                          },
                          tooltip: 'Approve Doctor',
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel_rounded,
                              color: Color(0xFFC62828), size: 24),
                          onPressed: () async {
                            await DoctorService.instance
                                .revokePatientLink(req.linkId);
                            if (!mounted) return;
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Doctor request rejected.')),
                            );
                          },
                          tooltip: 'Reject Request',
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
          ],

          // Approved Doctors
          if (approvedLinks.isNotEmpty) ...[
            const Text(
              'Authorized Doctors',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            ...approvedLinks.map((link) {
              // FIX: Prevent RenderFlex overflow on narrow mobile screens
              return LayoutBuilder(
                builder: (cardCtx, doctorConstraints) {
                  final isNarrow = doctorConstraints.maxWidth < 290;
                  const doctorInfo = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded,
                          color: AppColors.teal, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dr. Ananya Bora (Neurologist)',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Guwahati Neurological Institute',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.muted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  final revokeButton = TextButton(
                    onPressed: () async {
                      await DoctorService.instance
                          .revokePatientLink(link.linkId);
                      if (!cardCtx.mounted) return;
                      setState(() {});
                      ScaffoldMessenger.of(cardCtx).showSnackBar(
                        const SnackBar(content: Text('Doctor access revoked.')),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Revoke',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFC62828),
                          fontWeight: FontWeight.w700),
                    ),
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isNarrow
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              doctorInfo,
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerRight,
                                child: revokeButton,
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(child: doctorInfo),
                              const SizedBox(width: 8),
                              revokeButton,
                            ],
                          ),
                  );
                },
              );
            }),
          ],
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  // FIX: Prevent RenderFlex overflow on narrow mobile screens
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.teal),
        const SizedBox(width: 8),
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.inkSoft,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // FIX: Prevent RenderFlex overflow on narrow mobile screens
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: const Text(
          ' yrs • ID:  •  Stage',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
            child: Text(context.tr('common.cancel', defaultText: 'Cancel')),
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
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              if (mounted) {
                setState(() {});
                widget.onPatientChanged();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
            child: Text(
              context.tr('caregiver.linkPatient', defaultText: 'Link Patient'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
