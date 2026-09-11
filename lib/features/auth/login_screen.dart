```dart
// lib/features/auth/login_screen.dart
//
// Accessible Login Screen with dedicated Patient Code Login and Caregiver Login.
//
// Patients:
// - Patient code login.
// - Large code input.
// - Elderly-friendly error handling.
//
// Caregivers:
// - Email and password authentication.
// - Demo credentials.
// - Caregiver dashboard navigation.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/models/user_model.dart';
import '../../core/services/caregiver_service.dart';
import '../../core/services/patient_code_service.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/patient_code_formatter.dart';

class LoginScreen extends StatefulWidget {
  final String role;

  const LoginScreen({
    super.key,
    required this.role,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();

  late bool _isPatient;

  bool _obscurePassword = true;
  bool _isLoading = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _isPatient = widget.role.toLowerCase() == 'patient';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Patient Code Login
  // ---------------------------------------------------------------------------

  Future<void> _handlePatientCodeLogin() async {
    final rawCode = _codeController.text.trim();

    if (rawCode.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your SmritiCare code.';
      });

      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result =
          await PatientCodeService.instance.verifyPatientCode(rawCode);

      if (!mounted) {
        return;
      }

      if (result.isSuccess) {
        UserSessionService.instance.setActiveRole(
          UserRole.patient,
        );

        if (result.patientId != null &&
            result.patientId!.trim().isNotEmpty) {
          await CaregiverService.instance.selectPatient(
            result.patientId!,
          );
        }

        if (!mounted) {
          return;
        }

        setState(() {
          _isLoading = false;
        });

        context.go('/dashboard');
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result.errorMessage ??
              'That code is not correct. Please ask your caregiver to check it.';
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Unable to verify the code. Please try again.';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Caregiver and Doctor Login
  // ---------------------------------------------------------------------------

  Future<void> _handleCaregiverLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future.delayed(
      const Duration(milliseconds: 300),
    );

    if (!mounted) {
      return;
    }

    final role = widget.role.toLowerCase();

    if (role == 'doctor') {
      final result = AuthService.authenticateDoctor(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (result.success) {
        UserSessionService.instance.setActiveRole(
          UserRole.doctor,
        );

        setState(() {
          _isLoading = false;
        });

        context.go('/doctor');
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result.error;
        });
      }

      return;
    }

    final result = AuthService.authenticateCaregiver(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (result.success) {
      UserSessionService.instance.setActiveRole(
        UserRole.caregiver,
      );

      setState(() {
        _isLoading = false;
      });

      context.go('/caregiver-dashboard');
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result.error;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 24,
            color: AppColors.ink,
          ),
          onPressed: () => context.go('/role-select'),
          tooltip: 'Back to role selection',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 8,
          ),
          child: _isPatient
              ? _buildPatientCodeView()
              : _buildCaregiverView(),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Patient Login View
  // ---------------------------------------------------------------------------

  Widget _buildPatientCodeView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12),

        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.tealPale,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.teal.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.vpn_key_rounded,
            color: AppColors.teal,
            size: 46,
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          'Patient Login',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Ask your caregiver\nfor your SmritiCare code.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
            height: 1.35,
          ),
        ),

        const SizedBox(height: 36),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _errorMessage != null
                  ? AppColors.error
                  : AppColors.teal,
              width: 2.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6,
          ),
          child: TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            textInputAction: TextInputAction.done,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              color: AppColors.ink,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'SMR-____-__',
              hintStyle: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: AppColors.border,
              ),
            ),
            inputFormatters: [
              PatientCodeInputFormatter(),
            ],
            onChanged: (_) {
              if (_errorMessage != null) {
                setState(() {
                  _errorMessage = null;
                });
              }
            },
            onSubmitted: (_) => _handlePatientCodeLogin(),
          ),
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.error,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed:
                _isLoading ? null : _handlePatientCodeLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'CONTINUE',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 22,
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 28),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: AppColors.softSection,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.borderLight,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Demo Code: ',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text(
                'SMR-4827-KP',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  _codeController.text = 'SMR-4827-KP';

                  setState(() {
                    _errorMessage = null;
                  });
                },
                child: const Text(
                  'Tap to fill',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.teal,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        TextButton(
          onPressed: () {
            setState(() {
              _isPatient = false;
              _errorMessage = null;
            });
          },
          child: const Text(
            'Caregiver? Sign in with email',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.inkSoft,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Caregiver Login View
  // ---------------------------------------------------------------------------

  Widget _buildCaregiverView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.bluePale,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.blueDeep,
                    size: 32,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Caregiver Login',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Sign in to monitor your patient\'s care overview.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          const Text(
            'Email address',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.inkSoft,
            ),
          ),

          const SizedBox(height: 6),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: const InputDecoration(
              hintText: 'you@example.com',
              prefixIcon: Icon(
                Icons.email_outlined,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email.';
              }

              return null;
            },
            onChanged: (_) {
              setState(() {
                _errorMessage = null;
              });
            },
          ),

          const SizedBox(height: 18),

          const Text(
            'Password',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.inkSoft,
            ),
          ),

          const SizedBox(height: 6),

          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleCaregiverLogin(),
            decoration: InputDecoration(
              hintText: 'Enter password',
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                tooltip: _obscurePassword
                    ? 'Show password'
                    : 'Hide password',
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your password.';
              }

              return null;
            },
            onChanged: (_) {
              setState(() {
                _errorMessage = null;
              });
            },
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed:
                  _isLoading ? null : _handleCaregiverLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blueDeep,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Sign In to Care Portal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.softSection,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.borderLight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sample credentials',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppColors.inkSoft,
                  ),
                ),

                const SizedBox(height: 6),

                const _CredRow(
                  label: 'Email',
                  value: AppConstants.caregiverEmail,
                ),

                const SizedBox(height: 3),

                const _CredRow(
                  label: 'Password',
                  value: AppConstants.caregiverPassword,
                ),

                const SizedBox(height: 8),

                GestureDetector(
                  onTap: () {
                    _emailController.text =
                        AppConstants.caregiverEmail;

                    _passwordController.text =
                        AppConstants.caregiverPassword;

                    setState(() {
                      _errorMessage = null;
                    });
                  },
                  child: const Text(
                    'Tap to auto-fill',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.teal,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Center(
            child: TextButton(
              onPressed: () {
                setState(() {
                  _isPatient = true;
                  _errorMessage = null;
                });
              },
              child: const Text(
                'Patient? Enter patient code',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.teal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Demo Credentials Row
// -----------------------------------------------------------------------------

class _CredRow extends StatelessWidget {
  final String label;
  final String value;

  const _CredRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.muted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.inkSoft,
            ),
          ),
        ),
      ],
    );
  }
}
```
