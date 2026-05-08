import 'package:flutter/material.dart';
import 'package:open_vts/features/shell/open_vts_bottom_nav.dart';
import 'package:open_vts/features/shell/role_nav_config.dart';

class CustomBottomBar extends StatelessWidget {
  const CustomBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const OpenVtsBottomNav(role: OpenVtsRole.admin, forceVisible: true);
  }
}
