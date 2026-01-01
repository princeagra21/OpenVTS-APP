// components/notifications/widget/notification_dnd_box.dart
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'notification_toggle_tile.dart';

class NotificationDndBox extends StatefulWidget {
  const NotificationDndBox({super.key});

  @override
  State<NotificationDndBox> createState() => _NotificationDndBoxState();
}

class _NotificationDndBoxState extends State<NotificationDndBox> {
  bool dnd = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final titleFont = AdaptiveUtils.getSubtitleFontSize(width);
    final spacing = AdaptiveUtils.getLeftSectionSpacing(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Do Not Disturb",
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: titleFont)),
        SizedBox(height: spacing),
        NotificationToggleTile(
          icon: Icons.do_not_disturb_on,
          title: "Enable DND",
          subtitle: "Mute all notifications temporarily",
          value: dnd,
          onChanged: (v) => setState(() => dnd = v),
        ),
      ],
    );
  }
}
