class AdminVehicleItem {
  final Map<String, dynamic> raw;

  const AdminVehicleItem(this.raw);

  List<String> get keys => raw.keys.map((k) => k.toString()).toList()..sort();

  String get id => _string(
    raw['id'] ??
        raw['vehicleID'] ??
        raw['vehicleId'] ??
        raw['vehicle_id'] ??
        raw['uuid'] ??
        raw['uid'],
  );

  String get name => _string(
    raw['name'] ??
        raw['title'] ??
        raw['vehicleName'] ??
        raw['vehicle_name'] ??
        raw['plateNumber'],
  );

  String get plateNumber => _string(
    raw['plateNumber'] ??
        raw['plate_number'] ??
        raw['plate'] ??
        raw['registrationNumber'] ??
        raw['registration_number'],
  );

  String get status {
    final direct = raw['status'] ?? raw['state'] ?? raw['vehicleStatus'];
    final normalizedDirect = _normalizeStatus(direct);
    if (normalizedDirect != null) return normalizedDirect;

    final active = raw['isActive'] ?? raw['active'] ?? raw['is_active'];
    final normalizedActive = _normalizeStatus(active);
    if (normalizedActive != null) return normalizedActive;
    return '';
  }

  bool get isActive {
    final v = raw['isActive'] ?? raw['active'] ?? raw['is_active'];
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final t = v.trim().toLowerCase();
      if (t == 'true' || t == '1' || t == 'active') return true;
      if (t == 'false' || t == '0' || t == 'inactive') return false;
    }
    final s = status.trim().toLowerCase();
    if (s == 'active' || s == 'verified' || s == 'enabled') return true;
    if (s == 'inactive' || s == 'disabled') return false;
    return false;
  }

  String get imei =>
      _string(raw['imei'] ?? raw['deviceImei'] ?? raw['device_imei']);

  String get vin => _string(raw['vin'] ?? raw['VIN'] ?? raw['chassisNumber']);

  String get simNumber => _string(
    raw['simNumber'] ?? raw['sim_number'] ?? raw['simNo'] ?? raw['sim'],
  );

  String get type {
    final vehicleType = raw['vehicleType'];
    if (vehicleType is Map) {
      final nestedName =
          vehicleType['name'] ??
          vehicleType['title'] ??
          vehicleType['type'] ??
          vehicleType['slug'];
      final nested = _string(nestedName);
      if (nested.isNotEmpty) return nested;
    }
    return _string(
      raw['type'] ??
          raw['vehicleType'] ??
          raw['vehicleTypeName'] ??
          raw['vehicle_type_name'],
    );
  }

  String get updatedAt => _string(
    raw['updatedAt'] ??
        raw['updated_at'] ??
        raw['lastActivityAt'] ??
        raw['last_activity_at'] ??
        raw['lastSeenAt'] ??
        raw['last_seen_at'] ??
        raw['createdAt'] ??
        raw['created_at'],
  );

  static String? _normalizeStatus(Object? value) {
    if (value == null) return null;
    if (value is bool) return value ? 'Active' : 'Inactive';
    if (value is num) return value != 0 ? 'Active' : 'Inactive';
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      final t = trimmed.toLowerCase();
      if (t == 'true' || t == '1' || t == 'active' || t == 'enabled') {
        return 'Active';
      }
      if (t == 'false' || t == '0' || t == 'inactive' || t == 'disabled') {
        return 'Inactive';
      }
      return trimmed;
    }
    return value.toString();
  }

  static String _string(Object? v) {
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }
}
