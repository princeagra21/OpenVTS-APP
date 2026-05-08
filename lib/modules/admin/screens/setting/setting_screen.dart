import 'package:flutter/material.dart';
import 'package:open_vts/features/settings/settings_role_config.dart';
import 'package:open_vts/features/settings/settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleAwareSettingsScreen(role: SettingsRole.admin);
  }
}
