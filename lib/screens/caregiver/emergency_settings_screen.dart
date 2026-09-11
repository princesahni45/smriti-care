// lib/screens/caregiver/emergency_settings_screen.dart
//
// Caregiver Emergency Numbers Configuration Screen / Dialog
// Allows verified caregivers to manage Primary & Secondary Emergency Mobile Numbers.
//
// Features:
// - Primary & Secondary Mobile Number editing
// - Strict phone format validation & duplicate warning
// - Immediate local storage caching for 100% offline access
// - Automatic Firestore cloud sync when connected
// - Role-based protection: only authenticated caregivers can edit

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/emergency_service.dart';
import '../../core/services/caregiver_auth_service.dart';

class EmergencySettingsScreen extends StatefulWidget {
  final VoidCallback? onSaved;

  const EmergencySettingsScreen({super.key, this.onSaved});

  /// Static helper to open as a dialog or modal bottom sheet
  static Future<void> show(BuildContext context, {VoidCallback? onSaved}) {
    return showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: EmergencySettingsScreen(
            onSaved: () {
              Navigator.of(ctx).pop();
              if (onSaved != null) onSaved();
            },
          ),
        ),
      ),
    );
  }

  @override
  State<EmergencySettingsScreen> createState() =>
      _EmergencySettingsScreenState();
}

class _EmergencySettingsScreenState extends State<EmergencySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _primaryCtrl;
  late TextEditingController _secondaryCtrl;
  late TextEditingController _primaryNameCtrl;
  late TextEditingController _secondaryNameCtrl;
  late TextEditingController _primaryRelCtrl;
  late TextEditingController _secondaryRelCtrl;

  bool _isSaving = false;
  String? _duplicateWarning;

  @override
  void initState() {
    super.initState();
    final settings = EmergencyService.instance.settings;
    _primaryCtrl = TextEditingController(text: settings.primaryNumber);
    _secondaryCtrl = TextEditingController(text: settings.secondaryNumber);
    _primaryNameCtrl = TextEditingController(text: settings.primaryName);
    _secondaryNameCtrl = TextEditingController(text: settings.secondaryName);
    _primaryRelCtrl = TextEditingController(text: settings.primaryRelationship);
    _secondaryRelCtrl =
        TextEditingController(text: settings.secondaryRelationship);

    _primaryCtrl.addListener(_checkDuplicate);
    _secondaryCtrl.addListener(_checkDuplicate);
  }

  void _checkDuplicate() {
    final isDup = EmergencyService.areNumbersDuplicate(
        _primaryCtrl.text, _secondaryCtrl.text);
    if (isDup && _duplicateWarning == null) {
      setState(() {
        _duplicateWarning =
            'Warning: Primary and Secondary numbers are identical.';
      });
    } else if (!isDup && _duplicateWarning != null) {
      setState(() {
        _duplicateWarning = null;
      });
    }
  }

  @override
  void dispose() {
    _primaryCtrl.dispose();
    _secondaryCtrl.dispose();
    _primaryNameCtrl.dispose();
    _secondaryNameCtrl.dispose();
    _primaryRelCtrl.dispose();
    _secondaryRelCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    // Security check: Only verified caregivers can edit
    final isCaregiver = CaregiverAuthService.instance.isCaregiverAuthenticated;
    if (!isCaregiver) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr(
              'caregiver.caregiverOnlyEmergency',
              defaultText:
                  'Access Denied: Only verified caregivers can edit emergency numbers.',
            ),
          ),
          backgroundColor: AppColors.coralDeep,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final result = await EmergencyService.instance.updateEmergencyNumbers(
      primaryNumber: _primaryCtrl.text.trim(),
      secondaryNumber: _secondaryCtrl.text.trim(),
      primaryName: _primaryNameCtrl.text.trim(),
      secondaryName: _secondaryNameCtrl.text.trim(),
      primaryRelationship: _primaryRelCtrl.text.trim(),
      secondaryRelationship: _secondaryRelCtrl.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                result.isCloudSynced
                    ? Icons.cloud_done_rounded
                    : Icons.offline_pin_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.statusMessage,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.teal,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      if (widget.onSaved != null) {
        widget.onSaved!();
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.statusMessage),
          backgroundColor: AppColors.coralDeep,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ─────────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.tealPale,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.contact_phone_rounded,
                            color: AppColors.teal, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Emergency Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.close_rounded, color: AppColors.muted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Configure two emergency contact numbers for patient SOS calls and GPS SMS alerts. Stored locally on device for offline emergency use.',
                style: TextStyle(
                    fontSize: 12, color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 18),

              // ── Duplicate Warning Banner ───────────────────────────────────
              if (_duplicateWarning != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 18, color: Colors.amber.shade900),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _duplicateWarning!,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ── 1. PRIMARY EMERGENCY CONTACT ────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.teal.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.phone_in_talk_rounded,
                            color: AppColors.teal, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Primary Emergency Contact',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.tealDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _primaryCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Primary Phone Number *',
                        hintText: '+91 98765 43210',
                        prefixIcon: Icon(Icons.phone_rounded,
                            color: AppColors.teal, size: 20),
                        isDense: true,
                      ),
                      validator: (v) => EmergencyService.validatePhoneNumber(v,
                          label: 'Primary number'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _primaryNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Contact Name',
                              hintText: 'Rahul Das',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _primaryRelCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Relationship',
                              hintText: 'Son',
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── 2. SECONDARY EMERGENCY CONTACT ──────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.violet.withValues(alpha: 0.3),
                      width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.phone_forwarded_rounded,
                            color: AppColors.violet, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Secondary Emergency Contact',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.violetDeep),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _secondaryCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Secondary Phone Number *',
                        hintText: '+91 91234 56780',
                        prefixIcon: Icon(Icons.phone_rounded,
                            color: AppColors.violet, size: 20),
                        isDense: true,
                      ),
                      validator: (v) => EmergencyService.validatePhoneNumber(v,
                          label: 'Secondary number'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _secondaryNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Contact Name',
                              hintText: 'Dr. Ananya Bora',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _secondaryRelCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Relationship',
                              hintText: 'Doctor',
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ── Save Button ────────────────────────────────────────────────
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded, size: 20),
                  label: Text(
                    _isSaving ? 'Saving Numbers...' : 'Save Emergency Settings',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  onPressed: _isSaving ? null : _handleSave,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
