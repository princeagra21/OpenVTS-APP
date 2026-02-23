class SuperadminTotalCounts {
  final Map<String, dynamic> raw;

  const SuperadminTotalCounts(this.raw);

  Map<String, dynamic> get data {
    Map<String, dynamic> asMap(Object? value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value.cast());
      return const <String, dynamic>{};
    }

    final root = asMap(raw);
    final first = asMap(root['data']);
    final second = asMap(first['data']);

    bool hasCountKeys(Map<String, dynamic> m) {
      if (m.isEmpty) return false;
      const keys = <String>{
        'totalVehicles',
        'activeVehicles',
        'totalUsers',
        'totalAdmins',
        'licensedCredits',
        'usedCredits',
        'licensesUsed',
      };
      return m.keys.any(keys.contains);
    }

    if (hasCountKeys(second)) return second;
    if (hasCountKeys(first)) return first;
    if (hasCountKeys(root)) return root;
    return second.isNotEmpty ? second : (first.isNotEmpty ? first : root);
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
        data['licensedCredits'] ??
        data['licensed_credits'] ??
        data['licenseIssuedCount'] ??
        data['license_issued'] ??
        data['licenses_issued'],
  );

  int get licensesUsed => _int(
    data['licensesUsed'] ??
        data['licenseUsed'] ??
        data['usedCredits'] ??
        data['used_credits'] ??
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
