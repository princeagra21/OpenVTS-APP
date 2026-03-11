class UserNotificationPreferences {
  final Map<String, dynamic> raw;

  const UserNotificationPreferences(this.raw);

  Map<String, dynamic> get data {
    Object? node = raw;
    for (var i = 0; i < 4; i++) {
      if (node is Map) {
        final map = node is Map<String, dynamic>
            ? node
            : Map<String, dynamic>.from(node.cast());
        final next = map['data'];
        if (next is Map) {
          node = next;
          continue;
        }
        return map;
      }
      break;
    }
    if (node is Map<String, dynamic>) return node;
    if (node is Map) return Map<String, dynamic>.from(node.cast());
    return const <String, dynamic>{};
  }

  List<UserNotificationPreferenceItem> get items {
    final channels = _asMap(data['channels']);
    if (channels.isEmpty) return const <UserNotificationPreferenceItem>[];

    final out = <UserNotificationPreferenceItem>[];
    for (final entry in channels.entries) {
      final value = _asMap(entry.value);
      out.add(
        UserNotificationPreferenceItem(
          eventType: entry.key.toString().trim().toUpperCase(),
          notifyEmail: _b(value['notifyEmail']),
          notifyWhatsapp: _b(value['notifyWhatsapp']),
          notifyWebPush: _b(value['notifyWebPush']),
          notifyMobilePush: _b(value['notifyMobilePush']),
          notifyTelegram: _b(value['notifyTelegram']),
          notifySms: _b(value['notifySms']),
          linkedCount: _linkedCountFor(
            entry.key.toString().trim().toUpperCase(),
          ),
        ),
      );
    }

    out.sort((a, b) => a.label.compareTo(b.label));
    return out;
  }

  UserNotificationPreferenceItem? itemFor(String eventType) {
    final wanted = eventType.trim().toUpperCase();
    for (final item in items) {
      if (item.eventType == wanted) return item;
    }
    return null;
  }

  List<UserNotificationVehicle> get vehicles {
    final out = <UserNotificationVehicle>[];
    for (final item in _asList(data['vehicles'])) {
      if (item is Map<String, dynamic>) {
        out.add(UserNotificationVehicle.fromRaw(item));
      } else if (item is Map) {
        out.add(
          UserNotificationVehicle.fromRaw(
            Map<String, dynamic>.from(item.cast()),
          ),
        );
      }
    }
    return out;
  }

  List<UserBasicAlertRule> get basicRules {
    final out = <UserBasicAlertRule>[];
    for (final item in _asList(data['basic'])) {
      if (item is Map<String, dynamic>) {
        out.add(UserBasicAlertRule.fromRaw(item));
      } else if (item is Map) {
        out.add(
          UserBasicAlertRule.fromRaw(Map<String, dynamic>.from(item.cast())),
        );
      }
    }
    return out;
  }

  List<UserOverspeedRule> get overspeedRules {
    final out = <UserOverspeedRule>[];
    for (final item in _asList(data['overspeed'])) {
      if (item is Map<String, dynamic>) {
        out.add(UserOverspeedRule.fromRaw(item));
      } else if (item is Map) {
        out.add(
          UserOverspeedRule.fromRaw(Map<String, dynamic>.from(item.cast())),
        );
      }
    }
    return out;
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
    final dataMap = Map<String, dynamic>.from(data);
    final channels = <String, dynamic>{};
    for (final item in settings ?? items) {
      channels[item.eventType] = <String, dynamic>{
        'notifyEmail': item.notifyEmail,
        'notifyWhatsapp': item.notifyWhatsapp,
        'notifyWebPush': item.notifyWebPush,
        'notifyMobilePush': item.notifyMobilePush,
        'notifyTelegram': item.notifyTelegram,
        'notifySms': item.notifySms,
      };
    }
    dataMap['channels'] = channels;
    dataMap['basic'] = (basicRules ?? this.basicRules)
        .map((e) => e.toPayload())
        .toList();
    dataMap['overspeed'] = (overspeedRules ?? this.overspeedRules)
        .map((e) => e.toPayload())
        .toList();
    return UserNotificationPreferences(<String, dynamic>{'data': dataMap});
  }

  Map<String, dynamic> toUpdatePayload() {
    return <String, dynamic>{
      'settings': items.map((e) => e.toPayload()).toList(),
      'basic': basicRules.map((e) => e.toPayload()).toList(),
      'overspeed': overspeedRules.map((e) => e.toPayload()).toList(),
    };
  }

  int _linkedCountFor(String eventType) {
    switch (eventType) {
      case 'BASIC':
        return _asList(data['basic']).length;
      case 'OVERSPEED':
        return _asList(data['overspeed']).length;
      case 'GEOFENCE':
        final geofences = _asList(data['geofences']);
        if (geofences.isNotEmpty) return geofences.length;
        return _asList(data['geofenceMatrix']).length;
      default:
        return _asList(data['vehicles']).length;
    }
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value.cast());
    return const <String, dynamic>{};
  }

  static List _asList(Object? value) {
    if (value is List) return value;
    return const [];
  }

  static bool _b(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final s = value?.toString().trim().toLowerCase() ?? '';
    return s == 'true' || s == '1' || s == 'yes' || s == 'on';
  }
}

class UserNotificationPreferenceItem {
  final String eventType;
  final bool notifyEmail;
  final bool notifyWhatsapp;
  final bool notifyWebPush;
  final bool notifyMobilePush;
  final bool notifyTelegram;
  final bool notifySms;
  final int linkedCount;

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
                  .map(
                    (part) => part.isEmpty
                        ? part
                        : '${part[0].toUpperCase()}${part.substring(1)}',
                  )
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

  Map<String, dynamic> toPayload() {
    return <String, dynamic>{
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
  final Map<String, dynamic> raw;

  const UserNotificationVehicle(this.raw);

  factory UserNotificationVehicle.fromRaw(Map<String, dynamic> raw) {
    return UserNotificationVehicle(raw);
  }

  String get id => _text(raw['id'] ?? raw['vehicleId'] ?? raw['uid']);

  String get name => _text(raw['name'] ?? raw['vehicleName']);

  String get plateNumber =>
      _text(raw['plateNumber'] ?? raw['plate'] ?? raw['registrationNumber']);

  String get label {
    if (plateNumber.isNotEmpty && name.isNotEmpty) {
      return '$plateNumber • $name';
    }
    if (plateNumber.isNotEmpty) return plateNumber;
    if (name.isNotEmpty) return name;
    return id;
  }
}

class UserBasicAlertRule {
  final Map<String, dynamic> raw;

  const UserBasicAlertRule(this.raw);

  factory UserBasicAlertRule.fromRaw(Map<String, dynamic> raw) {
    return UserBasicAlertRule(raw);
  }

  String get vehicleId => _text(raw['vehicleId'] ?? raw['id']);

  bool get ignitionEnabled =>
      UserNotificationPreferences._b(raw['ignitionEnabled']);

  bool get alarmEnabled => UserNotificationPreferences._b(raw['alarmEnabled']);

  UserBasicAlertRule copyWith({bool? ignitionEnabled, bool? alarmEnabled}) {
    return UserBasicAlertRule(<String, dynamic>{
      ...raw,
      'vehicleId': int.tryParse(vehicleId) ?? vehicleId,
      'ignitionEnabled': ignitionEnabled ?? this.ignitionEnabled,
      'alarmEnabled': alarmEnabled ?? this.alarmEnabled,
    });
  }

  Map<String, dynamic> toPayload() {
    return <String, dynamic>{
      'vehicleId': int.tryParse(vehicleId) ?? vehicleId,
      'ignitionEnabled': ignitionEnabled,
      'alarmEnabled': alarmEnabled,
    };
  }
}

class UserOverspeedRule {
  final Map<String, dynamic> raw;

  const UserOverspeedRule(this.raw);

  factory UserOverspeedRule.fromRaw(Map<String, dynamic> raw) {
    return UserOverspeedRule(raw);
  }

  String get vehicleId => _text(raw['vehicleId'] ?? raw['id']);

  bool get enabled => UserNotificationPreferences._b(raw['enabled']);

  int? get speedLimitKph {
    final value = raw['speedLimitKph'] ?? raw['speedLimit'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(_text(value));
  }

  UserOverspeedRule copyWith({bool? enabled, int? speedLimitKph}) {
    return UserOverspeedRule(<String, dynamic>{
      ...raw,
      'vehicleId': int.tryParse(vehicleId) ?? vehicleId,
      'enabled': enabled ?? this.enabled,
      'speedLimitKph': speedLimitKph ?? this.speedLimitKph,
    });
  }

  Map<String, dynamic> toPayload() {
    return <String, dynamic>{
      'vehicleId': int.tryParse(vehicleId) ?? vehicleId,
      'enabled': enabled,
      'speedLimitKph': speedLimitKph,
    };
  }
}

String _text(Object? value) {
  if (value == null) return '';
  final text = value.toString().trim();
  if (text.toLowerCase() == 'null') return '';
  return text;
}
