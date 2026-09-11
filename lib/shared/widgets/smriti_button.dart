// lib/shared/widgets/smriti_button.dart
//
// Reusable button components matching the React .btn-primary and .btn-secondary styles.
// Ensures minimum 52px height for elderly accessibility (React uses 48px min).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

enum SmritiButtonKind { primary, secondary }

class SmritiButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final SmritiButtonKind kind;
  final Widget? icon;
  final bool isLoading;
  final double? width;

  const SmritiButton({
    super.key,
    required this.label,
    this.onPressed,
    this.kind = SmritiButtonKind.primary,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  const SmritiButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
  }) : kind = SmritiButtonKind.secondary;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: kind == SmritiButtonKind.primary
                  ? Colors.white
                  : AppColors.teal,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label),
              if (icon != null) ...[const SizedBox(width: 8), icon!],
            ],
          );

    final textStyle =
        GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700);
    final minSize = Size(width ?? 0, 52);

    Widget button;
    if (kind == SmritiButtonKind.primary) {
      button = ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          minimumSize: minSize,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: textStyle,
          elevation: 0,
        ),
        child: child,
      );
    } else {
      button = OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.tealDark,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          minimumSize: minSize,
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: textStyle,
        ),
        child: child,
      );
    }

    if (width != null) {
      return SizedBox(width: width, child: button);
    }
    return button;
  }
}

/// Large patient-friendly button with 64px height (pd-dashboard-card touch target)
class PatientActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Widget? leading;

  const PatientActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.backgroundColor = AppColors.teal,
    this.foregroundColor = Colors.white,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle:
              GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            Text(label),
          ],
        ),
      ),
    );
  }
}

/// Chip / badge widget matching React .icon-bubble pattern
class IconBubble extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color foregroundColor;
  final double size;

  const IconBubble({
    super.key,
    required this.child,
    required this.backgroundColor,
    required this.foregroundColor,
    this.size = 44,
  });

  factory IconBubble.teal(
          {required IconData icon, double size = 44, Key? key}) =>
      IconBubble(
        key: key,
        backgroundColor: AppColors.tealLight,
        foregroundColor: AppColors.tealDark,
        size: size,
        child: Icon(icon, size: size * 0.48),
      );

  factory IconBubble.blue(
          {required IconData icon, double size = 44, Key? key}) =>
      IconBubble(
        key: key,
        backgroundColor: AppColors.bluePale,
        foregroundColor: AppColors.blueDeep,
        size: size,
        child: Icon(icon, size: size * 0.48),
      );

  factory IconBubble.violet(
          {required IconData icon, double size = 44, Key? key}) =>
      IconBubble(
        key: key,
        backgroundColor: AppColors.violetPale,
        foregroundColor: AppColors.violetDeep,
        size: size,
        child: Icon(icon, size: size * 0.48),
      );

  factory IconBubble.coral(
          {required IconData icon, double size = 44, Key? key}) =>
      IconBubble(
        key: key,
        backgroundColor: AppColors.coralPale,
        foregroundColor: AppColors.coralDeep,
        size: size,
        child: Icon(icon, size: size * 0.48),
      );

  factory IconBubble.amber(
          {required IconData icon, double size = 44, Key? key}) =>
      IconBubble(
        key: key,
        backgroundColor: AppColors.amberPale,
        foregroundColor: AppColors.amberDeep,
        size: size,
        child: Icon(icon, size: size * 0.48),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size * 0.30),
      ),
      child: IconTheme(
        data: IconThemeData(color: foregroundColor, size: size * 0.48),
        child: child,
      ),
    );
  }
}
