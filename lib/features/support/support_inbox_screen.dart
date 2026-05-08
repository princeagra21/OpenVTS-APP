import 'package:flutter/material.dart';
import 'package:open_vts/features/support/legacy/admin_support_screen_legacy.dart'
    as admin_legacy;
import 'package:open_vts/features/support/legacy/superadmin_support_screen_legacy.dart'
    as superadmin_legacy;
import 'package:open_vts/features/support/legacy/user_support_screen_legacy.dart'
    as user_legacy;
import 'package:open_vts/features/support/support_role_config.dart';

class SupportInboxScreen extends StatelessWidget {
  const SupportInboxScreen({super.key, required this.role});

  final SupportRole role;

  @override
  Widget build(BuildContext context) {
    switch (role) {
      case SupportRole.admin:
        return const admin_legacy.SupportScreen();
      case SupportRole.user:
        return const user_legacy.SupportScreen();
      case SupportRole.superadmin:
        return const superadmin_legacy.SupportScreen();
    }
  }
}
