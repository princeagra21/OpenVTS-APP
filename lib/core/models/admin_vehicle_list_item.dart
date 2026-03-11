class AdminVehicleListItem {
  final Map<String, dynamic> raw;

  const AdminVehicleListItem(this.raw);

  factory AdminVehicleListItem.fromRaw(Map<String, dynamic> raw) {
    return AdminVehicleListItem(raw);
  }

  String get id =>
      _s(raw['id'] ?? raw['vehicleId'] ?? raw['uid'] ?? raw['_id']);

  String get nameModel {
    final value = _s(
      raw['model'] ??
          raw['name'] ??
          raw['vehicleName'] ??
          raw['title'] ??
          raw['plateNumber'],
    );
    if (value.isNotEmpty) return value;
    return '—';
  }

  String get plateNumber => _s(
    raw['plateNumber'] ??
        raw['plate'] ??
        raw['registrationNo'] ??
        raw['registrationNumber'],
  );

  String get imei {
    final device = _asMap(raw['device']);
    return _s(
      raw['imei'] ??
          raw['deviceImei'] ??
          raw['imeiNumber'] ??
          device['imei'] ??
          device['imeiNumber'],
    );
  }

  String get vin => _s(raw['vin'] ?? raw['chassisNo'] ?? raw['vehicleVin']);

  String get motion =>
      _s(raw['motion'] ?? raw['status'] ?? raw['state'] ?? raw['liveStatus']);

  String get statusLabel {
    final normalized = _normalizeMotion(motion);
    if (normalized.isNotEmpty) return normalized;
    final active = isActive;
    if (active == true) return 'RUNNING';
    if (active == false) return 'STOPPED';
    return '—';
  }

  String get durationLabel =>
      _s(raw['duration'] ?? raw['elapsed'] ?? raw['uptime'] ?? raw['age']);

  String get speedLabel {
    final speed = _s(raw['speed'] ?? raw['currentSpeed'] ?? raw['velocity']);
    if (speed.isEmpty) return '—';
    if (speed.toLowerCase().contains('km')) return speed;
    return '$speed km/h';
  }

  String get primaryUserName {
    final nested = _asMap(raw['primaryUser']);
    final explicit = _s(
      nested['name'] ??
          raw['primaryUserName'] ??
          raw['userName'] ??
          raw['username'] ??
          raw['ownerName'],
    );
    return explicit;
  }

  String get driverName {
    final nested = _asMap(raw['driver']);
    return _s(nested['name'] ?? raw['driverName'] ?? raw['assignedDriverName']);
  }

  String get userInitials {
    final name = (driverName.isNotEmpty ? driverName : primaryUserName).trim();
    if (name.isEmpty) return '--';
    final parts = name
        .split(RegExp(r'\\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '--';
    if (parts.length == 1) {
      return parts.first.length >= 2
          ? parts.first.substring(0, 2).toUpperCase()
          : parts.first.toUpperCase();
    }
    return (parts.first[0] + parts[1][0]).toUpperCase();
  }

  String get userDisplayName {
    final driver = driverName.trim();
    if (driver.isNotEmpty) return driver;
    final primary = primaryUserName.trim();
    if (primary.isNotEmpty) return primary;
    return '—';
  }

  String get lastActivityAt => _s(
    raw['lastActivityAt'] ??
        raw['last_activity'] ??
        raw['lastSeenAt'] ??
        raw['lastSeen'] ??
        raw['updatedAt'] ??
        raw['timestamp'],
  );

  String get expiry => _s(
    raw['expiry'] ??
        raw['planExpiry'] ??
        raw['licenseExpiry'] ??
        raw['expiryDate'],
  );

  bool? get isActive => _b(
    raw['isActive'] ?? raw['active'] ?? raw['enabled'] ?? raw['statusFlag'],
  );

  bool? get ignitionOk =>
      _b(raw['ignition'] ?? raw['ignitionOk'] ?? raw['ignitionStatus']);

  bool? get gpsOk => _b(raw['gps'] ?? raw['gpsOk'] ?? raw['gpsStatus']);

  bool? get lockOk => _b(raw['locked'] ?? raw['lock'] ?? raw['lockStatus']);

  static String _normalizeMotion(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return '';
    final l = v.toLowerCase();
    if (l.contains('running') || l.contains('moving') || l == 'active') {
      return 'RUNNING';
    }
    if (l.contains('stop') || l.contains('stopped') || l.contains('idle')) {
      return 'STOPPED';
    }
    if (l.contains('offline') || l.contains('inactive')) return 'STOPPED';
    return v.toUpperCase();
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value.cast());
    return const <String, dynamic>{};
  }

  static String _s(Object? value) {
    if (value == null) return '';
    final out = value.toString().trim();
    if (out.toLowerCase() == 'null') return '';
    return out;
  }

  static bool? _b(Object? value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final s = value.toString().trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes' || s == 'on') return true;
    if (s == 'false' || s == '0' || s == 'no' || s == 'off') return false;
    return null;
  }
}
