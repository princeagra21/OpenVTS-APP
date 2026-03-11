class UserFleetStatusSummary {
  final Map<String, dynamic> raw;

  const UserFleetStatusSummary(this.raw);

  Map<String, dynamic> get payload {
    final root = _asMap(raw);
    final level1 = _asMap(root['data']);
    final level2 = _asMap(level1['data']);

    if (_hasKeys(level2)) return level2;
    if (_hasKeys(level1)) return level1;
    return root;
  }

  Map<String, dynamic> get _buckets => _asMap(payload['buckets']);
  Map<String, dynamic> get _percentages => _asMap(payload['percentages']);

  int get totalVehicles => _int(payload['totalVehicles']);
  int get withDevice => _int(payload['withDevice']);
  int get noDevice => _int(payload['noDevice']);

  int get running => _int(_buckets['running']);
  int get idle => _int(_buckets['idle']);
  int get stopped => _int(_buckets['stopped']);
  int get inactive => _int(_buckets['inactive']);
  int get noData => _int(_buckets['noData']);

  double? percentFor(String key) => _double(_percentages[key]);

  static bool _hasKeys(Map<String, dynamic> value) {
    return value.containsKey('totalVehicles') ||
        value.containsKey('buckets') ||
        value.containsKey('withDevice');
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
    return int.tryParse(value.toString().replaceAll(',', '').trim()) ?? 0;
  }

  static double? _double(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '').trim());
  }
}
