// lib/features/auth/login_screen.dart
//
// Login screen for both Patient and Caregiver roles.
// Mirrors React PatientLoginModal and LoginModal (Caregiver) merged into one screen.
// Shows demo credentials hint matching the React prototype.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/user_model.dart';

import '../../shared/widgets/smriti_button.dart';

class LoginScreen extends StatefulWidget {
  final String role; // 'patient' or 'caregiver'
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading       = false;
  String? _errorMessage;

  bool get _isPatient => widget.role.toLowerCase() == 'patient';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    // Simulate network delay for prototype
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;

    if (_isPatient) {
      final result = AuthService.authenticatePatient(
        _emailController.text,
        _passwordController.text,
      );
      if (result.success) {
        UserSessionService.instance.setActiveRole(UserRole.patient);
        context.go('/dashboard');
      } else {
        setState(() { _errorMessage = result.error; _isLoading = false; });
      }
    } else {
      final result = AuthService.authenticateCaregiver(
        _emailController.text,
        _passwordController.text,
      );
      if (result.success) {
        UserSessionService.instance.setActiveRole(UserRole.caregiver);
        context.go('/caregiver-dashboard');
      } else {
        setState(() { _errorMessage = result.error; _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/role-select'),
          tooltip: 'Back to role selection',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Icon bubble + title
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: _isPatient ? AppColors.tealLight : AppColors.bluePale,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          _isPatient ? Icons.psychology_rounded : Icons.favorite_rounded,
                          color: _isPatient ? AppColors.teal : AppColors.blueDeep,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isPatient ? 'Patient Login' : 'Caregiver Login',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isPatient
                            ? 'Sign in to continue your care journey.'
                            : 'Sign in to view your patient\'s care overview.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── Email field
                Text(
                  'Email address',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    hintText: 'you@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter your email.';
                    return null;
                  },
                  onChanged: (_) => setState(() => _errorMessage = null),
                ),
                const SizedBox(height: 20),

                // ── Password field
                Text(
                  'Password',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleLogin(),
                  decoration: InputDecoration(
                    hintText: 'Enter password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter your password.';
                    return null;
                  },
                  onChanged: (_) => setState(() => _errorMessage = null),
                ),
                const SizedBox(height: 16),

                // ── Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Sign In button
                SmritiButton(
                  label: 'Sign In',
                  onPressed: _handleLogin,
                  isLoading: _isLoading,
                  width: double.infinity,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                ),
                const SizedBox(height: 24),

                // ── Demo credentials hint (matching React demo-credentials div)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.softSection,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sample credentials',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.inkSoft,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _CredRow(
                        label: 'Email',
                        value: _isPatient
                            ? AppConstants.patientEmail
                            : AppConstants.caregiverEmail,
                      ),
                      const SizedBox(height: 4),
                      _CredRow(
                        label: 'Password',
                        value: _isPatient
                            ? AppConstants.patientPassword
                            : AppConstants.caregiverPassword,
                      ),
                      const SizedBox(height: 10),
                      // Quick-fill button
                      GestureDetector(
                        onTap: () {
                          _emailController.text = _isPatient
                              ? AppConstants.patientEmail
                              : AppConstants.caregiverEmail;
                          _passwordController.text = _isPatient
                              ? AppConstants.patientPassword
                              : AppConstants.caregiverPassword;
                          setState(() => _errorMessage = null);
                        },
                        child: const Text(
                          'Tap to auto-fill',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.teal,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Register link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () => context.go('/register'),
                        child: Text(
                          'Register',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.teal,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CredRow extends StatelessWidget {
  final String label;
  final String value;
  const _CredRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.inkSoft,
          ),
        ),
      ],
    );
  }
}
