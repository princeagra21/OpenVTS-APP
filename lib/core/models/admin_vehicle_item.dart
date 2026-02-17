class AdminVehicleItem {
  final Map<String, dynamic> raw;

  const AdminVehicleItem(this.raw);

  List<String> get keys => raw.keys.map((k) => k.toString()).toList()..sort();

  String get id => _string(
    raw['id'] ??
        raw['vehicleId'] ??
        raw['vehicle_id'] ??
        raw['uuid'] ??
        raw['uid'],
  );

  String get name => _string(raw['name'] ?? raw['title'] ?? raw['vehicleName']);

  String get plateNumber => _string(
    raw['plateNumber'] ??
        raw['plate_number'] ??
        raw['plate'] ??
        raw['registrationNumber'] ??
        raw['registration_number'],
  );

  String get status => _string(raw['status'] ?? raw['state']);

  bool get isActive {
    final v = raw['isActive'] ?? raw['active'] ?? raw['is_active'];
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final t = v.trim().toLowerCase();
      if (t == 'true' || t == '1') return true;
      if (t == 'false' || t == '0') return false;
    }
    final s = status.trim().toLowerCase();
    if (s == 'active') return true;
    if (s == 'inactive') return false;
    return false;
  }

  String get imei =>
      _string(raw['imei'] ?? raw['deviceImei'] ?? raw['device_imei']);

  String get updatedAt => _string(
    raw['updatedAt'] ??
        raw['updated_at'] ??
        raw['lastActivityAt'] ??
        raw['last_activity_at'] ??
        raw['lastSeenAt'] ??
        raw['last_seen_at'],
  );

  static String _string(Object? v) {
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }
}
