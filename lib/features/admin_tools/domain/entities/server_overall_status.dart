class ServerOverallStatus {
  ServerOverallStatus(Object? source)
      : this.typed(
          isUp: _readIsUp(source),
          uptimeText: _readUptimeText(source),
          uptimeSeconds: _readUptimeSeconds(source),
          startedAt: _readStartedAt(source),
          cpuPercent: _readCpuPercent(source),
          memPercent: _readMemPercent(source),
          diskPercent: _readDiskPercent(source),
          loadAvg1: _readLoad(source, 0),
          loadAvg5: _readLoad(source, 1),
          loadAvg15: _readLoad(source, 2),
        );

  const ServerOverallStatus.typed({
    required this.isUp,
    required this.uptimeText,
    required this.uptimeSeconds,
    required this.startedAt,
    required this.cpuPercent,
    required this.memPercent,
    required this.diskPercent,
    required this.loadAvg1,
    required this.loadAvg5,
    required this.loadAvg15,
  });

  final bool isUp;
  final String uptimeText;
  final int uptimeSeconds;
  final String startedAt;
  final double cpuPercent;
  final double memPercent;
  final double diskPercent;
  final double loadAvg1;
  final double loadAvg5;
  final double loadAvg15;

  static Map<String, Object?> _system(Object? source) {
    final raw = _asMap(source);
    final direct = _asMap(raw['system']);
    if (direct.isNotEmpty) return direct;
    final level1 = _asMap(raw['data']);
    final level1System = _asMap(level1['system']);
    if (level1System.isNotEmpty) return level1System;
    final level2 = _asMap(level1['data']);
    final level2System = _asMap(level2['system']);
    if (level2System.isNotEmpty) return level2System;
    return raw;
  }

  static bool _readIsUp(Object? source) {
    final raw = _asMap(source);
    final value = raw['isUp'] ?? raw['up'] ?? raw['ok'] ?? raw['healthy'] ?? raw['status'];
    if (value is bool) return value;
    final text = value?.toString().toLowerCase() ?? '';
    if (text == 'up' || text == 'ok' || text == 'healthy' || text == 'true' || text == '1') return true;
    return _system(source).isNotEmpty;
  }

  static String _readUptimeText(Object? source) {
    final raw = _asMap(source);
    final direct = _string(raw['uptimeText'] ?? raw['uptime'] ?? raw['uptimeHuman']);
    if (direct.isNotEmpty) return direct;
    final seconds = _readUptimeSeconds(source);
    if (seconds <= 0) return '';
    return _formatDuration(seconds);
  }

  static int _readUptimeSeconds(Object? source) {
    final raw = _asMap(source);
    final system = _system(source);
    return _int(raw['uptimeSeconds'] ?? raw['uptimeSec'] ?? raw['uptime_s'] ?? system['uptimeSeconds'] ?? system['uptimeSec'] ?? system['uptime_s']);
  }

  static String _readStartedAt(Object? source) {
    final raw = _asMap(source);
    final system = _system(source);
    final direct = _string(raw['startedAt'] ?? raw['started_at'] ?? raw['bootTime'] ?? system['startedAt'] ?? system['started_at'] ?? system['bootTime']);
    if (direct.isNotEmpty) return direct;
    final serverTimeText = _string(system['serverTime']);
    final uptimeSeconds = _readUptimeSeconds(source);
    if (serverTimeText.isEmpty || uptimeSeconds <= 0) return '';
    final serverTime = DateTime.tryParse(serverTimeText);
    if (serverTime == null) return '';
    return serverTime.subtract(Duration(seconds: uptimeSeconds)).toIso8601String();
  }

  static double _readCpuPercent(Object? source) {
    final raw = _asMap(source);
    final cpu = _asMap(_system(source)['cpu']);
    return _double(raw['cpuPercent'] ?? raw['cpu'] ?? raw['cpuUsage'] ?? cpu['usagePct'] ?? cpu['usage'] ?? cpu['cpuUsage']);
  }

  static double _readMemPercent(Object? source) {
    final raw = _asMap(source);
    final memory = _asMap(_system(source)['memory']);
    final direct = _double(raw['memPercent'] ?? raw['memoryPercent'] ?? raw['memory'] ?? raw['ram']);
    if (direct > 0) return direct;
    final total = _double(memory['total']);
    final used = _double(memory['used']);
    if (total <= 0) return 0;
    return (used / total) * 100;
  }

  static double _readDiskPercent(Object? source) {
    final raw = _asMap(source);
    final direct = _double(raw['diskPercent'] ?? raw['disk'] ?? raw['diskUsage']);
    if (direct > 0) return direct;
    final disks = _diskList(_system(source)['disk']);
    if (disks.isEmpty) return 0;
    final disk = disks.first;
    final total = _double(disk['total']);
    final used = _double(disk['used']);
    if (total <= 0) return 0;
    return (used / total) * 100;
  }

  static double _readLoad(Object? source, int index) {
    final raw = _asMap(source);
    final cpu = _asMap(_system(source)['cpu']);
    final keys = switch (index) {
      0 => const ['loadAvg1', 'load1'],
      1 => const ['loadAvg5', 'load5'],
      _ => const ['loadAvg15', 'load15'],
    };
    for (final key in keys) {
      final direct = _double(raw[key] ?? cpu[key] ?? _system(source)[key]);
      if (direct > 0) return direct;
    }
    final load = raw['loadAvg'] ?? raw['load'] ?? raw['loadAverage'];
    if (load is List && load.length > index) return _double(load[index]);
    return 0;
  }

  static List<Map<String, Object?>> _diskList(Object? value) {
    if (value is! List) return const <Map<String, Object?>>[];
    return value.whereType<Map>().map((e) => <String, Object?>{for (final entry in e.entries) entry.key.toString(): entry.value}).toList(growable: false);
  }

  static Map<String, Object?> _asMap(Object? value) {
    if (value is Map) return <String, Object?>{for (final entry in value.entries) entry.key.toString(): entry.value};
    return const <String, Object?>{};
  }

  static String _string(Object? value) => value?.toString().trim() ?? '';

  static int _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _double(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _formatDuration(int seconds) {
    final d = Duration(seconds: seconds);
    final days = d.inDays;
    final hours = d.inHours % 24;
    final mins = d.inMinutes % 60;
    final secs = d.inSeconds % 60;
    if (days > 0) return '${days}d ${hours}h ${mins}m';
    if (d.inHours > 0) return '${d.inHours}h ${mins}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m ${secs}s';
    return '${d.inSeconds}s';
  }
}
