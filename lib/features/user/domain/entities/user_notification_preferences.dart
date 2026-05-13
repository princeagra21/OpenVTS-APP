class UserNotificationPreferences {
  UserNotificationPreferences(Object? source)
      : this.typed(
          items: _itemsFromSource(source),
          vehicles: _vehiclesFromSource(source),
          basicRules: _basicRulesFromSource(source),
          overspeedRules: _overspeedRulesFromSource(source),
          geofenceRuleCount: _listFromData(source, const ['geofences']).isNotEmpty
              ? _listFromData(source, const ['geofences']).length
              : _listFromData(source, const ['geofenceMatrix']).length,
          data: _data(source),
        );

  const UserNotificationPreferences.typed({
    required this.items,
    required this.vehicles,
    required this.basicRules,
    required this.overspeedRules,
    this.geofenceRuleCount = 0,
    this.data = const <String, Object?>{},
  });

  final List<UserNotificationPreferenceItem> items;
  final List<UserNotificationVehicle> vehicles;
  final List<UserBasicAlertRule> basicRules;
  final List<UserOverspeedRule> overspeedRules;
  final int geofenceRuleCount;
  final Map<String, Object?> data;

  UserNotificationPreferenceItem? itemFor(String eventType) {
    final wanted = eventType.trim().toUpperCase();
    for (final item in items) {
      if (item.eventType == wanted) return item;
    }
    return null;
  }

  UserBasicAlertRule? basicRuleFor(String vehicleId) {
    final wanted = vehicleId.trim();
    for (final item in basicRules) {
      if (item.vehicleId == wanted) return item;
    }
    return null;
  }

  UserOverspeedRule? overspeedRuleFor(String vehicleId) {
    final wanted = vehicleId.trim();
    for (final item in overspeedRules) {
      if (item.vehicleId == wanted) return item;
    }
    return null;
  }

  UserNotificationPreferences copyWith({
    List<UserNotificationPreferenceItem>? settings,
    List<UserBasicAlertRule>? basicRules,
    List<UserOverspeedRule>? overspeedRules,
  }) {
    return UserNotificationPreferences.typed(
      items: settings ?? items,
      vehicles: vehicles,
      basicRules: basicRules ?? this.basicRules,
      overspeedRules: overspeedRules ?? this.overspeedRules,
      geofenceRuleCount: geofenceRuleCount,
      data: data,
    );
  }

  Map<String, Object?> toUpdatePayload() {
    return <String, Object?>{
      'settings': items.map((e) => e.toPayload()).toList(),
      'basic': basicRules.map((e) => e.toPayload()).toList(),
      'overspeed': overspeedRules.map((e) => e.toPayload()).toList(),
    };
  }

  static List<UserNotificationPreferenceItem> _itemsFromSource(Object? source) {
    final channels = _asMap(_data(source)['channels']);
    if (channels.isEmpty) return const <UserNotificationPreferenceItem>[];
    final out = <UserNotificationPreferenceItem>[];
    for (final entry in channels.entries) {
      final value = _asMap(entry.value);
      final eventType = entry.key.toString().trim().toUpperCase();
      out.add(
        UserNotificationPreferenceItem(
          eventType: eventType,
          notifyEmail: _bool(value['notifyEmail']),
          notifyWhatsapp: _bool(value['notifyWhatsapp']),
          notifyWebPush: _bool(value['notifyWebPush']),
          notifyMobilePush: _bool(value['notifyMobilePush']),
          notifyTelegram: _bool(value['notifyTelegram']),
          notifySms: _bool(value['notifySms']),
          linkedCount: _linkedCountFor(source, eventType),
        ),
      );
    }
    out.sort((a, b) => a.label.compareTo(b.label));
    return out;
  }

  static List<UserNotificationVehicle> _vehiclesFromSource(Object? source) {
    return _listFromData(source, const ['vehicles']).map(UserNotificationVehicle.fromRaw).toList(growable: false);
  }

  static List<UserBasicAlertRule> _basicRulesFromSource(Object? source) {
    return _listFromData(source, const ['basic']).map(UserBasicAlertRule.fromRaw).toList(growable: false);
  }

  static List<UserOverspeedRule> _overspeedRulesFromSource(Object? source) {
    return _listFromData(source, const ['overspeed']).map(UserOverspeedRule.fromRaw).toList(growable: false);
  }

  static int _linkedCountFor(Object? source, String eventType) {
    switch (eventType) {
      case 'BASIC':
        return _listFromData(source, const ['basic']).length;
      case 'OVERSPEED':
        return _listFromData(source, const ['overspeed']).length;
      case 'GEOFENCE':
        final geofences = _listFromData(source, const ['geofences']);
        if (geofences.isNotEmpty) return geofences.length;
        return _listFromData(source, const ['geofenceMatrix']).length;
      default:
        return _listFromData(source, const ['vehicles']).length;
    }
  }

  static Map<String, Object?> _data(Object? source) {
    Object? node = source;
    for (var i = 0; i < 4; i++) {
      final map = _asMap(node);
      if (map.isEmpty) break;
      final next = map['data'];
      if (next is Map) {
        node = next;
        continue;
      }
      return map;
    }
    return _asMap(node);
  }

  static List<Object?> _listFromData(Object? source, List<String> keys) {
    final data = _data(source);
    for (final key in keys) {
      final value = data[key];
      if (value is List) return List<Object?>.from(value);
    }
    return const <Object?>[];
  }

  static Map<String, Object?> _asMap(Object? value) {
    if (value is Map) return <String, Object?>{for (final entry in value.entries) entry.key.toString(): entry.value};
    return const <String, Object?>{};
  }

  static bool _bool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase() ?? '';
    return text == 'true' || text == '1' || text == 'yes' || text == 'on';
  }
}

class UserNotificationPreferenceItem {
  const UserNotificationPreferenceItem({
    required this.eventType,
    required this.notifyEmail,
    required this.notifyWhatsapp,
    required this.notifyWebPush,
    required this.notifyMobilePush,
    required this.notifyTelegram,
    required this.notifySms,
    this.linkedCount = 0,
  });

  final String eventType;
  final bool notifyEmail;
  final bool notifyWhatsapp;
  final bool notifyWebPush;
  final bool notifyMobilePush;
  final bool notifyTelegram;
  final bool notifySms;
  final int linkedCount;

  String get label {
    switch (eventType) {
      case 'BASIC':
        return 'Basic Alerts';
      case 'OVERSPEED':
        return 'Overspeed Alerts';
      case 'GEOFENCE':
        return 'Geofence Alerts';
      default:
        final lower = eventType.toLowerCase();
        return lower.isEmpty
            ? 'Notifications'
            : lower
                  .split('_')
                  .map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
                  .join(' ');
    }
  }

  String get subtitle {
    if (linkedCount > 0) {
      final noun = linkedCount == 1 ? 'rule' : 'rules';
      return '$linkedCount linked $noun';
    }
    final enabled = <String>[];
    if (notifyEmail) enabled.add('Email');
    if (notifyWhatsapp) enabled.add('WhatsApp');
    if (notifyWebPush) enabled.add('Web');
    if (notifyMobilePush) enabled.add('Mobile');
    if (notifyTelegram) enabled.add('Telegram');
    if (notifySms) enabled.add('SMS');
    if (enabled.isEmpty) return 'No channels enabled';
    return enabled.take(3).join(' • ');
  }

  Map<String, Object?> toPayload() {
    return <String, Object?>{
      'eventType': eventType,
      'notifyEmail': notifyEmail,
      'notifyWhatsapp': notifyWhatsapp,
      'notifyWebPush': notifyWebPush,
      'notifyMobilePush': notifyMobilePush,
      'notifyTelegram': notifyTelegram,
      'notifySms': notifySms,
    };
  }

  UserNotificationPreferenceItem copyWith({
    bool? notifyEmail,
    bool? notifyWhatsapp,
    bool? notifyWebPush,
    bool? notifyMobilePush,
    bool? notifyTelegram,
    bool? notifySms,
    int? linkedCount,
  }) {
    return UserNotificationPreferenceItem(
      eventType: eventType,
      notifyEmail: notifyEmail ?? this.notifyEmail,
      notifyWhatsapp: notifyWhatsapp ?? this.notifyWhatsapp,
      notifyWebPush: notifyWebPush ?? this.notifyWebPush,
      notifyMobilePush: notifyMobilePush ?? this.notifyMobilePush,
      notifyTelegram: notifyTelegram ?? this.notifyTelegram,
      notifySms: notifySms ?? this.notifySms,
      linkedCount: linkedCount ?? this.linkedCount,
    );
  }
}

class UserNotificationVehicle {
  const UserNotificationVehicle({required this.id, required this.name, required this.plateNumber});

  factory UserNotificationVehicle.fromRaw(Object? source) {
    final raw = _asMap(source);
    return UserNotificationVehicle(
      id: _text(raw['id'] ?? raw['vehicleId'] ?? raw['uid']),
      name: _text(raw['name'] ?? raw['vehicleName']),
      plateNumber: _text(raw['plateNumber'] ?? raw['plate'] ?? raw['registrationNumber']),
    );
  }

  final String id;
  final String name;
  final String plateNumber;

  String get label {
    if (plateNumber.isNotEmpty && name.isNotEmpty) return '$plateNumber • $name';
    if (plateNumber.isNotEmpty) return plateNumber;
    if (name.isNotEmpty) return name;
    return id;
  }
}

class UserBasicAlertRule {
  const UserBasicAlertRule({required this.vehicleId, required this.ignitionEnabled, required this.alarmEnabled});

  factory UserBasicAlertRule.fromRaw(Object? source) {
    final raw = _asMap(source);
    return UserBasicAlertRule(
      vehicleId: _text(raw['vehicleId'] ?? raw['id']),
      ignitionEnabled: UserNotificationPreferences._bool(raw['ignitionEnabled']),
      alarmEnabled: UserNotificationPreferences._bool(raw['alarmEnabled']),
    );
  }

  final String vehicleId;
  final bool ignitionEnabled;
  final bool alarmEnabled;

  UserBasicAlertRule copyWith({bool? ignitionEnabled, bool? alarmEnabled}) {
    return UserBasicAlertRule(
      vehicleId: vehicleId,
      ignitionEnabled: ignitionEnabled ?? this.ignitionEnabled,
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
    );
  }

  Map<String, Object?> toPayload() {
    return <String, Object?>{
      'vehicleId': int.tryParse(vehicleId) ?? vehicleId,
      'ignitionEnabled': ignitionEnabled,
      'alarmEnabled': alarmEnabled,
    };
  }
}

class UserOverspeedRule {
  const UserOverspeedRule({required this.vehicleId, required this.enabled, required this.speedLimitKph});

  factory UserOverspeedRule.fromRaw(Object? source) {
    final raw = _asMap(source);
    final speed = raw['speedLimitKph'] ?? raw['speedLimit'];
    return UserOverspeedRule(
      vehicleId: _text(raw['vehicleId'] ?? raw['id']),
      enabled: UserNotificationPreferences._bool(raw['enabled']),
      speedLimitKph: speed is num ? speed.toInt() : int.tryParse(_text(speed)),
    );
  }

  final String vehicleId;
  final bool enabled;
  final int? speedLimitKph;

  UserOverspeedRule copyWith({bool? enabled, int? speedLimitKph}) {
    return UserOverspeedRule(
      vehicleId: vehicleId,
      enabled: enabled ?? this.enabled,
      speedLimitKph: speedLimitKph ?? this.speedLimitKph,
    );
  }

  Map<String, Object?> toPayload() {
    return <String, Object?>{
      'vehicleId': int.tryParse(vehicleId) ?? vehicleId,
      'enabled': enabled,
      'speedLimitKph': speedLimitKph,
    };
  }
}

Map<String, Object?> _asMap(Object? value) {
  if (value is Map) return <String, Object?>{for (final entry in value.entries) entry.key.toString(): entry.value};
  return const <String, Object?>{};
}

String _text(Object? value) {
  if (value == null) return '';
  final text = value.toString().trim();
  if (text.toLowerCase() == 'null') return '';
  return text;
}
