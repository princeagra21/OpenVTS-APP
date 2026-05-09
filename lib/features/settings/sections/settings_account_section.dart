import 'package:flutter/material.dart';
import 'package:open_vts/design_system/components/open_vts_components.dart';
import 'package:open_vts/features/settings/settings_role_config.dart';

class SettingsAccountSection extends StatelessWidget {
  const SettingsAccountSection({super.key, required this.role});

  final SettingsRole role;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OpenVtsSectionHeader(title: 'Account Settings'),
          const SizedBox(height: 16),
          // Add account-related widgets here
          OpenVtsListTile(
            title: 'Account Information',
            subtitle: 'View and update your account details',
            leading: const Icon(Icons.account_circle),
            onTap: () {
              // Handle account info
            },
          ),
          const OpenVtsDivider(),
          OpenVtsListTile(
            title: 'Privacy Settings',
            subtitle: 'Manage your privacy preferences',
            leading: const Icon(Icons.privacy_tip),
            onTap: () {
              // Handle privacy
            },
          ),
          // Add more account options based on role
        ],
      ),
    );
  }
}