import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_vts/features/shell/presentation/widgets/open_vts_page_title_bar.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onClose;
  final IconData leadingIcon;
  final String? fallbackRoute;

  const TopBar({
    super.key,
    required this.title,
    this.onClose,
    this.leadingIcon = Icons.dashboard_outlined,
    this.fallbackRoute,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OpenVtsPageTitleBar(
        title: title,
        leadingIcon: leadingIcon,
        fallbackRoute: fallbackRoute,
        onClose: onClose ??
            () {
              final router = GoRouter.of(context);
              if (router.canPop()) {
                context.pop();
              }
            },
        borderRadius: 0,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
