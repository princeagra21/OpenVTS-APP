// lib/screens/vehicle_toggle_screen.dart
import 'package:fleet_stack/modules/user/layout/app_layout.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/user/screens/notification/notification_toggle_tile.dart';
import 'package:flutter/material.dart';


class VehicleToggleScreen extends StatefulWidget {
  final String vehicleId;

  const VehicleToggleScreen({super.key, required this.vehicleId});

  @override
  State<VehicleToggleScreen> createState() => _VehicleToggleScreenState();
}

class _VehicleToggleScreenState extends State<VehicleToggleScreen> {
  bool ignitionOn = true;
  bool ignitionOff = true;
  bool sos = true;
  bool powerCut = true;
  bool vibration = true;
  bool lowBattery = true;
  bool hardBraking = true;
  bool hardAcceleration = true;
  bool hardCornering = true;
  bool tampering = true;
  bool powerOn = true;
  bool powerOff = true;
  bool accident = true;
  bool powerRestored = true;
  bool shock = true;
  bool parkingEnable = true;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;
    final double titleFont = AdaptiveUtils.getSubtitleFontSize(width);
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(width);

    return AppLayout(
      title: "FLEET STACK",
      subtitle: "Notifications for ${widget.vehicleId}",
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 8,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Alerts",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: titleFont,
              ),
            ),
            SizedBox(height: spacing),
            NotificationToggleTile(
              icon: Icons.power_settings_new,
              title: "Ignition On",
              subtitle: "Receive notifications for ignition on",
              value: ignitionOn,
              onChanged: (v) => setState(() => ignitionOn = v),
            ),
            SizedBox(height: spacing),
            NotificationToggleTile(
              icon: Icons.power_settings_new,
              title: "Ignition Off",
              subtitle: "Receive notifications for ignition off",
              value: ignitionOff,
              onChanged: (v) => setState(() => ignitionOff = v),
            ),
            SizedBox(height: spacing),
            NotificationToggleTile(
              icon: Icons.warning_amber_rounded,
              title: "SOS",
              subtitle: "Receive notifications for SOS",
              value: sos,
              onChanged: (v) => setState(() => sos = v),
            ),
            SizedBox(height: spacing),
            NotificationToggleTile(
              icon: Icons.power_off,
              title: "Power Cut",
              subtitle: "Receive notifications for power cut",
              value: powerCut,
              onChanged: (v) => setState(() => powerCut = v),
            ),
            SizedBox(height: spacing),
            NotificationToggleTile(
              icon: Icons.vibration,
              title: "Vibration",
              subtitle: "Receive notifications for vibration",
              value: vibration,
              onChanged: (v) => setState(() => vibration = v),
            ),
            SizedBox(height: spacing),
            NotificationToggleTile(
              icon: Icons.battery_alert,
              title: "Low Battery",
              subtitle: "Receive notifications for low battery",
              value: lowBattery,
              onChanged: (v) => setState(() => lowBattery = v),
            ),
            SizedBox(height: spacing),
            NotificationToggleTile(
              icon: Icons.car_repair,
              title: "Hard Braking",
              subtitle: "Receive notifications for hard braking",
              value: hardBraking,
              onChanged: (v) => setState(() => hardBraking = v),
            ),
            SizedBox(height: spacing),
            NotificationToggleTile(
              icon: Icons.speed,
              title: "Hard Acceleration",
              subtitle: "Receive notifications for hard acceleration",
              value: hardAcceleration,
              onChanged: (v) => setState(() => hardAcceleration = v),
            ),
            SizedBox(height: spacing),
            NotificationToggleTile(
              icon: Icons.turn_sharp_right,
              title: "Hard Cornering",
              subtitle: "Receive notifications for hard cornering",
              value: hardCornering,
              onChanged: (v) => setState(() => hardCornering = v),
            ),
            SizedBox(height: spacing),
            NotificationToggleTile(
              icon: Icons.security,
              title: "Tampering",
              subtitle: "Receive notifications for tampering",
              value: tampering,
              onChanged: (v) => setState(() => tampering = v),
            ),
            SizedBox(height: spacing),
            NotificationToggleTile(
              icon: Icons.power,
              title: "Power On",
              subtitle: "Receive notifications for power on",
              value: powerOn,
              onChanged: (v) => setState(() => powerOn = v),
            ),
            SizedBox(height: spacing),
            NotificationToggleTile(
              icon: Icons.power_off,
              title: "Power Off",
              subtitle: "Receive notifications for power off",
              value: powerOff,
              onChanged: (v) => setState(() => powerOff = v),
            ),
            SizedBox(height: spacing),
            NotificationToggleTile(
              icon: Icons.car_crash,
              title: "Accident",
              subtitle: "Receive notifications for accident",
              value: accident,
              onChanged: (v) => setState(() => accident = v),
            ),
            SizedBox(height: spacing),
            NotificationToggleTile(
              icon: Icons.power,
              title: "Power Restored",
              subtitle: "Receive notifications for power restored",
              value: powerRestored,
              onChanged: (v) => setState(() => powerRestored = v),
            ),
            SizedBox(height: spacing),
            NotificationToggleTile(
              icon: Icons.electric_bolt,
              title: "Shock",
              subtitle: "Receive notifications for shock",
              value: shock,
              onChanged: (v) => setState(() => shock = v),
            ),
            SizedBox(height: spacing),
            NotificationToggleTile(
              icon: Icons.local_parking,
              title: "Parking Enable",
              subtitle: "Receive notifications for parking enable",
              value: parkingEnable,
              onChanged: (v) => setState(() => parkingEnable = v),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}