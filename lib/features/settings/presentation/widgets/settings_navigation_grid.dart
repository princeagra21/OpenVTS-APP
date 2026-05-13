import 'package:flutter/material.dart';
import 'package:open_vts/features/settings/domain/config/settings_role_config.dart';
import 'package:open_vts/features/settings/domain/entities/settings_section_model.dart';
import 'package:open_vts/features/settings/presentation/widgets/settings_group.dart';

class SettingsNavigationGrid extends StatelessWidget {
  const SettingsNavigationGrid({
    super.key,
    required this.config,
    required this.selectedSection,
    required this.onSectionSelected,
  });

  final SettingsRoleConfig config;
  final SettingsSectionId selectedSection;
  final ValueChanged<SettingsSectionId> onSectionSelected;

  @override
  Widget build(BuildContext context) {
    return SettingsGroup(
      title: 'System Settings',
      subtitle: config.subtitle,
      sections: config.availableSections,
      selectedSection: selectedSection,
      onSectionSelected: onSectionSelected,
    );
  }
}
