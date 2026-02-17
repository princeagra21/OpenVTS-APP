class ServerPostgresStatus {
  final Map<String, dynamic> raw;

  const ServerPostgresStatus(this.raw);

  factory ServerPostgresStatus.fromHealthPayload(
    String fallbackName,
    Object? payload,
  ) {
    final root = _m(payload);
    final nested = _m(root['data']);
    final source = nested.isNotEmpty ? nested : root;
    return ServerPostgresStatus(<String, dynamic>{
      ...source,
      if (_s(source['dbName']).isEmpty &&
          _s(source['name']).isEmpty &&
          _s(source['database']).isEmpty &&
          _s(source['db']).isEmpty)
        'dbName': fallbackName,
    });
  }

  String get dbName =>
      _s(raw['dbName'] ?? raw['name'] ?? raw['database'] ?? raw['db']);

  double get sizeGb => _d(raw['sizeGb'] ?? raw['sizeGB'] ?? raw['size_gb']);

  int get sizeBytes =>
      _i(raw['sizeBytes'] ?? raw['size_bytes'] ?? raw['bytes']);

  int get connections => _i(
    raw['connections'] ?? raw['connectionCount'] ?? raw['activeConnections'],
  );

  int get deadTuples =>
      _i(raw['deadTuples'] ?? raw['dead_tuples'] ?? raw['n_dead_tup']);

  bool get isUp {
    final v = raw['isUp'] ?? raw['up'] ?? raw['healthy'] ?? raw['status'];
    if (v is bool) return v;
    final s = _s(v).toLowerCase();
    return s == 'up' || s == 'ok' || s == 'healthy' || s == 'running';
  }

  static String _s(Object? v) => v == null ? '' : v.toString();
  static Map<String, dynamic> _m(Object? v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v.cast());
    return const <String, dynamic>{};
  }

  static int _i(Object? v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v.toString().replaceAll(',', '')) ?? 0;
  }

  static double _d(Object? v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '')) ?? 0;
  }
}
