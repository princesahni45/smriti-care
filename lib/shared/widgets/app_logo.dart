// lib/shared/widgets/app_logo.dart
//
// Brand logo widget reused across Splash, Login, and Dashboard screens.
// Mirrors the React <Logo /> component: brain icon + small heart + "Smriti Care" text.

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  final bool showText;

  const AppLogo({
    super.key,
    this.iconSize = 28.0,
    this.fontSize = 22.0,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo mark — teal rounded square with brain + small heart overlay
        _LogoMark(size: iconSize + 16),
        if (showText) ...[
          const SizedBox(width: 8),
          // FIX: Prevent RenderFlex overflow on narrow mobile screens - flexible logo text
          Flexible(
            child: Text(
              'Smriti Care',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

class _LogoMark extends StatelessWidget {
  final double size;
  const _LogoMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.tealLight,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Brain icon (primary)
          Icon(Icons.psychology_rounded,
              color: AppColors.teal, size: size * 0.56),
          // Small heart in bottom-right corner
          Positioned(
            right: -1,
            bottom: 0,
            child: Icon(
              Icons.favorite_rounded,
              color: const Color(0xFFE66D67),
              size: size * 0.30,
            ),
          ),
        ],
      ),
    );
  }
}

/// Larger centered logo for splash / auth screens
class AppLogoCentered extends StatelessWidget {
  final double iconSize;
  const AppLogoCentered({super.key, this.iconSize = 60});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LogoMark(size: iconSize),
        const SizedBox(height: 14),
        Text(
          'Smriti Care',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.ink,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Cognitive Care & Safety Platform',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
