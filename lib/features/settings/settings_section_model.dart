import 'package:flutter/material.dart';

enum SettingsSectionId { profile, localization, settings }

class SettingsSectionModel {
  const SettingsSectionModel({
    required this.id,
    required this.label,
    required this.icon,
  });

  final SettingsSectionId id;
  final String label;
  final IconData icon;
}
