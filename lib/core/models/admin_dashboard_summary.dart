class AdminDashboardSummary {
  final Map<String, dynamic> raw;

  const AdminDashboardSummary(this.raw);

  Map<String, dynamic> get payload {
    final root = _asMap(raw);
    final level1 = _asMap(root['data']);
    final level2 = _asMap(level1['data']);

    if (_hasDashboardKeys(level2)) return level2;
    if (_hasDashboardKeys(level1)) return level1;
    return root;
  }

  Map<String, dynamic> get _totals {
    final t = _asMap(payload['totals']);
    return t.isNotEmpty ? t : payload;
  }

  Map<String, dynamic> get _expiry {
    final e = _asMap(payload['expiry']);
    return e.isNotEmpty ? e : payload;
  }

  Map<String, dynamic> get _liveStatus {
    final l1 = _asMap(payload['vehicleLiveStatus']);
    if (l1.isNotEmpty) return l1;
    final l2 = _asMap(payload['liveStatus']);
    return l2;
  }

  int get totalVehicles => _int(
    _totals['totalVehicles'] ??
        _totals['vehiclesCount'] ??
        _totals['vehicleCount'] ??
        payload['totalVehicles'],
  );

  int get totalUsers => _int(
    _totals['totalUsers'] ??
        _totals['usersCount'] ??
        _totals['userCount'] ??
        payload['totalUsers'],
  );

  int get expiring30d => _int(
    _expiry['thisMonth'] ??
        _expiry['expiryThisMonth'] ??
        payload['expiryThisMonth'] ??
        payload['expiring30d'] ??
        payload['expiringIn30Days'],
  );

  int get expired => _int(
    payload['expired'] ??
        payload['expiredCount'] ??
        payload['expiredVehicles'] ??
        _expiry['expired'] ??
        _expiry['expiredCount'],
  );

  int get running => _int(_liveStatus['running']);
  int get stop => _int(_liveStatus['stop'] ?? _liveStatus['stopped']);
  int get notWorking48h => _int(
    _liveStatus['notWorking48h'] ??
        _liveStatus['notWorking'] ??
        _liveStatus['inactive'] ??
        _liveStatus['disconnected'],
  );
  int get noData => _int(
    _liveStatus['noData'] ??
        _liveStatus['no_device'] ??
        _liveStatus['noDevice'],
  );

  List<String> get keys =>
      payload.keys.map((e) => e.toString()).toList()..sort();

  static bool _hasDashboardKeys(Map<String, dynamic> map) {
    if (map.isEmpty) return false;
    return map.containsKey('totals') ||
        map.containsKey('vehicleLiveStatus') ||
        map.containsKey('totalVehicles') ||
        map.containsKey('expiry');
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value.cast());
    return const <String, dynamic>{};
  }

  static int _int(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      final cleaned = value.replaceAll(',', '').trim();
      return int.tryParse(cleaned) ?? 0;
    }
    return int.tryParse(value.toString()) ?? 0;
  }
}
