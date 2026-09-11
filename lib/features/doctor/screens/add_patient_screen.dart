// lib/features/doctor/screens/add_patient_screen.dart
//
// Add / Link Patient Screen for Doctor Portal.
// Enforces secure doctor-patient linking:
// Doctor enters unique Patient Link Code provided by caregiver.
// Connection request is submitted to caregiver for approval.

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../services/doctor_service.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _codeController = TextEditingController();
  bool _isSubmitting = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter a Patient Link Code.';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _statusMessage = null;
    });

    final result = await DoctorService.instance.requestPatientLink(code);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _statusMessage = result.message;
        _isSuccess = result.success;
      });

      if (result.success) {
        _codeController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Connect New Patient',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Privacy & Security Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.tealLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.security_rounded, size: 22, color: AppColors.tealDark),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Secure Privacy Protocol',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'To protect elderly patient confidentiality, physician directory browsing is disabled. You must obtain an authorization link code directly from the patient\'s family or caregiver.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Instructions Step Card
            const Text(
              'How to Link a Patient',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  _buildStepRow(
                    step: '1',
                    text: 'Ask the patient\'s caregiver to open the Caregiver Portal.',
                  ),
                  const SizedBox(height: 12),
                  _buildStepRow(
                    step: '2',
                    text: 'Caregiver navigates to "Manage Doctors" and generates a link code.',
                  ),
                  const SizedBox(height: 12),
                  _buildStepRow(
                    step: '3',
                    text: 'Enter the 6-character code below and submit your connection request.',
                  ),
                  const SizedBox(height: 12),
                  _buildStepRow(
                    step: '4',
                    text: 'Caregiver approves the request, and the patient appears in your dashboard.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Input Field Form
            const Text(
              'Enter Patient Link Code',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                  color: AppColors.tealDark,
                ),
                decoration: const InputDecoration(
                  hintText: 'e.g. SMR-2048 or SC-1234',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    letterSpacing: 0,
                    fontWeight: FontWeight.normal,
                    color: AppColors.muted,
                  ),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.vpn_key_rounded, color: AppColors.teal),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _handleSubmit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  _isSubmitting ? 'Sending Request...' : 'Send Connection Request',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            // Feedback / Status Banner
            if (_statusMessage != null) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isSuccess
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isSuccess
                        ? const Color(0xFF81C784)
                        : const Color(0xFFE57373),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                      color: _isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow({required String step, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: AppColors.tealLight,
          child: Text(
            step,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.tealDark),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppColors.ink, height: 1.3),
          ),
        ),
      ],
    );
  }
}
