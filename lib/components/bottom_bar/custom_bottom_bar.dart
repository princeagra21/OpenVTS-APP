import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_utils.dart';

class CustomBottomBar extends StatelessWidget {
  const CustomBottomBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final String currentPath = GoRouterState.of(context).uri.path;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

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
      if (currentPath == routes[i]) {
        currentIndex = i;
        break;
      }
    }

    if (currentIndex == null) {
      return const SizedBox.shrink();
    }

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
              return GestureDetector(
                onTap: () => context.go(routes[index]),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: isSelected
                          ? const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            )
                          : null,
                      child: Icon(
                        icons[index],
                        size: 22,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.grey[500] : Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[index],
                      style: AppUtils.bodySmallBase.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
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