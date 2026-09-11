// lib/features/auth/role_selection_screen.dart
//
// Role selection screen — user picks Patient or Caregiver before logging in.
// Mirrors the React LoginModal type selection (Patient / Caregiver buttons on landing).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_logo.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              // ── Brand
              const AppLogoCentered(iconSize: 64),
              const SizedBox(height: 16),
              // ── Eyebrow
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.tealLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4BBCB0),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'MADE WITH CARE FOR NORTH EAST INDIA',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.tealDark,
                            letterSpacing: 0.09,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // ── Heading
              Text(
                'Welcome back',
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Choose how you would like to continue.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.muted,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // ── Role cards
              _RoleCard(
                icon: Icons.psychology_rounded,
                iconBg: AppColors.tealLight,
                iconColor: AppColors.teal,
                title: 'Patient',
                subtitle: 'Enter your daily cognitive care session.',
                badge: 'Elderly-Friendly',
                badgeBg: AppColors.tealLight,
                badgeColor: AppColors.tealDark,
                accentColor: AppColors.teal,
                onTap: () => context.go('/login/patient'),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.favorite_rounded,
                iconBg: AppColors.bluePale,
                iconColor: AppColors.blueDeep,
                title: 'Caregiver',
                subtitle: "Monitor your patient's care overview and activity.",
                badge: 'Care Portal',
                badgeBg: AppColors.bluePale,
                badgeColor: AppColors.blueDeep,
                accentColor: AppColors.blueDeep,
                onTap: () => context.go('/login/caregiver'),
              ),
              const SizedBox(height: 32),
              // ── Register link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "New to Smriti Care? ",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  GestureDetector(
                    onTap: () => context.go('/register'),
                    child: Text(
                      'Create account',
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
              const SizedBox(height: 24),
              // ── Trust badges
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield_rounded,
                      size: 16, color: AppColors.teal),
                  const SizedBox(width: 6),
                  Text('Safe & accessible', style: _trustStyle(context)),
                  const SizedBox(width: 20),
                  const Icon(Icons.handshake_rounded,
                      size: 16, color: AppColors.teal),
                  const SizedBox(width: 6),
                  Text('Built for care', style: _trustStyle(context)),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle? _trustStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.inkSoft,
            fontWeight: FontWeight.w600,
          );
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeBg;
  final Color badgeColor;
  final Color accentColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeBg,
    required this.badgeColor,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight, width: 1.5),
          ),
          child: Row(
            children: [
              // Icon bubble
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(width: 10),
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: badgeColor,
                              letterSpacing: 0.04,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Arrow
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: accentColor),
            ],
          ),
        ),
      ),
    );
  }
}
