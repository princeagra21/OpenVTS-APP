import 'package:fleet_stack/modules/superadmin/components/card/adoption_widget.dart';
import 'package:fleet_stack/modules/superadmin/components/card/fleet_card.dart';
import 'package:fleet_stack/modules/superadmin/components/card/recent_activity_box.dart';
import 'package:fleet_stack/modules/superadmin/components/card/vehicle_status_box.dart';
import 'package:fleet_stack/modules/superadmin/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fleet_stack/main.dart' show themeController;

import '../../layout/app_layout.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeIcon = isDark ? Icons.light_mode : Icons.dark_mode;

    return AppLayout(
      title: "FLEET STACK",
      subtitle: "Overview",
      // Previous action layout:
      // actionIcons: const [CupertinoIcons.search, CupertinoIcons.bell],
      // Search intentionally hidden to match Admin/User app bars.
      actionIcons: [themeIcon, CupertinoIcons.bell],
      onActionTaps: [
        () {
          final isCurrentlyDark =
              Theme.of(context).brightness == Brightness.dark;
          final newDarkMode = !isCurrentlyDark;

          themeController.setDarkMode(newDarkMode);
          AppTheme.setDarkMode(newDarkMode);

          if (AppTheme.brandColor == AppTheme.defaultBrand ||
              AppTheme.brandColor == AppTheme.defaultDarkBrand) {
            final forcedBrand = newDarkMode
                ? AppTheme.defaultDarkBrand
                : AppTheme.defaultBrand;
            themeController.setBrand(forcedBrand);
            AppTheme.setBrand(forcedBrand);
          }
        },
        () => context.push('/superadmin/notifications'),
      ],

      /// ❌ Removed onBottomTap — GoRouter handles navigation
      leftAvatarText: 'FS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          FleetOverviewBox(),
          SizedBox(height: 24),
          AdoptionGrowthBox(),
          SizedBox(height: 24),
          VehicleStatusBox(),
          SizedBox(height: 24),
          RecentActivityBox(),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}
