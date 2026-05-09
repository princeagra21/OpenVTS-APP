import 'package:flutter/material.dart';
import 'package:open_vts/features/settings/settings_role_config.dart';
import 'package:open_vts/features/settings/settings_route_resolver.dart';
import 'package:open_vts/features/settings/settings_section_model.dart';

class SettingsSectionRouter {
  const SettingsSectionRouter();

  Widget buildRoleAppBar({
    required BuildContext context,
    required SettingsRole role,
  }) {
    return SettingsRouteResolver.buildRoleAppBar(
      context: context,
      role: role,
    );
  }

  Widget buildLocalizationSection(SettingsRole role) {
    return SettingsRouteResolver.buildLocalizationSection(role);
  }

  Widget buildSettingsSection(SettingsRole role) {
    return SettingsRouteResolver.buildSettingsSection(role);
  }

  Widget buildSection(
    SettingsSectionId section,
    SettingsRole role,
    Widget profileSection,
  ) {
    switch (section) {
      case SettingsSectionId.profile:
        return profileSection;
      case SettingsSectionId.localization:
        return buildLocalizationSection(role);
      case SettingsSectionId.settings:
        return buildSettingsSection(role);
    }
  }
}