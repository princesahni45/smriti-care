// lib/core/theme/app_theme.dart
//
// Design tokens faithfully ported from the React app's styles.css and CSS custom properties.
// Primary palette: teal #157f7a, Background: #f4faf9, Ink: #173944
// Font: DM Sans (body), Merriweather/Playfair as Fraunces substitute for headings.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // ── Primary teal palette (from React --pd-teal, --color-teal)
  static const Color teal          = Color(0xFF157F7A);
  static const Color tealDark      = Color(0xFF0E6B65);
  static const Color tealDeep      = Color(0xFF063E3B);
  static const Color tealPale      = Color(0xFFD4F0ED);
  static const Color tealLight     = Color(0xFFE1F6F3);
  static const Color tealSky       = Color(0xFFE9F8F8);
  static const Color tealBg        = Color(0xFFF0FDFA);

  // ── Background / surface (from --pd-bg, --pd-surface)
  static const Color background    = Color(0xFFF4FAF9);
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color softSection   = Color(0xFFF7FBFB);

  // ── Ink / text (from --pd-ink, --color-ink)
  static const Color ink           = Color(0xFF173944);
  static const Color inkDark       = Color(0xFF0F2F38);
  static const Color inkSoft       = Color(0xFF2D5560);
  static const Color muted         = Color(0xFF66808A);
  static const Color mutedLight    = Color(0xFF7FA6A3);

  // ── Border
  static const Color border        = Color(0xFFB0D4CF);
  static const Color borderLight   = Color(0xFFE0ECEB);

  // ── Accent: blue
  static const Color blue          = Color(0xFF287BA7);
  static const Color bluePale      = Color(0xFFDAEEF9);
  static const Color blueDeep      = Color(0xFF155E8E);

  // ── Accent: violet
  static const Color violet        = Color(0xFF7162B5);
  static const Color violetDeep    = Color(0xFF4B3D9E);
  static const Color violetPale    = Color(0xFFEDE9FC);
  static const Color violetLight   = Color(0xFFF3F0FE);  // soft lavender fill (role switcher bg)
  static const Color violetBorder  = Color(0xFF9B8FD4);  // mid-violet outline (role switcher border)

  // ── Accent: coral
  static const Color coral         = Color(0xFFCE625D);
  static const Color coralDeep     = Color(0xFF9E2D26);
  static const Color coralPale     = Color(0xFFFDE8E6);

  // ── Accent: amber/gold
  static const Color amber         = Color(0xFFA87125);
  static const Color amberDeep     = Color(0xFF6B4600);
  static const Color amberPale     = Color(0xFFFFF6DF);

  // ── Dark Navy (from --color-navy, how-section bg)
  static const Color navy          = Color(0xFF123B4A);
  static const Color navyDark      = Color(0xFF133D4B);

  // ── Error
  static const Color error         = Color(0xFFB91C1C);
  static const Color errorLight    = Color(0xFFFEE2E2);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary:          AppColors.teal,
        onPrimary:        Colors.white,
        primaryContainer: AppColors.tealPale,
        onPrimaryContainer: AppColors.tealDeep,
        secondary:        AppColors.blue,
        onSecondary:      Colors.white,
        secondaryContainer: AppColors.bluePale,
        onSecondaryContainer: AppColors.blueDeep,
        tertiary:         AppColors.violet,
        onTertiary:       Colors.white,
        tertiaryContainer: AppColors.violetPale,
        onTertiaryContainer: AppColors.violetDeep,
        error:            AppColors.error,
        onError:          Colors.white,
        errorContainer:   AppColors.errorLight,
        onErrorContainer: AppColors.error,
        surface:          AppColors.surface,
        onSurface:        AppColors.ink,
        surfaceContainerHighest: AppColors.softSection,
        outline:          AppColors.border,
        outlineVariant:   AppColors.borderLight,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      textTheme: _buildTextTheme(base.textTheme),
      appBarTheme: _appBarTheme(),
      cardTheme: _cardTheme(),
      elevatedButtonTheme: _elevatedButtonTheme(),
      outlinedButtonTheme: _outlinedButtonTheme(),
      inputDecorationTheme: _inputDecorationTheme(),
      dividerTheme: const DividerThemeData(color: AppColors.borderLight, thickness: 1),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.tealPale,
        elevation: 0,
      ),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base) {
    // DM Sans for body; Playfair Display as Fraunces substitute for display/headings
    final dmSans = GoogleFonts.dmSansTextTheme(base);
    return dmSans.copyWith(
      // Display / headings → Playfair Display (closest to Fraunces available on google_fonts)
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 57, fontWeight: FontWeight.w700, letterSpacing: -1.5, color: AppColors.ink,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 45, fontWeight: FontWeight.w700, letterSpacing: -1.0, color: AppColors.ink,
      ),
      displaySmall: GoogleFonts.playfairDisplay(
        fontSize: 36, fontWeight: FontWeight.w700, letterSpacing: -0.8, color: AppColors.ink,
      ),
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: AppColors.ink,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.4, color: AppColors.ink,
      ),
      headlineSmall: GoogleFonts.playfairDisplay(
        fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: AppColors.ink,
      ),
      // Body → DM Sans
      titleLarge: GoogleFonts.dmSans(
        fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink,
      ),
      titleSmall: GoogleFonts.dmSans(
        fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.inkSoft, height: 1.65,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.inkSoft,
      ),
      bodySmall: GoogleFonts.dmSans(
        fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.muted,
      ),
      labelLarge: GoogleFonts.dmSans(
        fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink,
      ),
      labelMedium: GoogleFonts.dmSans(
        fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted,
      ),
      labelSmall: GoogleFonts.dmSans(
        fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.08, color: AppColors.muted,
      ),
    );
  }

  static AppBarTheme _appBarTheme() => AppBarTheme(
    backgroundColor: AppColors.surface,
    foregroundColor: AppColors.ink,
    elevation: 0,
    shadowColor: Colors.black12,
    scrolledUnderElevation: 2,
    titleTextStyle: GoogleFonts.dmSans(
      fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink,
    ),
    iconTheme: const IconThemeData(color: AppColors.ink),
  );

  static CardThemeData _cardTheme() => CardThemeData(
    color: AppColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: AppColors.borderLight),
    ),
    margin: EdgeInsets.zero,
  );

  static ElevatedButtonThemeData _elevatedButtonTheme() => ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.teal,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      minimumSize: const Size(0, 52),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700),
    ),
  );

  static OutlinedButtonThemeData _outlinedButtonTheme() => OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.tealDark,
      side: const BorderSide(color: AppColors.border, width: 1.5),
      minimumSize: const Size(0, 52),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700),
    ),
  );

  static InputDecorationTheme _inputDecorationTheme() => InputDecorationTheme(
    filled: true,
    fillColor: AppColors.softSection,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.teal, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    labelStyle: GoogleFonts.dmSans(color: AppColors.inkSoft, fontWeight: FontWeight.w600),
    hintStyle: GoogleFonts.dmSans(color: AppColors.muted),
  );
}
