class UserUsageLast7Days {
  UserUsageLast7Days(Object? source)
      : this.typed(
          points: _points(source),
          totalDrivenKm: _double(_totals(source)['drivenKm'] ?? _payload(source)['drivenKm'] ?? _payload(source)['distanceKm']),
          totalEngineHours: _double(_totals(source)['engineHours'] ?? _payload(source)['engineHours'] ?? _payload(source)['hours']),
        );

  const UserUsageLast7Days.typed({
    required this.points,
    required this.totalDrivenKm,
    required this.totalEngineHours,
  });

  final List<UserUsagePoint> points;
  final double totalDrivenKm;
  final double totalEngineHours;

  int get daysTracked => points.length;

  static Map<String, Object?> _payload(Object? source) {
    final root = _asMap(source);
    final level1 = _asMap(root['data']);
    final level2 = _asMap(level1['data']);
    if (_hasKeys(level2)) return level2;
    if (_hasKeys(level1)) return level1;
    return root;
  }

  static Map<String, Object?> _totals(Object? source) => _asMap(_payload(source)['totals']);

  static List<UserUsagePoint> _points(Object? source) {
    final value = _payload(source)['points'];
    if (value is! List) return const <UserUsagePoint>[];
    return value.map(UserUsagePoint.fromObject).toList(growable: false);
  }

  static bool _hasKeys(Map<String, Object?> value) {
    return value.containsKey('points') || value.containsKey('totals') || value.containsKey('range');
  }

  static Map<String, Object?> _asMap(Object? value) {
    if (value is Map) return <String, Object?>{for (final entry in value.entries) entry.key.toString(): entry.value};
    return const <String, Object?>{};
  }

  static double _double(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '').trim() ?? '') ?? 0;
  }
}

class UserUsagePoint {
  UserUsagePoint.fromObject(Object? source)
      : label = _string(_asMap(source)['label'] ?? _asMap(source)['date'] ?? _asMap(source)['day']),
        drivenKm = UserUsageLast7Days._double(_asMap(source)['drivenKm'] ?? _asMap(source)['distanceKm']),
        engineHours = UserUsageLast7Days._double(_asMap(source)['engineHours'] ?? _asMap(source)['hours']);

  const UserUsagePoint({required this.label, required this.drivenKm, required this.engineHours});

  final String label;
  final double drivenKm;
  final double engineHours;

  static Map<String, Object?> _asMap(Object? value) {
    if (value is Map) return <String, Object?>{for (final entry in value.entries) entry.key.toString(): entry.value};
    return const <String, Object?>{};
  }

  static String _string(Object? value) => value?.toString().trim() ?? '';
}
