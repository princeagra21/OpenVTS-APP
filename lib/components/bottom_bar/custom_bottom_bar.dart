// components/bottom_bar/custom_bottom_bar.dart
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_utils.dart';
import '../../utils/adaptive_utils.dart'; // Import the shared utils

class CustomBottomBar extends StatelessWidget {
  const CustomBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentPath = GoRouterState.of(context).uri.path;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double screenWidth = MediaQuery.of(context).size.width;

    // Adaptive values from our utils
    final double iconSize = AdaptiveUtils.getIconSize(screenWidth); // 16–20
    final double buttonSize = AdaptiveUtils.getButtonSize(screenWidth); // 28–36
    final double labelFontSize = AdaptiveUtils.getTitleFontSize(screenWidth) + 1; // 12–14 (slightly bigger than title)
    final double topPadding = AdaptiveUtils.getHorizontalPadding(screenWidth); // 8–16
    final double verticalSpacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth); // 6–10

    final List<IconData> icons = [
      CupertinoIcons.house_fill,
      CupertinoIcons.map_fill,
      CupertinoIcons.person_2_fill,
      CupertinoIcons.car_detailed,
      CupertinoIcons.ellipsis_circle_fill,
    ];
    final List<String> labels = ['Home', 'Map', 'Admins', 'Vehicles', 'More'];
    final List<String> routes = [
      '/home',
      '/map',
      '/admins',
      '/vehicles',
      '/more',
    ];

    int? currentIndex;
    for (int i = 0; i < routes.length; i++) {
      if (currentPath.startsWith(routes[i])) { // use startsWith for nested routes
        currentIndex = i;
        break;
      }
    }

    // Hide bottom bar if no match (optional)
    if (currentIndex == null) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(38)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 88,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.10)
                : Colors.white.withOpacity(0.85),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.7),
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
                    SizedBox(height: topPadding), // Adaptive top spacing

                    // Selected indicator + icon
                    Container(
                      padding: EdgeInsets.all(buttonSize * 0.28), // scales with buttonSize
                      decoration: isSelected
                          ? const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            )
                          : null,
                      child: Icon(
                        icons[index],
                        size: iconSize,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.grey[500] : Colors.grey[600]),
                      ),
                    ),

                    SizedBox(height: verticalSpacing),

                    // Label
                    Text(
                      labels[index],
                      style: AppUtils.bodySmallBase.copyWith(
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? (isDark ? Colors.white : Colors.black)
                            : (isDark ? Colors.grey[500] : Colors.grey[600]),
                        letterSpacing: 0.6,
                      ),
                    ),

                    SizedBox(height: verticalSpacing + 2), // bottom padding
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