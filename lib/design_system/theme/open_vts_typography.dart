import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/open_vts_typography.dart' as core;

import 'open_vts_colors.dart';

class OpenVtsTypography {
  const OpenVtsTypography._();

  static const String fontFamily = core.OpenVtsTypography.fontFamily;

  static TextTheme textTheme({required Brightness brightness}) {
    return core.OpenVtsTypography.textTheme(brightness: brightness);
  }

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    height: 1.2,
    letterSpacing: -0.4,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle headingLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    height: 1.25,
    letterSpacing: -0.2,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle headingMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 1.3,
    letterSpacing: -0.1,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 1.2,
    letterSpacing: 0.2,
    fontWeight: FontWeight.w600,
  );

  static TextStyle primary(TextStyle style) {
    return style.copyWith(color: OpenVtsColors.textPrimary);
  }

  static TextStyle secondary(TextStyle style) {
    return style.copyWith(color: OpenVtsColors.textSecondary);
  }

  static TextStyle tertiary(TextStyle style) {
    return style.copyWith(color: OpenVtsColors.textTertiary);
  }
}
