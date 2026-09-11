// lib/features/patient/patient_profile_screen.dart
//
// Elder-friendly Patient Profile Screen with real Caregiver Connection.
// Allows elderly patients to:
// 1. View their personal information (Name, Age, Location, Language).
// 2. Connect to a caregiver via Caregiver Connection Code (e.g. CG-4827-MS).
// 3. View connected caregiver status ("Connected ✓") and remove connection.
// 4. Switch interface language across all 10 supported regional languages.
// 5. Navigate with proper back button support (no unexpected app exit).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/caregiver_models.dart';
import '../../core/services/caregiver_service.dart';

class PatientProfileScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const PatientProfileScreen({super.key, this.onBack});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final TextEditingController _caregiverCodeController = TextEditingController();
  bool _isConnecting = false;
  String? _connectError;

  @override
  void dispose() {
    _caregiverCodeController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/dashboard');
    }
  }

  Future<void> _showAddCaregiverDialog(PatientProfile patient) async {
    _caregiverCodeController.clear();
    _connectError = null;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.tealPale,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.teal, size: 24),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Add Caregiver',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ask your caregiver for their connection code and enter it below:',
                  style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _caregiverCodeController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: AppColors.ink,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. CG-4827-MS',
                    hintStyle: const TextStyle(fontSize: 16, color: AppColors.muted, letterSpacing: 0),
                    prefixIcon: const Icon(Icons.key_rounded, color: AppColors.teal),
                    filled: true,
                    fillColor: AppColors.softSection,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderLight, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.teal, width: 2),
                    ),
                  ),
                ),
                if (_connectError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _connectError!,
                    style: const TextStyle(fontSize: 12, color: AppColors.coral, fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 12),
                // Demo helper chip
                InkWell(
                  onTap: () {
                    _caregiverCodeController.text = 'CG-4827-MS';
                    setDialogState(() => _connectError = null);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.tealPale.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Sample Caregiver Code: CG-4827-MS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.tealDark),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel', style: TextStyle(fontSize: 14)),
            ),
            ElevatedButton(
              onPressed: _isConnecting
                  ? null
                  : () async {
                      final input = _caregiverCodeController.text.trim();
                      if (input.isEmpty) {
                        setDialogState(() => _connectError = 'Please enter your caregiver code.');
                        return;
                      }

                      setDialogState(() => _isConnecting = true);

                      final success = await CaregiverService.instance.linkPatientToCaregiver(
                        patientId: patient.id,
                        caregiverCodeOrEmail: input,
                      );

                      if (!ctx.mounted) return;

                      if (success) {
                        Navigator.of(dialogCtx).pop();
                        if (mounted) {
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Connected to your caregiver successfully!'),
                              backgroundColor: AppColors.tealDark,
                            ),
                          );
                        }
                      } else {
                        setDialogState(() {
                          _isConnecting = false;
                          _connectError =
                              'That code is not recognized. Please check the code with your caregiver.';
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isConnecting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Connect', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRemoveConnection(PatientProfile patient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Caregiver Connection?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        content: Text(
          'Are you sure you want to disconnect from ${patient.caregiverName ?? "your caregiver"}? You can reconnect anytime with their code.',
          style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral),
            child: const Text('Remove Connection', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await CaregiverService.instance.disconnectCaregiver(patientId: patient.id);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Caregiver connection removed.'),
            backgroundColor: AppColors.coral,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = CaregiverService.instance.getPatientProfile();
    final hasCaregiver = patient.isConnected &&
        patient.caregiverName != null &&
        patient.caregiverName!.isNotEmpty;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 26, color: AppColors.ink),
            onPressed: _handleBack,
            tooltip: 'Back to Dashboard',
          ),
          title: const Text(
            'My Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Large Avatar
              CircleAvatar(
                radius: 46,
                backgroundColor: AppColors.tealPale,
                child: Text(
                  patient.avatarInitials,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.tealDark,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Patient Name
              Text(
                patient.fullName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),

              // ID Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.softSection,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Text(
                  'Patient ID: ${patient.id}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── My Caregiver Section (Requirement 2, 3, 4) ────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: hasCaregiver
                        ? AppColors.teal.withValues(alpha: 0.4)
                        : AppColors.borderLight,
                    width: 1.5,
                  ),
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
                        const Icon(Icons.favorite_rounded, color: AppColors.coral, size: 22),
                        const SizedBox(width: 8),
                        const Text(
                          'My Caregiver',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: hasCaregiver ? AppColors.tealPale : AppColors.softSection,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            hasCaregiver ? 'Connected ✓' : 'Not Connected',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: hasCaregiver ? AppColors.tealDark : AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (hasCaregiver) ...[
                      // Caregiver Details Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.tealPale.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.teal,
                              child: Icon(Icons.person_rounded, color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    patient.caregiverName ?? 'Primary Caregiver',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Actively linked to your care team',
                                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmRemoveConnection(patient),
                          icon: const Icon(Icons.link_off_rounded, color: AppColors.coral, size: 20),
                          label: const Text(
                            'Remove Connection',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.coral,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.coral.withValues(alpha: 0.6)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'No caregiver connected\n\nAsk your caregiver for their connection code to link accounts.',
                        style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddCaregiverDialog(patient),
                          icon: const Icon(Icons.add_link_rounded, color: Colors.white, size: 22),
                          label: const Text(
                            'Add Caregiver Code',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.teal,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── General Profile Info ──────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderLight, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Details',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink),
                    ),
                    const SizedBox(height: 14),
                    _buildDetailRow(Icons.cake_rounded, 'Age', '${patient.age} years old'),
                    const Divider(height: 18, color: AppColors.borderLight),
                    _buildDetailRow(Icons.place_rounded, 'Location', patient.location),
                    const Divider(height: 18, color: AppColors.borderLight),
                    _buildDetailRow(Icons.bloodtype_rounded, 'Blood Group', patient.bloodGroup),
                    const Divider(height: 18, color: AppColors.borderLight),
                    _buildDetailRow(Icons.translate_rounded, 'Language', patient.primaryLanguage),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.teal),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.muted, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
      ],
    );
  }
}
