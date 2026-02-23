class VehicleListItem {
  final Map<String, dynamic> raw;

  const VehicleListItem(this.raw);

  List<String> get keys => raw.keys.map((k) => k.toString()).toList()..sort();

  String get id => _string(
    raw['id'] ??
        raw['vehicleID'] ??
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

  String get vin => _string(raw['vin'] ?? raw['VIN'] ?? raw['chassisNumber']);

  String get name => _string(raw['name'] ?? raw['title'] ?? raw['vehicleName']);

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

  String get imei =>
      _string(raw['imei'] ?? raw['deviceImei'] ?? raw['device_imei']);

  String get simNumber => _string(
    raw['simNumber'] ?? raw['sim_number'] ?? raw['simNo'] ?? raw['sim'],
  );

  String get userPrimaryName => _string(
    (raw['userPrimary'] is Map
            ? (raw['userPrimary'] as Map)['name'] ??
                  (raw['userPrimary'] as Map)['fullName']
            : null) ??
        raw['primaryUserName'] ??
        raw['primary_user_name'] ??
        raw['driverName'] ??
        raw['driver'],
  );

  String get userAddedByName => _string(
    (raw['userAddedBy'] is Map
            ? (raw['userAddedBy'] as Map)['name'] ??
                  (raw['userAddedBy'] as Map)['fullName'] ??
                  (raw['userAddedBy'] as Map)['username']
            : null) ??
        raw['addedByName'] ??
        raw['added_by_name'],
  );

  String get status {
    final direct = raw['status'] ?? raw['state'] ?? raw['vehicleStatus'];
    final fromDirect = _normalizeStatus(direct);
    if (fromDirect != null) return fromDirect;

    final active = raw['isActive'] ?? raw['active'] ?? raw['is_active'];
    final fromActive = _normalizeStatus(active);
    if (fromActive != null) return fromActive;
    return '';
  }

  String get driverName => _string(
    raw['driverName'] ??
        raw['driver'] ??
        (raw['primaryUser'] is Map
            ? (raw['primaryUser'] as Map)['name']
            : null) ??
        (raw['userPrimary'] is Map
            ? (raw['userPrimary'] as Map)['name']
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

  String get createdAt => _string(
    raw['createdAt'] ??
        raw['created_at'] ??
        raw['createdOn'] ??
        raw['created_on'],
  );

  String get primaryExpiry => _string(
    raw['primaryExpiry'] ??
        raw['primary_expiry'] ??
        raw['primaryLicenseExpiry'] ??
        raw['primary_license_expiry'] ??
        raw['license_pri'] ??
        raw['licensePri'],
  );

  String get secondaryExpiry => _string(
    raw['secondaryExpiry'] ??
        raw['secondary_expiry'] ??
        raw['secondaryLicenseExpiry'] ??
        raw['secondary_license_expiry'] ??
        raw['license_sec'] ??
        raw['licenseSec'],
  );

  String get gmtOffset => _string(
    raw['gmtOffset'] ??
        raw['gmt_offset'] ??
        raw['timezone'] ??
        raw['timeZone'] ??
        raw['tz'],
  );

  String get userPrimaryUsername => _string(
    (raw['userPrimary'] is Map
            ? (raw['userPrimary'] as Map)['username'] ??
                  (raw['userPrimary'] as Map)['email'] ??
                  (raw['userPrimary'] as Map)['loginType'] ??
                  (raw['userPrimary'] as Map)['uid']
            : null) ??
        raw['primaryUserUsername'] ??
        raw['primary_user_username'],
  );

  String get userAddedByUsername => _string(
    (raw['userAddedBy'] is Map
            ? (raw['userAddedBy'] as Map)['username'] ??
                  (raw['userAddedBy'] as Map)['email'] ??
                  (raw['userAddedBy'] as Map)['loginType'] ??
                  (raw['userAddedBy'] as Map)['uid']
            : null) ??
        raw['addedByUsername'] ??
        raw['added_by_username'],
  );

  bool get isActive {
    final v = raw['active'] ?? raw['isActive'] ?? raw['is_active'];
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = status.toLowerCase();
    if (s == 'active' || s == 'verified' || s == 'enabled') return true;
    if (s == 'inactive' || s == 'disabled') return false;
    if (v is String) {
      final t = v.trim().toLowerCase();
      if (t == 'true' || t == '1' || t == 'active') return true;
      if (t == 'false' || t == '0' || t == 'inactive') return false;
    }
    return false;
  }

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
