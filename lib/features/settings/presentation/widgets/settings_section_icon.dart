import 'package:flutter/material.dart';

class SettingsSectionIcon {
  const SettingsSectionIcon._();

  static IconData resolve(String key) {
    switch (key) {
      case 'person':
        return Icons.person_outline;
      case 'language':
        return Icons.language;
      case 'settings':
        return Icons.tune;
      default:
        return Icons.settings_outlined;
    }
  }
}
