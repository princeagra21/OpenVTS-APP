import 'package:flutter/material.dart';
import 'package:open_vts/core/router/route_names.dart';
import 'package:open_vts/features/shell/presentation/widgets/open_vts_page_title_bar.dart';

class SuperAdminHomeAppBar extends StatelessWidget {
  final String title;
  final IconData leadingIcon;
  final VoidCallback? onClose;
  final double borderRadius;

  const SuperAdminHomeAppBar({
    super.key,
    required this.title,
    required this.leadingIcon,
    this.onClose,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return OpenVtsPageTitleBar(
      title: title,
      leadingIcon: leadingIcon,
      onClose: onClose,
      fallbackRoute: AppRoutePaths.superadminHome,
      borderRadius: borderRadius,
    );
  }
}
