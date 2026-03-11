class ServerOverallStatus {
  final Map<String, dynamic> raw;

  const ServerOverallStatus(this.raw);

  Map<String, dynamic> get _system {
    final direct = _m(raw['system']);
    if (direct.isNotEmpty) return direct;

    final level1 = _m(raw['data']);
    final level1System = _m(level1['system']);
    if (level1System.isNotEmpty) return level1System;

    final level2 = _m(level1['data']);
    final level2System = _m(level2['system']);
    if (level2System.isNotEmpty) return level2System;

    return raw;
  }

  Map<String, dynamic> get _cpu => _m(_system['cpu']);
  Map<String, dynamic> get _memory => _m(_system['memory']);
  List<Map<String, dynamic>> get _diskList =>
      _toMapList(_system['disk']) ?? const [];

  bool get isUp {
    final v =
        raw['isUp'] ??
        raw['up'] ??
        raw['ok'] ??
        raw['healthy'] ??
        raw['status'];
    if (v is bool) return v;
    final s = v?.toString().toLowerCase() ?? '';
    if (s == 'up' || s == 'ok' || s == 'healthy' || s == 'true' || s == '1') {
      return true;
    }
    return _system.isNotEmpty;
  }

  String get uptimeText {
    final direct = _s(raw['uptimeText'] ?? raw['uptime'] ?? raw['uptimeHuman']);
    if (direct.isNotEmpty) return direct;
    if (uptimeSeconds <= 0) return '';
    return _formatDuration(uptimeSeconds);
  }

  int get uptimeSeconds => _i(
    raw['uptimeSeconds'] ??
        raw['uptimeSec'] ??
        raw['uptime_s'] ??
        _system['uptimeSeconds'] ??
        _system['uptimeSec'] ??
        _system['uptime_s'],
  );

  String get startedAt {
    final direct = _s(
      raw['startedAt'] ??
          raw['started_at'] ??
          raw['bootTime'] ??
          _system['startedAt'] ??
          _system['started_at'] ??
          _system['bootTime'],
    );
    if (direct.isNotEmpty) return direct;

    final serverTimeText = _s(_system['serverTime']);
    if (serverTimeText.isEmpty || uptimeSeconds <= 0) return '';

    final serverTime = DateTime.tryParse(serverTimeText);
    if (serverTime == null) return '';

    return serverTime
        .subtract(Duration(seconds: uptimeSeconds))
        .toIso8601String();
  }

  double get cpuPercent => _d(
    raw['cpuPercent'] ??
        raw['cpu'] ??
        raw['cpuUsage'] ??
        _cpu['usagePct'] ??
        _cpu['usage'] ??
        _cpu['cpuUsage'],
  );

  double get memPercent {
    final direct = _d(
      raw['memPercent'] ?? raw['memoryPercent'] ?? raw['memory'] ?? raw['ram'],
    );
    if (direct > 0) return direct;

    final total = _d(_memory['total']);
    final used = _d(_memory['used']);
    if (total <= 0) return 0;
    return (used / total) * 100;
  }

  double get diskPercent {
    final direct = _d(raw['diskPercent'] ?? raw['disk'] ?? raw['diskUsage']);
    if (direct > 0) return direct;

    if (_diskList.isEmpty) return 0;
    final disk = _diskList.first;
    final total = _d(disk['total']);
    final used = _d(disk['used']);
    if (total <= 0) return 0;
    return (used / total) * 100;
  }

  double get loadAvg1 => _d(
    raw['loadAvg1'] ??
        raw['load1'] ??
        _cpu['load1'] ??
        _system['load1'] ??
        _loadAt(0),
  );

  double get loadAvg5 => _d(
    raw['loadAvg5'] ??
        raw['load5'] ??
        _cpu['load5'] ??
        _system['load5'] ??
        _loadAt(1),
  );

  double get loadAvg15 => _d(
    raw['loadAvg15'] ??
        raw['load15'] ??
        _cpu['load15'] ??
        _system['load15'] ??
        _loadAt(2),
  );

  Object? _loadAt(int i) {
    final l = raw['loadAvg'] ?? raw['load'] ?? raw['loadAverage'];
    if (l is List && l.length > i) return l[i];
    return null;
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
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _d(Object? v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static List<Map<String, dynamic>>? _toMapList(Object? value) {
    if (value is List) {
      return value
          .whereType<Object>()
          .map((e) => e is Map ? _m(e) : const <String, dynamic>{})
          .where((m) => m.isNotEmpty)
          .toList();
    }
    return null;
  }

  static String _formatDuration(int seconds) {
    final d = Duration(seconds: seconds);
    final days = d.inDays;
    final hours = d.inHours % 24;
    final mins = d.inMinutes % 60;
    final secs = d.inSeconds % 60;
    if (days > 0) return "${days}d ${hours}h ${mins}m";
    if (d.inHours > 0) return "${d.inHours}h ${mins}m";
    if (d.inMinutes > 0) return "${d.inMinutes}m ${secs}s";
    return "${d.inSeconds}s";
  }
}
