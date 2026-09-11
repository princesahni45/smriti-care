// lib/features/auth/register_screen.dart
//
// Registration screen — placeholder UI (no backend yet).
// Allows entering name, email, password, and selecting a role.
// TODO: Connect to Firebase Auth / FastAPI backend in a later task.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/smriti_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String _selectedRole = 'patient';
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // TODO: Integrate with Firebase Auth / FastAPI /api/v1/auth/register
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      // Show placeholder success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Registration coming soon — Firebase integration pending (Task 2).',
          ),
          backgroundColor: AppColors.teal,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    });
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
          tooltip: 'Back',
        ),
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.violetPale,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.person_add_rounded,
                          color: AppColors.violetDeep,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Join Smriti Care',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Create an account to get started.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.muted,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── Role selector (matching React role context)
                Text('I am a', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _RoleChip(
                      label: 'Patient',
                      icon: Icons.psychology_rounded,
                      isSelected: _selectedRole == 'patient',
                      onTap: () => setState(() => _selectedRole = 'patient'),
                    ),
                    const SizedBox(width: 12),
                    _RoleChip(
                      label: 'Caregiver',
                      icon: Icons.favorite_rounded,
                      isSelected: _selectedRole == 'caregiver',
                      onTap: () => setState(() => _selectedRole = 'caregiver'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Full name
                const _FieldLabel('Full name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Your full name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter your name.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // ── Email
                const _FieldLabel('Email address'),
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
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter your email.';
                    }
                    if (!v.contains('@')) {
                      return 'Please enter a valid email.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // ── Password
                const _FieldLabel('Password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Create a password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 6) {
                      return 'Password must be at least 6 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // ── Confirm password
                const _FieldLabel('Confirm password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleRegister(),
                  decoration: InputDecoration(
                    hintText: 'Repeat your password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v != _passwordController.text) {
                      return 'Passwords do not match.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // ── Register button
                SmritiButton(
                  label: 'Create Account',
                  onPressed: _handleRegister,
                  isLoading: _isLoading,
                  width: double.infinity,
                  icon:
                      const Icon(Icons.check_circle_outline_rounded, size: 18),
                ),
                const SizedBox(height: 20),

                // ── Sign in link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ',
                          style: Theme.of(context).textTheme.bodyMedium),
                      GestureDetector(
                        onTap: () => context.go('/role-select'),
                        child: Text(
                          'Sign in',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
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

                // ── Backend notice
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.amberPale,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 18, color: AppColors.amberDeep),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Registration will be connected to Firebase Auth in Task 2. This is a UI placeholder.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.amberDeep,
                                    fontWeight: FontWeight.w600,
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

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.labelLarge);
}

class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.tealLight : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.teal : AppColors.borderLight,
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18, color: isSelected ? AppColors.teal : AppColors.muted),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.tealDark : AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
