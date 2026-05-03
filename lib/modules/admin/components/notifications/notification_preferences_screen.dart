// components/notifications/notification_preferences_screen.dart
import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'widget/notification_general_box.dart';
import 'widget/notification_vehicle_alert_box.dart';
import 'widget/notification_system_box.dart';
import 'widget/notification_dnd_box.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  /// Endpoint scan result (FleetStack-API-Reference.md first, Postman second):
  /// - /admin/notifications* endpoints are inbox/read APIs (separate screen),
  ///   not preferences persistence.
  /// - Postman has only superadmin app notification template endpoints
  ///   (/superadmin/appnotifytemplates*), not admin preferences endpoints.
  ///
  /// No Admin notification-preferences GET/PATCH endpoint exists for
  /// Vehicle/System/DND toggle settings. This screen stays local-only.
  bool _apiUnavailableShown = false;

  void _showApiUnavailableOnce() {
    if (!kDebugMode || _apiUnavailableShown || !mounted) return;
    _apiUnavailableShown = true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification settings API not available yet'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;

    return AppLayout(
      title: "Open VTS",
      subtitle: "Notifications",
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 8,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          children: [
            NotificationGeneralBox(onAttemptPersist: _showApiUnavailableOnce),
            SizedBox(height: 24),
            NotificationVehicleAlertBox(
              onAttemptPersist: _showApiUnavailableOnce,
            ),
            SizedBox(height: 24),
            NotificationSystemBox(onAttemptPersist: _showApiUnavailableOnce),
            SizedBox(height: 24),
            NotificationDndBox(onAttemptPersist: _showApiUnavailableOnce),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
