import 'package:flutter/material.dart';

import 'open_vts_colors.dart';

class OpenVtsTypography {
  static const String fontFamily = 'Satoshi';

  static TextTheme textTheme({required Brightness brightness}) {
    final bool isDark = brightness == Brightness.dark;
    final Color primary = isDark
        ? OpenVtsColors.darkTextPrimary
        : OpenVtsColors.textPrimary;
    final Color secondary = isDark
        ? OpenVtsColors.darkTextSecondary
        : OpenVtsColors.textSecondary;

    return TextTheme(
      headlineLarge: _style(
        size: 32,
        weight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.4,
        height: 1.2,
      ),
      headlineMedium: _style(
        size: 28,
        weight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.3,
        height: 1.2,
      ),
      headlineSmall: _style(
        size: 24,
        weight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.2,
        height: 1.25,
      ),
      titleLarge: _style(
        size: 20,
        weight: FontWeight.w600,
        color: primary,
        letterSpacing: -0.1,
        height: 1.3,
      ),
      titleMedium: _style(
        size: 16,
        weight: FontWeight.w600,
        color: primary,
        letterSpacing: 0,
        height: 1.35,
      ),
      titleSmall: _style(
        size: 14,
        weight: FontWeight.w600,
        color: primary,
        letterSpacing: 0,
        height: 1.35,
      ),
      bodyLarge: _style(
        size: 16,
        weight: FontWeight.w400,
        color: primary,
        letterSpacing: 0,
        height: 1.45,
      ),
      bodyMedium: _style(
        size: 14,
        weight: FontWeight.w400,
        color: primary,
        letterSpacing: 0,
        height: 1.45,
      ),
      bodySmall: _style(
        size: 12,
        weight: FontWeight.w400,
        color: secondary,
        letterSpacing: 0,
        height: 1.4,
      ),
      labelLarge: _style(
        size: 14,
        weight: FontWeight.w600,
        color: primary,
        letterSpacing: 0.2,
        height: 1.2,
      ),
      labelMedium: _style(
        size: 12,
        weight: FontWeight.w600,
        color: primary,
        letterSpacing: 0.2,
        height: 1.2,
      ),
      labelSmall: _style(
        size: 11,
        weight: FontWeight.w500,
        color: secondary,
        letterSpacing: 0.2,
        height: 1.2,
      ),
    );
  }

  static TextStyle _style({
    required double size,
    required FontWeight weight,
    required Color color,
    required double letterSpacing,
    required double height,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}
