// lib/widgets/sos_button.dart
//
// Obvious, high-contrast, elder-accessible Emergency SOS Button.
// Prominently placed on the Patient Dashboard.
// Features:
// - Elderly-friendly touch target (min height 56px, high-contrast red/coral)
// - Gentle confirmation dialog before activating to avoid panic/accidental taps
// - Immediate navigation to the Emergency SOS Two-Number Action screen

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../core/localization/app_localizations.dart';

class SosButton extends StatelessWidget {
  final VoidCallback? onTrigger;
  final bool isFullWidth;

  const SosButton({
    super.key,
    this.onTrigger,
    this.isFullWidth = true,
  });

  void _confirmSos(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.coralDeep, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.tr('sos.emergencyTitle', defaultText: 'Send Emergency Alert?'),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          context.tr('sos.safetyNotice',
              defaultText:
                  'This will obtain your current GPS coordinates and open emergency calling & messaging for your caregivers.'),
          style: const TextStyle(fontSize: 14, color: AppColors.inkSoft, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              context.tr('common.cancel', defaultText: 'Cancel'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.muted),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coralDeep,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            icon: const Icon(Icons.sos_rounded, size: 20),
            label: Text(
              context.tr('sos.sosButton', defaultText: 'Send SOS'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (onTrigger != null) {
                onTrigger!();
              } else {
                context.push('/take-me-home');
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      height: 58,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.coralDeep,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppColors.coralDeep.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.sos_rounded, size: 26, color: Colors.white),
        ),
        label: Text(
          context.tr('sos.sosButton', defaultText: 'SOS EMERGENCY HELP'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        onPressed: () => _confirmSos(context),
      ),
    );

    return isFullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
