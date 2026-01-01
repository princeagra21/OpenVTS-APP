// components/notifications/widget/notification_vehicle_alert_box.dart
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'notification_toggle_tile.dart';

class NotificationVehicleAlertBox extends StatefulWidget {
  const NotificationVehicleAlertBox({super.key});

  @override
  State<NotificationVehicleAlertBox> createState() =>
      _NotificationVehicleAlertBoxState();
}

class _NotificationVehicleAlertBoxState
    extends State<NotificationVehicleAlertBox> {
  bool offline = true;
  bool overspeed = true;
  bool ignition = true;
  bool geofence = false;
  bool sos = true;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final titleFont = AdaptiveUtils.getSubtitleFontSize(width);
    final spacing = AdaptiveUtils.getLeftSectionSpacing(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Vehicle Alerts",
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: titleFont)),
        SizedBox(height: spacing),
        NotificationToggleTile(
          icon: Icons.signal_wifi_off,
          title: "Vehicle Offline",
          subtitle: "Alert when vehicle goes offline",
          value: offline,
          onChanged: (v) => setState(() => offline = v),
        ),
        SizedBox(height: spacing),
        NotificationToggleTile(
          icon: Icons.speed,
          title: "Overspeed",
          subtitle: "Speed limit exceeded",
          value: overspeed,
          onChanged: (v) => setState(() => overspeed = v),
        ),
        SizedBox(height: spacing),
        NotificationToggleTile(
          icon: Icons.power,
          title: "Ignition",
          subtitle: "Vehicle ignition status",
          value: ignition,
          onChanged: (v) => setState(() => ignition = v),
        ),
        SizedBox(height: spacing),
        NotificationToggleTile(
          icon: Icons.location_on,
          title: "Geofence",
          subtitle: "Enter or exit geofence area",
          value: geofence,
          onChanged: (v) => setState(() => geofence = v),
        ),
        SizedBox(height: spacing),
        NotificationToggleTile(
          icon: Icons.sos,
          title: "SOS",
          subtitle: "Emergency SOS alerts",
          value: sos,
          onChanged: (v) => setState(() => sos = v),
        ),
      ],
    );
  }
}
