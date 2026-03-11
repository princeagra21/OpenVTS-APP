import 'dart:ui';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/superadmin/utils/app_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomBottomBar extends StatelessWidget {
  const CustomBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentPath = GoRouterState.of(context).uri.path;
    final double screenWidth = MediaQuery.of(context).size.width;
    final cs = Theme.of(context).colorScheme;

    /// Routes where bottom bar should be hidden
    const List<String> hiddenRoutes = [
      '/users/details',
      '/user/drivers/details/',
      '/user/vehicles/details/',
      '/user/profile',
      '/user/white-label',
      '/user/branding',
      '/user/api-config',
      '/user/localization',
      '/user/application-settings',
      '/user/notification-settings',
      '/user/email-settings',
      '/user/smtp-settings',
      '/user/user-policy',
      '/user/payment-gateway',
      '/user/server',
      '/user/calendar',
      '/user/roles',
      '/user/ssl',
      '/user/all-transactions',
      '/user/all-activities',
    ];

    for (final r in hiddenRoutes) {
      if (currentPath.startsWith(r)) {
        return const SizedBox.shrink();
      }
    }

    final double iconSize = AdaptiveUtils.getIconSize(screenWidth) * 0.85;
    final double buttonSize = AdaptiveUtils.getButtonSize(screenWidth) * 0.85;
    final double labelFontSize =
        AdaptiveUtils.getTitleFontSize(screenWidth) - 1;
    final double topPadding =
        AdaptiveUtils.getHorizontalPadding(screenWidth) * 0.75;
    final double verticalSpacing =
        AdaptiveUtils.getLeftSectionSpacing(screenWidth) * 0.75;

    /// UPDATED ICONS
    final List<IconData> icons = [
      CupertinoIcons.house_fill, // Home
      CupertinoIcons.map_fill, // Maps
      CupertinoIcons.map_pin_ellipse, // Landmarks
      CupertinoIcons.person_2_fill, // Admin
      CupertinoIcons.ellipsis_circle_fill, // More
    ];

    /// UPDATED LABELS
    final List<String> labels = ['Home', 'Maps', 'Geofence', 'Tools', 'More'];

    /// UPDATED ROUTES
    final List<String> routes = [
      '/user/home',
      '/user/maps',
      '/user/geofence',
      '/user/admin',
      '/user/more',
    ];

    int? currentIndex;
    for (int i = 0; i < routes.length; i++) {
      if (currentPath.startsWith(routes[i])) {
        currentIndex = i;
        break;
      }
    }

    if (currentIndex == null) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: AdaptiveUtils.getBottomBarHeight(screenWidth),
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(0.95),
            border: Border.all(
              color: cs.onSurface.withOpacity(0.1),
              width: 1.3,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(icons.length, (index) {
              final bool isSelected = index == currentIndex;

              return CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  if (routes[index] != currentPath) {
                    context.go(routes[index]);
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: topPadding),

                    /// Selected indicator + icon
                    Container(
                      padding: EdgeInsets.all(buttonSize * 0.28),
                      decoration: isSelected
                          ? BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                            )
                          : null,
                      child: Icon(
                        icons[index],
                        size: iconSize,
                        color: isSelected
                            ? cs.onPrimary
                            : cs.onSurface.withOpacity(0.7),
                      ),
                    ),

                    SizedBox(height: verticalSpacing),

                    /// Label
                    Text(
                      labels[index],
                      style: AppUtils.bodySmallBase.copyWith(
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? cs.primary
                            : cs.onSurface.withOpacity(0.7),
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
