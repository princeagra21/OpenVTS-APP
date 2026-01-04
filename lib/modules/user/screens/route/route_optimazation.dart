import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart' show AdaptiveUtils;
import 'package:fleet_stack/modules/user/layout/app_layout.dart';
import 'package:flutter/material.dart';

class RouteOptimizationScreen extends StatelessWidget {
  const RouteOptimizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;

    return AppLayout(
      title: "USER",
      subtitle: "Route Optimization",
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 8,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          children: [
            // Add your route optimization widgets here
           Text('route optimization settings will be here'),
            SizedBox(height: 24),
            // More widgets can be added here
          ],
        ),
      ),
    );
  }
}