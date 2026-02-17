class SuperadminRecentVehicle {
  final Map<String, dynamic> raw;

  const SuperadminRecentVehicle(this.raw);

  List<String> get keys => raw.keys.map((k) => k.toString()).toList()..sort();

  String get id => _string(
    raw['id'] ??
        raw['vehicleId'] ??
        raw['vehicle_id'] ??
        raw['registrationNumber'] ??
        raw['registration_number'] ??
        raw['plate'] ??
        raw['number'] ??
        raw['imei'],
  );

  String get name => _string(
    raw['name'] ??
        raw['vehicleName'] ??
        raw['vehicle_name'] ??
        raw['model'] ??
        raw['title'],
  );

  String get status {
    final v = raw['status'] ?? raw['state'];
    if (v is String && v.trim().isNotEmpty) return v;
    final isActive = raw['active'] ?? raw['isActive'] ?? raw['is_active'];
    if (isActive is bool) return isActive ? 'Active' : 'Idle';
    return '';
  }

  String get time => _string(
    raw['time'] ??
        raw['updatedAt'] ??
        raw['updated_at'] ??
        raw['lastSeenAt'] ??
        raw['last_seen_at'] ??
        raw['createdAt'] ??
        raw['created_at'],
  );

  static String _string(Object? v) {
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }
}
