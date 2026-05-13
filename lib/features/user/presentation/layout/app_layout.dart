import 'package:flutter/material.dart';
import 'package:open_vts/features/shell/presentation/widgets/open_vts_app_shell.dart';
import 'package:open_vts/features/shell/presentation/config/role_nav_config.dart';

class AppLayout extends StatelessWidget {
  const AppLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.leftAvatarText,
    this.actionIcons,
    this.onActionTaps,
    this.showLeftAvatar = true,
    this.showRightAvatar = false,
    this.horizontalPadding = 20.0,
    this.showAppBar = true,
    this.disableAppBarLeading = true,
    this.customTopBar,
    this.customTopBarPadding = EdgeInsets.zero,
    this.customTopBarHeight,
  });

  final String title;
  final String subtitle;
  final List<IconData>? actionIcons;
  final List<VoidCallback>? onActionTaps;
  final Widget child;

  final bool showLeftAvatar;
  final bool showRightAvatar;
  final String leftAvatarText;

  final double horizontalPadding;
  final bool showAppBar;
  final bool disableAppBarLeading;

  final Widget? customTopBar;
  final EdgeInsets customTopBarPadding;
  final double? customTopBarHeight;

  @override
  Widget build(BuildContext context) {
    return OpenVtsAppShell(
      role: OpenVtsRole.user,
      title: title,
      subtitle: subtitle,
      actionIcons: actionIcons,
      onActionTaps: onActionTaps,
      showLeftAvatar: showLeftAvatar,
      showRightAvatar: showRightAvatar,
      leftAvatarText: leftAvatarText,
      horizontalPadding: horizontalPadding,
      showAppBar: showAppBar,
      showBottomBar: false,
      disableAppBarLeading: disableAppBarLeading,
      customTopBar: customTopBar,
      customTopBarPadding: customTopBarPadding,
      customTopBarHeight: customTopBarHeight,
      child: child,
    );
  }
}

class UserLayout extends AppLayout {
  const UserLayout({
    super.key,
    required super.title,
    required super.subtitle,
    required super.child,
    required super.leftAvatarText,
    super.actionIcons,
    super.onActionTaps,
    super.showLeftAvatar,
    super.showRightAvatar,
    super.horizontalPadding,
    super.showAppBar,
    super.disableAppBarLeading,
    super.customTopBar,
    super.customTopBarPadding,
    super.customTopBarHeight,
  });
}
