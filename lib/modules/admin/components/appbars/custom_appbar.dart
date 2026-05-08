import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:open_vts/app/router/app_route_paths.dart';
import 'package:open_vts/features/shell/open_vts_app_bar.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.icons,
    this.onIconTaps,
    this.enableBellBadge = true,
    this.notificationPathPrefix = AppRoutePaths.adminNotifications,
    this.showLeftAvatar = true,
    this.showRightAvatar = false,
    required this.leftAvatarText,
    this.showLogo = false,
    this.scrollOffset = 0,
  });

  final String title;
  final String subtitle;
  final List<IconData>? icons;
  final List<VoidCallback>? onIconTaps;
  final bool enableBellBadge;
  final String notificationPathPrefix;
  final bool showLeftAvatar;
  final bool showRightAvatar;
  final String leftAvatarText;
  final bool showLogo;
  final double scrollOffset;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return OpenVtsAppBar(
      title: title,
      subtitle: subtitle,
      icons: icons,
      onIconTaps: onIconTaps,
      enableBellBadge: enableBellBadge,
      notificationPathPrefix: notificationPathPrefix,
      showLeftAvatar: showLeftAvatar,
      showRightAvatar: showRightAvatar,
      leftAvatarText: leftAvatarText,
      showLogo: showLogo,
      scrollOffset: scrollOffset,
      variant: OpenVtsAppBarVariant.standard,
    );
  }
}
