import 'package:flutter/material.dart';
import 'package:open_vts/design_system/components/open_vts_components.dart';
import 'package:open_vts/features/settings/settings_role_config.dart';

class SettingsThemeSection extends StatelessWidget {
  const SettingsThemeSection({super.key, required this.role});

  final SettingsRole role;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OpenVtsSectionHeader(title: 'Theme Settings'),
          const SizedBox(height: 16),
          // Add theme-related widgets here
          OpenVtsListTile(
            title: 'Light Theme',
            subtitle: 'Switch to light mode',
            leading: const Icon(Icons.light_mode),
            onTap: () {
              // Handle light theme
            },
          ),
          const OpenVtsDivider(),
          OpenVtsListTile(
            title: 'Dark Theme',
            subtitle: 'Switch to dark mode',
            leading: const Icon(Icons.dark_mode),
            onTap: () {
              // Handle dark theme
            },
          ),
          const OpenVtsDivider(),
          OpenVtsListTile(
            title: 'System Theme',
            subtitle: 'Follow system preference',
            leading: const Icon(Icons.settings_system_daydream),
            onTap: () {
              // Handle system theme
            },
          ),
          // Add more theme options
        ],
      ),
    );
  }
}