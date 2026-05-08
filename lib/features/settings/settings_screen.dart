import 'package:flutter/material.dart';
import 'package:open_vts/features/settings/settings_content.dart';
import 'package:open_vts/features/settings/settings_role_config.dart';

class RoleAwareSettingsScreen extends StatelessWidget {
  const RoleAwareSettingsScreen({super.key, required this.role});

  final SettingsRole role;

  @override
  Widget build(BuildContext context) {
    return RoleAwareSettingsContent(role: role);
  }
}
