class ServerOverallStatus {
  final Map<String, dynamic> raw;

  const ServerOverallStatus(this.raw);

  bool get isUp {
    final v =
        raw['isUp'] ??
        raw['up'] ??
        raw['ok'] ??
        raw['healthy'] ??
        raw['status'];
    if (v is bool) return v;
    final s = v?.toString().toLowerCase() ?? '';
    return s == 'up' || s == 'ok' || s == 'healthy' || s == 'true' || s == '1';
  }

  String get uptimeText =>
      _s(raw['uptimeText'] ?? raw['uptime'] ?? raw['uptimeHuman']);

  int get uptimeSeconds =>
      _i(raw['uptimeSeconds'] ?? raw['uptimeSec'] ?? raw['uptime_s']);

  String get startedAt =>
      _s(raw['startedAt'] ?? raw['started_at'] ?? raw['bootTime']);

  double get cpuPercent =>
      _d(raw['cpuPercent'] ?? raw['cpu'] ?? raw['cpuUsage']);

  double get memPercent => _d(
    raw['memPercent'] ?? raw['memoryPercent'] ?? raw['memory'] ?? raw['ram'],
  );

  double get diskPercent =>
      _d(raw['diskPercent'] ?? raw['disk'] ?? raw['diskUsage']);

  double get loadAvg1 => _d(raw['loadAvg1'] ?? raw['load1'] ?? _loadAt(0));

  double get loadAvg5 => _d(raw['loadAvg5'] ?? raw['load5'] ?? _loadAt(1));

  double get loadAvg15 => _d(raw['loadAvg15'] ?? raw['load15'] ?? _loadAt(2));

  Object? _loadAt(int i) {
    final l = raw['loadAvg'] ?? raw['load'] ?? raw['loadAverage'];
    if (l is List && l.length > i) return l[i];
    return null;
  }

  static String _s(Object? v) => v == null ? '' : v.toString();

  static int _i(Object? v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _d(Object? v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
