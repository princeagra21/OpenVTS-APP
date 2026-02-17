class VehicleListItem {
  final Map<String, dynamic> raw;

  const VehicleListItem(this.raw);

  List<String> get keys => raw.keys.map((k) => k.toString()).toList()..sort();

  String get id => _string(
    raw['id'] ??
        raw['vehicleId'] ??
        raw['vehicle_id'] ??
        raw['uuid'] ??
        raw['uid'],
  );

  String get plateNumber => _string(
    raw['plateNumber'] ??
        raw['plate_number'] ??
        raw['plate'] ??
        raw['registrationNumber'] ??
        raw['registration_number'],
  );

  String get name => _string(raw['name'] ?? raw['title'] ?? raw['vehicleName']);

  String get type => _string(
    raw['type'] ??
        raw['vehicleType'] ??
        raw['vehicleTypeName'] ??
        raw['vehicle_type_name'],
  );

  String get imei =>
      _string(raw['imei'] ?? raw['deviceImei'] ?? raw['device_imei']);

  String get status => _string(
    raw['status'] ?? raw['state'] ?? raw['vehicleStatus'] ?? raw['isActive'],
  );

  String get driverName => _string(
    raw['driverName'] ??
        raw['driver'] ??
        (raw['primaryUser'] is Map
            ? (raw['primaryUser'] as Map)['name']
            : null) ??
        raw['primaryUserName'] ??
        raw['primary_user_name'],
  );

  String get updatedAt => _string(
    raw['updatedAt'] ??
        raw['updated_at'] ??
        raw['lastActivityAt'] ??
        raw['last_activity_at'] ??
        raw['lastSeenAt'] ??
        raw['last_seen_at'],
  );

  bool get isActive {
    final v = raw['active'] ?? raw['isActive'] ?? raw['is_active'];
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = status.toLowerCase();
    if (s == 'active') return true;
    if (s == 'inactive') return false;
    if (v is String) {
      final t = v.trim().toLowerCase();
      if (t == 'true' || t == '1') return true;
      if (t == 'false' || t == '0') return false;
    }
    return false;
  }

  static String _string(Object? v) {
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }
}
