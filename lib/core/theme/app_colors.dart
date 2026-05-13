import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/open_vts_theme.dart';

abstract class AppColors {
  static const Color primary = OpenVtsColors.brandInk;
  static const Color primaryLight = OpenVtsColors.brandInkSoft;
  static const Color primaryDark = Color(0xFF0A0A0A);
  static const Color secondary = Color(0xFF00897B);
  static const Color tertiary = Color(0xFFFF6D00);

  static const Color success = OpenVtsColors.success;
  static const Color warning = OpenVtsColors.warning;
  static const Color danger = OpenVtsColors.danger;
  static const Color info = Color(0xFF0277BD);

  static const Color vehicleMoving = Color(0xFF2D6A4F);
  static const Color vehicleStopped = Color(0xFF8A2E43);
  static const Color vehicleIdle = Color(0xFF8A5C1D);
  static const Color vehicleNoData = Color(0xFF6B6570);

  static const Color surface = OpenVtsColors.background;
  static const Color surfaceCard = OpenVtsColors.white;
  static const Color divider = OpenVtsColors.divider;
  static const Color textPrimary = OpenVtsColors.textPrimary;
  static const Color textSecondary = OpenVtsColors.textSecondary;
  static const Color textDisabled = OpenVtsColors.textTertiary;

  static const Color surfaceDark = OpenVtsColors.darkBackground;
  static const Color surfaceCardDark = OpenVtsColors.darkSurface;
  static const Color dividerDark = OpenVtsColors.darkDivider;
  static const Color textPrimaryDark = OpenVtsColors.darkTextPrimary;
}
