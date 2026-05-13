class SuperadminTotalCounts {
  SuperadminTotalCounts(Object? source)
      : this.typed(
          totalVehicles: _int(_data(source), const ['totalVehicles', 'vehiclesCount', 'vehicleCount', 'total_vehicles', 'vehicles_count']),
          activeVehicles: _int(_data(source), const ['activeVehicles', 'activeVehiclesCount', 'activeVehicleCount', 'active_vehicles', 'active_vehicles_count']),
          totalUsers: _int(_data(source), const ['totalUsers', 'usersCount', 'userCount', 'total_users', 'users_count']),
          totalAdmins: _int(_data(source), const ['totalAdmins', 'adminsCount', 'adminCount', 'total_admins', 'admins_count']),
          licensesIssued: _int(_data(source), const ['licensesIssued', 'licenseIssued', 'licensedCredits', 'licensed_credits', 'licenseIssuedCount', 'license_issued', 'licenses_issued']),
          licensesUsed: _int(_data(source), const ['licensesUsed', 'licenseUsed', 'usedCredits', 'used_credits', 'licenseUsedCount', 'license_used', 'licenses_used']),
          liveConnected: _int(_liveStatus(source), const ['connected', 'online']),
          liveRunning: _int(_liveStatus(source), const ['running']),
          liveIdle: _int(_liveStatus(source), const ['idle']),
          liveStop: _int(_liveStatus(source), const ['stop']),
          liveInactive: _int(_liveStatus(source), const ['inactive']),
          liveNoData: _int(_liveStatus(source), const ['noData', 'nodata']),
          keys: _data(source).keys.map((k) => k.toString()).toList()..sort(),
        );

  const SuperadminTotalCounts.typed({
    required this.totalVehicles,
    required this.activeVehicles,
    required this.totalUsers,
    required this.totalAdmins,
    required this.licensesIssued,
    required this.licensesUsed,
    required this.liveConnected,
    required this.liveRunning,
    required this.liveIdle,
    required this.liveStop,
    required this.liveInactive,
    required this.liveNoData,
    required this.keys,
  });

  final int totalVehicles;
  final int activeVehicles;
  final int totalUsers;
  final int totalAdmins;
  final int licensesIssued;
  final int licensesUsed;
  final int liveConnected;
  final int liveRunning;
  final int liveIdle;
  final int liveStop;
  final int liveInactive;
  final int liveNoData;
  final List<String> keys;

  static Map<String, Object?> _data(Object? source) {
    final root = _asMap(source);
    final first = _asMap(root['data']);
    final second = _asMap(first['data']);
    if (_hasCountKeys(second)) return second;
    if (_hasCountKeys(first)) return first;
    if (_hasCountKeys(root)) return root;
    return second.isNotEmpty ? second : (first.isNotEmpty ? first : root);
  }

  static Map<String, Object?> _liveStatus(Object? source) => _asMap(_data(source)['vehicleLiveStatus']);

  static bool _hasCountKeys(Map<String, Object?> map) {
    const keys = <String>{'totalVehicles', 'activeVehicles', 'totalUsers', 'totalAdmins', 'licensedCredits', 'usedCredits', 'licensesUsed', 'vehicleLiveStatus'};
    return map.keys.any(keys.contains);
  }

  static int _int(Map<String, Object?> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is int) return value;
      if (value is num) return value.round();
      final parsed = int.tryParse(value?.toString().replaceAll(',', '').trim() ?? '');
      if (parsed != null) return parsed;
    }
    return 0;
  }

  static Map<String, Object?> _asMap(Object? value) {
    if (value is Map) return <String, Object?>{for (final entry in value.entries) entry.key.toString(): entry.value};
    return const <String, Object?>{};
  }
}
