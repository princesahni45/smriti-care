// lib/screens/placeholder_screen.dart
//
// Clean, accessible "Coming Soon" screen for non-dashboard modules.
// Features large text, high contrast, warm iconography, and easy return navigation.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String? detailedNote;
  final VoidCallback? onBack;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.accentColor = AppColors.teal,
    this.detailedNote,
    this.onBack,
  });

  /// Factory helper for standard placeholder modules
  factory PlaceholderScreen.forModule(String moduleId, {VoidCallback? onBack}) {
    switch (moduleId.toLowerCase()) {
      case 'games':
        return PlaceholderScreen(
          title: 'Cognitive Games',
          subtitle: 'Fun & gentle brain activities',
          icon: Icons.psychology_rounded,
          accentColor: AppColors.teal,
          detailedNote:
              'Memory Match, Word Recall, and Pattern Recognition games are currently being prepared for mobile play.',
          onBack: onBack,
        );
      case 'reminders':
        return PlaceholderScreen(
          title: 'Smart Reminders',
          subtitle: 'Daily medicine & activity schedule',
          icon: Icons.access_time_filled_rounded,
          accentColor: AppColors.amber,
          detailedNote:
              'Gentle voice and visual reminders for medications, hydration, and appointments will appear here.',
          onBack: onBack,
        );
      case 'emergency':
        return PlaceholderScreen(
          title: 'Emergency SOS',
          subtitle: 'Immediate family & caregiver alert',
          icon: Icons.emergency_rounded,
          accentColor: AppColors.coral,
          detailedNote:
              'One-tap emergency dialing, location sharing, and caregiver notification system.',
          onBack: onBack,
        );
      case 'location':
        return PlaceholderScreen(
          title: 'Safe Return Home',
          subtitle: 'Offline guidance to your home',
          icon: Icons.location_on_rounded,
          accentColor: AppColors.blue,
          detailedNote:
              'Large visual arrows, spoken directions, and saved home coordinates to guide you safely home.',
          onBack: onBack,
        );
      case 'progress':
        return PlaceholderScreen(
          title: 'Your Progress',
          subtitle: 'Cognitive activity summary',
          icon: Icons.bar_chart_rounded,
          accentColor: AppColors.violet,
          detailedNote:
              'Weekly engagement graphs, streak tracking, and memory score overviews will be accessible here.',
          onBack: onBack,
        );
      case 'caregiver':
        return PlaceholderScreen(
          title: 'Caregiver Portal',
          subtitle: 'Connected caregiver support',
          icon: Icons.family_restroom_rounded,
          accentColor: AppColors.navy,
          detailedNote:
              'View caregiver contact Mohak Singh, send updates, and manage care settings.',
          onBack: onBack,
        );
      case 'profile':
        return PlaceholderScreen(
          title: 'Patient Profile',
          subtitle: 'Personal details & preferences',
          icon: Icons.account_circle_rounded,
          accentColor: AppColors.tealDark,
          detailedNote:
              'Mr. Ramesh Das • ID: MC-2048 • Age: 72 • Language preferences and accessibility settings.',
          onBack: onBack,
        );
      default:
        return PlaceholderScreen(
          title: 'Feature Coming Soon',
          subtitle: 'Under active development',
          icon: Icons.construction_rounded,
          accentColor: AppColors.teal,
          detailedNote:
              'This Smriti Care feature is being fine-tuned for a comfortable elderly experience.',
          onBack: onBack,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              size: 28, color: AppColors.ink),
          tooltip: 'Back to Dashboard',
          onPressed: onBack ??
              () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go('/');
                }
              },
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.borderLight, height: 1),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Soft colored hero bubble
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.28),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(icon, size: 52, color: accentColor),
                  ),
                ),
                const SizedBox(height: 24),

                // Coming Soon Pill Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.amberPale,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: AppColors.amber.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          size: 16, color: AppColors.amber),
                      SizedBox(width: 6),
                      Text(
                        'COMING SOON',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: AppColors.amberDeep,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Title & Subtitle
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 24),

                // Informational Card
                if (detailedNote != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border:
                          Border.all(color: AppColors.borderLight, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 24, color: accentColor),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            detailedNote!,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.45,
                              color: AppColors.inkDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 36),

                // Large readable return button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.home_rounded, size: 24),
                    label: const Text(
                      'Back to Dashboard',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: onBack ??
                        () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            context.go('/');
                          }
                        },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
