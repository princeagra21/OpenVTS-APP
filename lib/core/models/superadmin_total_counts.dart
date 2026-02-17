class SuperadminTotalCounts {
  final Map<String, dynamic> raw;

  const SuperadminTotalCounts(this.raw);

  Map<String, dynamic> get data {
    final d = raw['data'];
    if (d is Map) return Map<String, dynamic>.from(d.cast());
    return raw;
  }

  List<String> get keys => data.keys.map((k) => k.toString()).toList()..sort();

  int get totalVehicles => _int(
    data['totalVehicles'] ??
        data['vehiclesCount'] ??
        data['vehicleCount'] ??
        data['total_vehicles'] ??
        data['vehicles_count'],
  );

  int get activeVehicles => _int(
    data['activeVehicles'] ??
        data['activeVehiclesCount'] ??
        data['activeVehicleCount'] ??
        data['active_vehicles'] ??
        data['active_vehicles_count'],
  );

  int get totalUsers => _int(
    data['totalUsers'] ??
        data['usersCount'] ??
        data['userCount'] ??
        data['total_users'] ??
        data['users_count'],
  );

  int get totalAdmins => _int(
    data['totalAdmins'] ??
        data['adminsCount'] ??
        data['adminCount'] ??
        data['total_admins'] ??
        data['admins_count'],
  );

  int get licensesIssued => _int(
    data['licensesIssued'] ??
        data['licenseIssued'] ??
        data['licenseIssuedCount'] ??
        data['license_issued'] ??
        data['licenses_issued'],
  );

  int get licensesUsed => _int(
    data['licensesUsed'] ??
        data['licenseUsed'] ??
        data['licenseUsedCount'] ??
        data['license_used'] ??
        data['licenses_used'],
  );

  static int _int(Object? v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) {
      final cleaned = v.replaceAll(',', '').trim();
      return int.tryParse(cleaned) ?? 0;
    }
    return int.tryParse(v.toString()) ?? 0;
  }
}
