// components/notifications/widget/notification_system_box.dart
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'notification_toggle_tile.dart';

class NotificationSystemBox extends StatefulWidget {
  const NotificationSystemBox({super.key});

  @override
  State<NotificationSystemBox> createState() =>
      _NotificationSystemBoxState();
}

class _NotificationSystemBoxState extends State<NotificationSystemBox> {
  bool updates = true;
  bool maintenance = true;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final titleFont = AdaptiveUtils.getSubtitleFontSize(width);
    final spacing = AdaptiveUtils.getLeftSectionSpacing(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("System Alerts",
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: titleFont)),
        SizedBox(height: spacing),
        NotificationToggleTile(
          icon: Icons.system_update,
          title: "System Alert",
          subtitle: "App & platform updates",
          value: updates,
          onChanged: (v) => setState(() => updates = v),
        ),
        SizedBox(height: spacing),
      //  NotificationToggleTile(
      //    icon: Icons.build,
       //   title: "Maintenance",
      //    subtitle: "Scheduled maintenance alerts",
      //    value: maintenance,
     //     onChanged: (v) => setState(() => maintenance = v),
    //    ),
      ],
    );
  }
}
