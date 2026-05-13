import 'package:flutter/material.dart';

abstract class AppTextStyles {
  static const String? fontFamily = null;

  static const TextStyle displayLarge = TextStyle(fontFamily: fontFamily, fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25);
  static const TextStyle displayMedium = TextStyle(fontFamily: fontFamily, fontSize: 45, fontWeight: FontWeight.w400);
  static const TextStyle headlineLarge = TextStyle(fontFamily: fontFamily, fontSize: 32, fontWeight: FontWeight.w600);
  static const TextStyle headlineMedium = TextStyle(fontFamily: fontFamily, fontSize: 28, fontWeight: FontWeight.w600);
  static const TextStyle titleLarge = TextStyle(fontFamily: fontFamily, fontSize: 22, fontWeight: FontWeight.w600);
  static const TextStyle titleMedium = TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.15);
  static const TextStyle bodyLarge = TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5);
  static const TextStyle bodyMedium = TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25);
  static const TextStyle bodySmall = TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4);
  static const TextStyle labelLarge = TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1);
  static const TextStyle labelMedium = TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5);
  static const TextStyle labelSmall = TextStyle(fontFamily: fontFamily, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5);
}
