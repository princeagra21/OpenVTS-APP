import 'package:flutter/material.dart';
import 'package:open_vts/design_system/components/open_vts_components.dart';
import 'package:open_vts/features/settings/settings_role_config.dart';

class SettingsSecuritySection extends StatelessWidget {
  const SettingsSecuritySection({super.key, required this.role});

  final SettingsRole role;

  @override
  Widget build(BuildContext context) {
    return OpenVtsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OpenVtsSectionHeader(title: 'Security Settings'),
          const SizedBox(height: 16),
          // Add security-related widgets here
          OpenVtsListTile(
            title: 'Change Password',
            subtitle: 'Update your account password',
            leading: const Icon(Icons.lock),
            onTap: () {
              // Handle change password
            },
          ),
          const OpenVtsDivider(),
          OpenVtsListTile(
            title: 'Two-Factor Authentication',
            subtitle: 'Add an extra layer of security',
            leading: const Icon(Icons.security),
            onTap: () {
              // Handle 2FA
            },
          ),
          // Add more security options based on role
        ],
      ),
    );
  }
}