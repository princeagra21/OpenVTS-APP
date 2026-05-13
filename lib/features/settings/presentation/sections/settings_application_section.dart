import 'package:flutter/material.dart';
import 'package:open_vts/features/settings/domain/config/settings_role_config.dart';
import 'package:open_vts/features/settings/presentation/routing/settings_route_resolver.dart';

class SettingsApplicationSection extends StatelessWidget {
  const SettingsApplicationSection({super.key, required this.role});

  final SettingsRole role;

  @override
  Widget build(BuildContext context) {
    return SettingsRouteResolver.buildSettingsSection(role);
  }
}
