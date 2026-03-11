class UserDashboardUsage {
  final Map<String, dynamic> raw;

  const UserDashboardUsage(this.raw);

  Map<String, dynamic> get payload {
    final root = _asMap(raw);
    final level1 = _asMap(root['data']);
    final level2 = _asMap(level1['data']);

    if (_hasUsageKeys(level2)) return level2;
    if (_hasUsageKeys(level1)) return level1;
    return root;
  }

  Map<String, dynamic> get totals {
    final map = _asMap(payload['totals']);
    return map.isNotEmpty ? map : payload;
  }

  List<Map<String, dynamic>> get points {
    final rawPoints = payload['points'];
    if (rawPoints is List) {
      return rawPoints
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item.cast()))
          .toList();
    }
    return const <Map<String, dynamic>>[];
  }

  double get drivenKm =>
      _double(totals['drivenKm'] ?? totals['distanceKm'] ?? totals['km']);
  double get engineHours =>
      _double(totals['engineHours'] ?? totals['hours'] ?? totals['engineHrs']);
  int get activeDays =>
      points.where((item) => _double(item['drivenKm']) > 0).length;
  String get updatedAt => _string(payload['updatedAt']);

  static bool _hasUsageKeys(Map<String, dynamic> map) {
    if (map.isEmpty) return false;
    return map.containsKey('points') || map.containsKey('totals');
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value.cast());
    return const <String, dynamic>{};
  }

  static String _string(Object? value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static double _double(Object? value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '').trim()) ?? 0;
  }
}
