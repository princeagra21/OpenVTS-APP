class UserDashboardFleetStatus {
  final Map<String, dynamic> raw;

  const UserDashboardFleetStatus(this.raw);

  Map<String, dynamic> get payload {
    final root = _asMap(raw);
    final level1 = _asMap(root['data']);
    final level2 = _asMap(level1['data']);

    if (_hasFleetKeys(level2)) return level2;
    if (_hasFleetKeys(level1)) return level1;
    return root;
  }

  Map<String, dynamic> get _buckets {
    final map = _asMap(payload['buckets']);
    return map.isNotEmpty ? map : payload;
  }

  Map<String, dynamic> get _percentages {
    final map = _asMap(payload['percentages']);
    return map.isNotEmpty ? map : payload;
  }

  int get totalVehicles =>
      _int(payload['totalVehicles'] ?? payload['vehicles'] ?? _buckets['total']);
  int get withDevice => _int(payload['withDevice'] ?? payload['devices']);
  int get noDevice => _int(payload['noDevice']);
  int get connected => _int(_buckets['connected']);
  int get running => _int(_buckets['running']);
  int get idle => _int(_buckets['idle']);
  int get stopped => _int(_buckets['stopped'] ?? _buckets['stop']);
  int get inactive => _int(_buckets['inactive']);
  int get noData => _int(_buckets['noData']);
  String get updatedAt => _string(payload['updatedAt']);

  double get runningPct => _double(_percentages['running']);
  double get idlePct => _double(_percentages['idle']);
  double get stoppedPct => _double(
    _percentages['stopped'] ?? _percentages['stop'],
  );
  double get inactivePct => _double(_percentages['inactive']);
  double get noDataPct => _double(_percentages['noData']);

  static bool _hasFleetKeys(Map<String, dynamic> map) {
    if (map.isEmpty) return false;
    return map.containsKey('totalVehicles') ||
        map.containsKey('buckets') ||
        map.containsKey('withDevice');
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

  static int _int(Object? value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString().replaceAll(',', '').trim()) ?? 0;
  }

  static double _double(Object? value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '').trim()) ?? 0;
  }
}
