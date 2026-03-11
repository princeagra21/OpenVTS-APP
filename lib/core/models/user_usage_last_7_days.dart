class UserUsageLast7Days {
  final Map<String, dynamic> raw;

  const UserUsageLast7Days(this.raw);

  Map<String, dynamic> get payload {
    final root = _asMap(raw);
    final level1 = _asMap(root['data']);
    final level2 = _asMap(level1['data']);

    if (_hasKeys(level2)) return level2;
    if (_hasKeys(level1)) return level1;
    return root;
  }

  Map<String, dynamic> get _totals => _asMap(payload['totals']);

  List<Map<String, dynamic>> get points => _asList(payload['points']);

  double get totalDrivenKm => _double(
    _totals['drivenKm'] ?? payload['drivenKm'] ?? payload['distanceKm'],
  );

  double get totalEngineHours => _double(
    _totals['engineHours'] ?? payload['engineHours'] ?? payload['hours'],
  );

  int get daysTracked => points.length;

  static bool _hasKeys(Map<String, dynamic> value) {
    return value.containsKey('points') ||
        value.containsKey('totals') ||
        value.containsKey('range');
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value.cast());
    return const <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _asList(Object? value) {
    if (value is List<Map<String, dynamic>>) return value;
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item.cast()))
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }

  static double _double(Object? value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '').trim()) ?? 0;
  }
}
