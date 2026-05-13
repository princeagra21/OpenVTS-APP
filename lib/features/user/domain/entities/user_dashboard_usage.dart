class UserDashboardUsage {
  UserDashboardUsage(Object? source)
      : this.typed(
          points: _points(source),
          drivenKm: _double(_totals(source)['drivenKm'] ?? _totals(source)['distanceKm'] ?? _totals(source)['km']),
          engineHours: _double(_totals(source)['engineHours'] ?? _totals(source)['hours'] ?? _totals(source)['engineHrs']),
          updatedAt: _string(_payload(source)['updatedAt']),
        );

  const UserDashboardUsage.typed({
    required this.points,
    required this.drivenKm,
    required this.engineHours,
    required this.updatedAt,
  });

  final List<UserDashboardUsagePoint> points;
  final double drivenKm;
  final double engineHours;
  final String updatedAt;

  int get activeDays => points.where((item) => item.drivenKm > 0).length;

  static Map<String, Object?> _payload(Object? source) {
    final root = _asMap(source);
    final level1 = _asMap(root['data']);
    final level2 = _asMap(level1['data']);
    if (_hasUsageKeys(level2)) return level2;
    if (_hasUsageKeys(level1)) return level1;
    return root;
  }

  static Map<String, Object?> _totals(Object? source) {
    final payload = _payload(source);
    final totals = _asMap(payload['totals']);
    return totals.isNotEmpty ? totals : payload;
  }

  static List<UserDashboardUsagePoint> _points(Object? source) {
    final value = _payload(source)['points'];
    if (value is! List) return const <UserDashboardUsagePoint>[];
    return value.map(UserDashboardUsagePoint.fromObject).toList(growable: false);
  }

  static bool _hasUsageKeys(Map<String, Object?> map) => map.containsKey('points') || map.containsKey('totals');

  static Map<String, Object?> _asMap(Object? value) {
    if (value is Map) return <String, Object?>{for (final entry in value.entries) entry.key.toString(): entry.value};
    return const <String, Object?>{};
  }

  static String _string(Object? value) => value?.toString().trim() ?? '';

  static double _double(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '').trim() ?? '') ?? 0;
  }
}

class UserDashboardUsagePoint {
  UserDashboardUsagePoint.fromObject(Object? source)
      : label = _string(_asMap(source)['label'] ?? _asMap(source)['date'] ?? _asMap(source)['day']),
        drivenKm = UserDashboardUsage._double(_asMap(source)['drivenKm'] ?? _asMap(source)['distanceKm']),
        engineHours = UserDashboardUsage._double(_asMap(source)['engineHours'] ?? _asMap(source)['hours']);

  const UserDashboardUsagePoint({required this.label, required this.drivenKm, required this.engineHours});

  final String label;
  final double drivenKm;
  final double engineHours;

  static Map<String, Object?> _asMap(Object? value) {
    if (value is Map) return <String, Object?>{for (final entry in value.entries) entry.key.toString(): entry.value};
    return const <String, Object?>{};
  }

  static String _string(Object? value) => value?.toString().trim() ?? '';
}
