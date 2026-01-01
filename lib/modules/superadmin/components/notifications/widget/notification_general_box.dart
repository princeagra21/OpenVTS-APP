// components/notifications/widget/notification_general_box.dart
import 'package:fleet_stack/modules/superadmin/components/notifications/widget/notification_toggle_tile.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';

class NotificationGeneralBox extends StatefulWidget {
  const NotificationGeneralBox({super.key});

  @override
  State<NotificationGeneralBox> createState() =>
      _NotificationGeneralBoxState();
}

class _NotificationGeneralBoxState extends State<NotificationGeneralBox> {
  bool email = true;
  bool push = true;
  bool sms = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final titleFont = AdaptiveUtils.getSubtitleFontSize(width);
    final spacing = AdaptiveUtils.getLeftSectionSpacing(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("General Notifications",
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: titleFont)),
        SizedBox(height: spacing),
        NotificationToggleTile(
          icon: Icons.notifications_active,
          title: "Push Notifications",
          subtitle: "Receive app notifications",
          value: push,
          onChanged: (v) => setState(() => push = v),
        ),
        SizedBox(height: spacing),
        NotificationToggleTile(
          icon: Icons.email,
          title: "Email Notifications",
          subtitle: "Receive alerts via email",
          value: email,
          onChanged: (v) => setState(() => email = v),
        ),
        SizedBox(height: spacing),
        NotificationToggleTile(
          icon: Icons.sms,
          title: "SMS Alerts",
          subtitle: "Critical alerts via SMS",
          value: sms,
          onChanged: (v) => setState(() => sms = v),
        ),
      ],
    );
  }
}
