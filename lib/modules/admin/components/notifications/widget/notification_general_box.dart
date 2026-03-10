// components/notifications/widget/notification_general_box.dart
import 'package:fleet_stack/modules/admin/components/notifications/widget/notification_toggle_tile.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';

class NotificationGeneralBox extends StatefulWidget {
  const NotificationGeneralBox({super.key, this.onAttemptPersist});

  final VoidCallback? onAttemptPersist;

  @override
  State<NotificationGeneralBox> createState() => _NotificationGeneralBoxState();
}

class _NotificationGeneralBoxState extends State<NotificationGeneralBox> {
  bool email = true;
  bool push = true;
  bool sms = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final spacing = AdaptiveUtils.getLeftSectionSpacing(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: spacing),
        NotificationToggleTile(
          icon: Icons.notifications_active,
          title: "All Notifications",
          subtitle: "Receive app notifications",
          value: push,
          onChanged: (v) {
            setState(() => push = v);
            widget.onAttemptPersist?.call();
          },
        ),
      ],
    );
  }
}
