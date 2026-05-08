import 'package:flutter/material.dart';
import 'package:open_vts/features/support/support_inbox_screen.dart';
import 'package:open_vts/features/support/support_role_config.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SupportInboxScreen(role: SupportRole.superadmin);
  }
}
