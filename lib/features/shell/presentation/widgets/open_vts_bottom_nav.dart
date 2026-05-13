import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_vts/core/router/route_names.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:open_vts/features/shell/presentation/config/role_nav_config.dart';

class OpenVtsBottomNav extends StatelessWidget {
  const OpenVtsBottomNav({
    super.key,
    required this.role,
    this.currentPath,
    this.forceVisible,
    this.onTap,
  });

  final OpenVtsRole role;
  final String? currentPath;
  final bool? forceVisible;
  final ValueChanged<OpenVtsBottomNavItem>? onTap;

  @override
  Widget build(BuildContext context) {
    final config = OpenVtsRoleNavConfigs.of(role);
    final path = currentPath ?? GoRouterState.of(context).uri.path;

    final shouldShowByDefault = config.showBottomNavByDefault;
    if (forceVisible == false ||
        (!shouldShowByDefault && forceVisible != true)) {
      return const SizedBox.shrink();
    }

    if (!config.allowsRoute(path)) {
      return const SizedBox.shrink();
    }

    if (config.isBottomNavHiddenForPath(path)) {
      return const SizedBox.shrink();
    }

    int? selectedIndex = config.selectedBottomNavIndex(path);
    if (selectedIndex == null &&
        role == OpenVtsRole.admin &&
        path.startsWith(AppRoutePaths.adminDashboard)) {
      selectedIndex = 0;
    }

    if (selectedIndex == null) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final cs = Theme.of(context).colorScheme;

    final iconSize = AdaptiveUtils.getIconSize(screenWidth) * 0.85;
    final buttonSize = AdaptiveUtils.getButtonSize(screenWidth) * 0.85;
    final labelFontSize = AdaptiveUtils.getTitleFontSize(screenWidth) - 1;
    final topPadding = AdaptiveUtils.getHorizontalPadding(screenWidth) * 0.75;
    final verticalSpacing =
        AdaptiveUtils.getLeftSectionSpacing(screenWidth) * 0.75;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: AdaptiveUtils.getBottomBarHeight(screenWidth),
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.95),
            border: Border.all(
              color: cs.onSurface.withValues(alpha: 0.1),
              width: 1.3,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List<Widget>.generate(config.bottomNavItems.length, (
              index,
            ) {
              final item = config.bottomNavItems[index];
              final isSelected = index == selectedIndex;

              return CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  onTap?.call(item);
                  if (item.route != path) {
                    context.go(item.route);
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox(height: topPadding),
                    Container(
                      padding: EdgeInsets.all(buttonSize * 0.28),
                      decoration: isSelected
                          ? BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                            )
                          : null,
                      child: Icon(
                        item.icon,
                        size: iconSize,
                        color: isSelected
                            ? cs.onPrimary
                            : cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    SizedBox(height: verticalSpacing),
                    Text(
                      item.label,
                      style: AppUtils.bodySmallBase.copyWith(
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? cs.primary
                            : cs.onSurface.withValues(alpha: 0.7),
                        letterSpacing: 0.6,
                      ),
                    ),
                    SizedBox(height: verticalSpacing + 1),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
