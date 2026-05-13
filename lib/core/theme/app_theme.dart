import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/open_vts_theme.dart';

/// New architecture theme facade.
/// Existing OpenVTS tokens remain the visual source of truth.
class AppTheme {
  const AppTheme._();

  static ThemeData light([Color? brand]) =>
      OpenVtsTheme.light(brand ?? OpenVtsTheme.defaultBrand);

  static ThemeData dark([Color? brand]) =>
      OpenVtsTheme.dark(brand ?? OpenVtsTheme.defaultDarkBrand);
}
