enum PushNotificationTab {
  basic,
  overspeed,
  geofence,
}

extension PushNotificationTabX on PushNotificationTab {
  String get label {
    switch (this) {
      case PushNotificationTab.basic:
        return 'Basic';
      case PushNotificationTab.overspeed:
        return 'Overspeed';
      case PushNotificationTab.geofence:
        return 'Geofence';
    }
  }

  String get eventType {
    switch (this) {
      case PushNotificationTab.basic:
        return 'BASIC';
      case PushNotificationTab.overspeed:
        return 'OVERSPEED';
      case PushNotificationTab.geofence:
        return 'GEOFENCE';
    }
  }

  String get title {
    switch (this) {
      case PushNotificationTab.basic:
        return 'Basic';
      case PushNotificationTab.overspeed:
        return 'Over Speed';
      case PushNotificationTab.geofence:
        return 'Geofence';
    }
  }

  static PushNotificationTab fromLabel(String label) {
    final normalized = label.trim().toLowerCase();
    if (normalized == 'overspeed') return PushNotificationTab.overspeed;
    if (normalized == 'geofence') return PushNotificationTab.geofence;
    return PushNotificationTab.basic;
  }
}

class PushNotificationActionResult {
  const PushNotificationActionResult({required this.message, this.isError = false});

  final String message;
  final bool isError;

  static PushNotificationActionResult success(String message) {
    return PushNotificationActionResult(message: message);
  }

  static PushNotificationActionResult error(String message) {
    return PushNotificationActionResult(message: message, isError: true);
  }
}
