import 'package:fleet_stack/components/card/adoption_widget.dart';
import 'package:fleet_stack/components/card/recent_activity_box.dart';
import 'package:fleet_stack/components/card/vehicle_status_box.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../layout/app_layout.dart';
import 'package:fleet_stack/components/card/fleet_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: "FLEET STACK",
      subtitle: "Overview",
      actionIcons: const [
        CupertinoIcons.search,
        CupertinoIcons.bell,
      ],


      /// ❌ Removed onBottomTap — GoRouter handles navigation
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
