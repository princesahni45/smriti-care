// lib/features/caregiver/tabs/caregiver_profile_safety_tab.dart
//
// Caregiver Profile, Family Memories Management & Emergency Safety Tab:
// - Caregiver account profile details
// - Family Memories Management (Add/Edit/Delete family members with photos/avatar, relationship, notes)
// - Real-time emergency status & SOS history log
// - Emergency contacts with quick call action
// - Safe zone / patient location visual representation
// - Switch to Patient Mode & Sign Out

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/caregiver_models.dart';
import '../../../core/services/caregiver_service.dart';

class CaregiverProfileSafetyTab extends StatefulWidget {
  final VoidCallback onSwitchToPatient;

  const CaregiverProfileSafetyTab({super.key, required this.onSwitchToPatient});

  @override
  State<CaregiverProfileSafetyTab> createState() => _CaregiverProfileSafetyTabState();
}

class _CaregiverProfileSafetyTabState extends State<CaregiverProfileSafetyTab> {
  @override
  Widget build(BuildContext context) {
    final caregiver = CaregiverService.instance.getCaregiverProfile();
    final familyMembers = CaregiverService.instance.getFamilyMembers();
    final emergencyContact = CaregiverService.instance.getEmergencyContact();
    final homeLocation = CaregiverService.instance.getHomeLocation();
    final sosLogs = CaregiverService.instance.getSosHistory();
    final isEmergency = CaregiverService.instance.isEmergencyActive();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Profile & Safety Hub',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Family memories integration, emergency SOS log, and caregiver account.',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 18),

          // Caregiver Account Card
          _buildCaregiverAccountCard(caregiver),

          const SizedBox(height: 24),

          // Family Memories Management Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.photo_library_outlined, color: AppColors.violetDeep, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Family Memories',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _openAddFamilyDialog(context),
                icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                label: const Text(
                  'Add Member',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.violetDeep,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Profiles and photos stored here are automatically presented in the patient's Family Memories cognitive activities.",
            style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.3),
          ),
          const SizedBox(height: 12),

          // Family Members Grid / Cards
          ...familyMembers.map((m) => _buildFamilyMemberTile(m)),

          const SizedBox(height: 24),

          // Emergency & Location Safety Section
          Row(
            children: const [
              Icon(Icons.shield_rounded, color: AppColors.coral, size: 20),
              SizedBox(width: 8),
              Text(
                'Emergency & Location Safety',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Real-time Emergency Status Card
          _buildEmergencyStatusCard(isEmergency),

          const SizedBox(height: 14),

          // Primary Emergency Contact Card
          _buildEmergencyContactCard(emergencyContact),

          const SizedBox(height: 14),

          // Safe Home Location Card
          _buildHomeLocationCard(homeLocation),

          const SizedBox(height: 20),

          // SOS Alert History Log
          Row(
            children: const [
              Icon(Icons.history_toggle_off_rounded, color: AppColors.coral, size: 18),
              SizedBox(width: 6),
              Text(
                'SOS Alert History',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (sosLogs.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Center(
                child: Text('No emergency SOS records found.', style: TextStyle(color: AppColors.muted, fontSize: 12)),
              ),
            )
          else
            ...sosLogs.map((log) => _buildSosHistoryTile(log)),

          const SizedBox(height: 28),

          // Role Switcher & Logout
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onSwitchToPatient,
              icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.tealDark),
              label: const Text(
                'Switch to Patient Dashboard',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.tealDark),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.teal, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => context.go('/role-select'),
              icon: const Icon(Icons.logout_rounded, color: AppColors.coralDeep, size: 18),
              label: const Text(
                'Log Out',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.coralDeep),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCaregiverAccountCard(CaregiverProfile caregiver) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.teal,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              caregiver.initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caregiver.name,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  caregiver.email,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.tealPale,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        caregiver.role,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.tealDark),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Linked: ',
                      style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyMemberTile(FamilyMemoryMember member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.violetPale,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              member.avatarEmoji,
              style: const TextStyle(fontSize: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.softSection,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        member.relationship,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.violetDeep),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  member.notes,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.3),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.coralDeep),
            onPressed: () async {
              await CaregiverService.instance.deleteFamilyMember(member.id);
              setState(() {});
            },
            tooltip: 'Delete Family Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyStatusCard(bool isEmergency) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isEmergency ? AppColors.coralPale : AppColors.tealPale,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEmergency ? AppColors.coral : AppColors.teal.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isEmergency ? AppColors.coral : AppColors.teal,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEmergency ? Icons.warning_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEmergency ? 'ACTIVE EMERGENCY SOS' : 'Emergency Status: Normal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isEmergency ? AppColors.coralDeep : AppColors.tealDark,
                  ),
                ),
                Text(
                  isEmergency
                      ? 'Patient triggered emergency assistance.'
                      : 'Safe Return beacon active • Last check normal.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isEmergency ? AppColors.coralDeep : AppColors.tealDark,
                  ),
                ),
              ],
            ),
          ),
          if (isEmergency)
            ElevatedButton(
              onPressed: () async {
                final logs = CaregiverService.instance.getSosHistory();
                final unres = logs.where((l) => !l.resolved).toList();
                for (final u in unres) {
                  await CaregiverService.instance.resolveSosAlert(u.id);
                }
                setState(() {});
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral),
              child: const Text('Resolve', style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactCard(EmergencyContact contact) {
    return Container(
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
              Row(
                children: const [
                  Icon(Icons.contact_phone_outlined, color: AppColors.teal, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Primary Emergency Contact',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.phone_rounded, color: AppColors.teal, size: 20),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Simulated calling primary contact: '),
                      backgroundColor: AppColors.tealDark,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                tooltip: 'Call Primary Contact',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            ' ()',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 2),
          Text('Primary: ', style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
          if (contact.secondaryPhone.isNotEmpty)
            Text('Secondary: ', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _buildHomeLocationCard(HomeLocation home) {
    return Container(
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
              Row(
                children: const [
                  Icon(Icons.location_on_rounded, color: AppColors.amberDeep, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Patient Location & Safe Home',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.amberPale,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Within Safe Zone',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.amberDeep),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            home.address,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            'Latitude: ° N • Longitude: ° E (Radius: 500m)',
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          // Visual safe zone indicator bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const LinearProgressIndicator(
              value: 0.15, // 15% distance from center of safe radius
              backgroundColor: AppColors.softSection,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.teal),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSosHistoryTile(SosAlertLog log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            log.resolved ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
            color: log.resolved ? AppColors.teal : AppColors.coral,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ' • / :',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  log.notes,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.3),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: log.resolved ? AppColors.tealPale : AppColors.coralPale,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              log.resolved ? 'Resolved' : 'Active',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: log.resolved ? AppColors.tealDark : AppColors.coralDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAddFamilyDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String relationship = 'Son';
    String emoji = '👨';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Family Member', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Person's Name", hintText: 'e.g. Priya Das'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: relationship,
                  decoration: const InputDecoration(labelText: 'Relationship'),
                  items: const [
                    DropdownMenuItem(value: 'Son', child: Text('Son')),
                    DropdownMenuItem(value: 'Daughter', child: Text('Daughter')),
                    DropdownMenuItem(value: 'Granddaughter', child: Text('Granddaughter')),
                    DropdownMenuItem(value: 'Grandson', child: Text('Grandson')),
                    DropdownMenuItem(value: 'Spouse', child: Text('Spouse')),
                    DropdownMenuItem(value: 'Daughter-in-law', child: Text('Daughter-in-law')),
                    DropdownMenuItem(value: 'Son-in-law', child: Text('Son-in-law')),
                    DropdownMenuItem(value: 'Sibling', child: Text('Sibling')),
                    DropdownMenuItem(value: 'Friend', child: Text('Friend')),
                  ],
                  onChanged: (v) => setDlgState(() => relationship = v ?? 'Son'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: emoji,
                  decoration: const InputDecoration(labelText: 'Avatar Icon / Photo Placeholder'),
                  items: const [
                    DropdownMenuItem(value: '👨', child: Text('👨 Adult Male')),
                    DropdownMenuItem(value: '👩', child: Text('👩 Adult Female')),
                    DropdownMenuItem(value: '👧', child: Text('👧 Young Girl')),
                    DropdownMenuItem(value: '👦', child: Text('👦 Young Boy')),
                    DropdownMenuItem(value: '👵', child: Text('👵 Senior Female')),
                    DropdownMenuItem(value: '👴', child: Text('👴 Senior Male')),
                    DropdownMenuItem(value: '🧑', child: Text('🧑 Family Relative')),
                  ],
                  onChanged: (v) => setDlgState(() => emoji = v ?? '👨'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Short Memory Description',
                    hintText: 'e.g. Loves playing chess with grandfather on Sunday mornings.',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final newMember = FamilyMemoryMember(
                  id: 'fam-',
                  patientId: CaregiverService.instance.selectedPatientId,
                  name: nameCtrl.text.trim(),
                  relationship: relationship,
                  notes: noteCtrl.text.trim().isNotEmpty
                      ? noteCtrl.text.trim()
                      : 'Family member linked to cognitive exercises.',
                  avatarEmoji: emoji,
                  createdAt: DateTime.now(),
                );
                await CaregiverService.instance.addFamilyMember(newMember);
                if (mounted) {
                  Navigator.pop(ctx);
                  setState(() {});
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.violetDeep),
              child: const Text('Save Profile', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
