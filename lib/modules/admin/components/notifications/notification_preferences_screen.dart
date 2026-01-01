// components/notifications/notification_preferences_screen.dart
import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';

import 'widget/notification_general_box.dart';
import 'widget/notification_vehicle_alert_box.dart';
import 'widget/notification_system_box.dart';
import 'widget/notification_dnd_box.dart';

class NotificationPreferencesScreen extends StatelessWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;

    return AppLayout(
      title: "FLEET STACK",
      subtitle: "Notifications",
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 8,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          children: const [
            NotificationGeneralBox(),
            SizedBox(height: 24),
            NotificationVehicleAlertBox(),
            SizedBox(height: 24),
            NotificationSystemBox(),
            SizedBox(height: 24),
            NotificationDndBox(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
