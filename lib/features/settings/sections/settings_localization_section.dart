import 'package:flutter/material.dart';
import 'package:open_vts/features/settings/settings_role_config.dart';
import 'package:open_vts/features/settings/settings_route_resolver.dart';

class SettingsLocalizationSection extends StatelessWidget {
  const SettingsLocalizationSection({super.key, required this.role});

  final SettingsRole role;

  @override
  Widget build(BuildContext context) {
    return SettingsRouteResolver.buildLocalizationSection(role);
  }
}