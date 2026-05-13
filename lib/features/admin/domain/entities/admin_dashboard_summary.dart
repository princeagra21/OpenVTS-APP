class AdminDashboardSummary {
  AdminDashboardSummary(Object? source)
      : this.typed(
          totalVehicles: _int(_totals(source), const ['totalVehicles', 'vehiclesCount', 'vehicleCount']),
          totalUsers: _int(_totals(source), const ['totalUsers', 'usersCount', 'userCount']),
          expiring30d: _int(_expiry(source), const ['thisMonth', 'expiryThisMonth', 'expiring30d', 'expiringIn30Days']),
          expired: _int(_expiry(source), const ['expired', 'expiredCount', 'expiredVehicles']),
          running: _int(_liveStatus(source), const ['running']),
          idle: _int(_liveStatus(source), const ['idle']),
          stop: _int(_liveStatus(source), const ['stop', 'stopped']),
          notWorking48h: _int(_liveStatus(source), const ['notWorking48h', 'notWorking', 'inactive', 'disconnected']),
          noData: _int(_liveStatus(source), const ['noData', 'no_device', 'noDevice']),
          keys: _payload(source).keys.map((e) => e.toString()).toList()..sort(),
        );

  const AdminDashboardSummary.typed({
    required this.totalVehicles,
    required this.totalUsers,
    required this.expiring30d,
    required this.expired,
    required this.running,
    required this.idle,
    required this.stop,
    required this.notWorking48h,
    required this.noData,
    required this.keys,
  });

  final int totalVehicles;
  final int totalUsers;
  final int expiring30d;
  final int expired;
  final int running;
  final int idle;
  final int stop;
  final int notWorking48h;
  final int noData;
  final List<String> keys;

  static Map<String, Object?> _payload(Object? source) {
    final root = _asMap(source);
    final level1 = _asMap(root['data']);
    final level2 = _asMap(level1['data']);
    if (_hasDashboardKeys(level2)) return level2;
    if (_hasDashboardKeys(level1)) return level1;
    return root;
  }

  static Map<String, Object?> _totals(Object? source) {
    final payload = _payload(source);
    final totals = _asMap(payload['totals']);
    return totals.isNotEmpty ? totals : payload;
  }

  static Map<String, Object?> _expiry(Object? source) {
    final payload = _payload(source);
    final expiry = _asMap(payload['expiry']);
    return expiry.isNotEmpty ? expiry : payload;
  }

  static Map<String, Object?> _liveStatus(Object? source) {
    final payload = _payload(source);
    final direct = _asMap(payload['vehicleLiveStatus']);
    if (direct.isNotEmpty) return direct;
    return _asMap(payload['liveStatus']);
  }

  static bool _hasDashboardKeys(Map<String, Object?> map) {
    return map.containsKey('totals') || map.containsKey('vehicleLiveStatus') || map.containsKey('totalVehicles') || map.containsKey('expiry');
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
