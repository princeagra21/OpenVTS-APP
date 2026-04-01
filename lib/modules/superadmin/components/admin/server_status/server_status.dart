// screens/server/server_status_screen.dart
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/server_overall_status.dart';
import 'package:fleet_stack/core/models/server_postgres_status.dart';
import 'package:fleet_stack/core/models/server_service_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/superadmin/utils/app_utils.dart';
import 'package:fleet_stack/modules/superadmin/components/appbars/superadmin_home_appbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class ServerStatusScreen extends StatefulWidget {
  const ServerStatusScreen({super.key});

  @override
  State<ServerStatusScreen> createState() => _ServerStatusScreenState();
}

class _ServerStatusScreenState extends State<ServerStatusScreen> {
  List<DateTime?> _dates = [
    DateTime.now().subtract(const Duration(days: 7)),
    DateTime.now(),
  ];
  ServerOverallStatus? _overall;
  ServerPostgresStatus? _postgres;
  ServerPostgresStatus? _logsDb;
  ServerPostgresStatus? _addressDb;
  Map<String, dynamic> _healthRaw = const <String, dynamic>{};
  List<ServerServiceItem> _services = const [];
  bool _loading = false;
  bool _errorShown = false;
  CancelToken? _token;
  ApiClient? _api;
  SuperadminRepository? _repo;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _token?.cancel('ServerStatusScreen disposed');
    super.dispose();
  }

  Color _serviceColor(String status) {
    final s = status.toLowerCase();
    if (s.isEmpty || s == 'unknown' || s == 'n/a') {
      return Colors.grey;
    }
    if (s == 'running' || s == 'up' || s == 'ok' || s == 'healthy') {
      return Colors.green;
    }
    if (s == 'degraded' || s == 'warning' || s == 'paused') {
      return Colors.orange;
    }
    return Colors.red;
  }

  String _uptimeText() {
    final o = _overall;
    if (o == null) return "—";
    if (o.uptimeText.trim().isNotEmpty) return o.uptimeText;
    if (o.uptimeSeconds <= 0) return "—";
    final d = Duration(seconds: o.uptimeSeconds);
    final days = d.inDays;
    final hours = d.inHours % 24;
    final mins = d.inMinutes % 60;
    final secs = d.inSeconds % 60;
    return "${days}d ${hours}h ${mins}m ${secs}s";
  }

  String _pgSizeText(ServerPostgresStatus? p) {
    if (p == null) return "—";
    if (p.sizeGb > 0) return "${p.sizeGb.toStringAsFixed(0)} GB";
    if (p.sizeBytes > 0) {
      final gb = p.sizeBytes / (1024 * 1024 * 1024);
      return "${gb.toStringAsFixed(1)} GB";
    }
    return "—";
  }

  Map<String, dynamic> _asMap(Object? v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v.cast());
    return const <String, dynamic>{};
  }

  String _asString(Object? v) => v == null ? '' : v.toString();

  String _valueOrDash(Object? v) {
    final text = _asString(v).trim();
    return text.isEmpty ? '—' : text;
  }

  String _formatPortValue(Object? v) {
    if (v == null) return '—';
    if (v is List) {
      final items = v
          .map(_asString)
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (items.isEmpty) return '—';
      return items.join(', ');
    }
    return _valueOrDash(v);
  }

  int? _asInt(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v.toString());
  }

  double? _asDouble(Object? v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  Object? _readPath(Map<String, dynamic> root, String path) {
    Object? cur = root;
    for (final part in path.split('.')) {
      if (cur is Map) {
        final map = _asMap(cur);
        if (!map.containsKey(part)) return null;
        cur = map[part];
      } else {
        return null;
      }
    }
    return cur;
  }

  Object? _firstPathValue(Map<String, dynamic> root, List<String> paths) {
    for (final p in paths) {
      final v = _readPath(root, p);
      if (v != null && _asString(v).trim().isNotEmpty) return v;
    }
    return null;
  }

  String _statusFromAny(Object? value, String fallback) {
    if (value is bool) return value ? 'up' : 'down';
    final mapValue = _asMap(value);
    if (mapValue.isNotEmpty) {
      final nested = _firstPathValue(mapValue, const ['status', 'state', 'up']);
      if (nested != null && _asString(nested).trim().isNotEmpty) {
        if (nested is bool) return nested ? 'up' : 'down';
        return _asString(nested);
      }
    }
    final asText = _asString(value).trim();
    return asText.isNotEmpty ? asText : fallback;
  }

  String _monitoringMeta(Map<String, dynamic> health, String label) {
    final key = label.toLowerCase();
    List<String> paths;
    if (key == 'local') {
      paths = const [
        'local.lastCheck',
        'local.last_check',
        'local.updatedAt',
        'local.updated_at',
        'local.timestamp',
        'data.timestamp',
        'timestamp',
      ];
    } else if (key == 'agent') {
      paths = const [
        'agent.lastCheck',
        'agent.last_check',
        'agent.updatedAt',
        'agent.updated_at',
        'agent.timestamp',
        'data.timestamp',
        'timestamp',
      ];
    } else if (key == 'server') {
      paths = const [
        'server.lastCheck',
        'server.last_check',
        'server.updatedAt',
        'server.updated_at',
        'server.timestamp',
        'data.timestamp',
        'timestamp',
      ];
    } else {
      paths = const [
        'status.lastCheck',
        'status.updatedAt',
        'status.timestamp',
        'data.timestamp',
        'timestamp',
      ];
    }
    final value = _valueOrDash(_firstPathValue(health, paths));
    return "Last check: $value";
  }

  String _monitoringLastCheckValue(
    Map<String, dynamic> health,
    String label,
  ) {
    final directTimestamp = _asString(health['timestamp']).trim();
    if (directTimestamp.isNotEmpty) {
      return _formatLocalTimestamp(directTimestamp);
    }
    final dataMap = _asMap(health['data']);
    final dataTimestamp = _asString(dataMap['timestamp']).trim();
    if (dataTimestamp.isNotEmpty) {
      return _formatLocalTimestamp(dataTimestamp);
    }
    final key = label.toLowerCase();
    List<String> paths;
    if (key == 'local') {
      paths = const [
        'local.lastCheck',
        'local.last_check',
        'local.updatedAt',
        'local.updated_at',
        'local.timestamp',
      ];
    } else if (key == 'agent') {
      paths = const [
        'agent.lastCheck',
        'agent.last_check',
        'agent.updatedAt',
        'agent.updated_at',
        'agent.timestamp',
      ];
    } else if (key == 'server') {
      paths = const [
        'server.lastCheck',
        'server.last_check',
        'server.updatedAt',
        'server.updated_at',
        'server.timestamp',
      ];
    } else {
      paths = const [
        'status.lastCheck',
        'status.updatedAt',
        'status.timestamp',
      ];
    }
    return _formatLocalTimestamp(_valueOrDash(_firstPathValue(health, paths)));
  }

  String _formatLocalTimestamp(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text == '—') return '—';
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return text;
    final local = parsed.toLocal();
    final int hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final String minute = local.minute.toString().padLeft(2, '0');
    final String ampm = local.hour >= 12 ? 'PM' : 'AM';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final String month = months[local.month - 1];
    return '$month ${local.day}, ${local.year} · $hour12:$minute $ampm';
  }

  String _formatUptimeAbbrev(int seconds) {
    if (seconds <= 0) return '—';
    const int minute = 60;
    const int hour = 3600;
    const int day = 86400;
    const int month = 2592000; // 30d
    const int year = 31536000; // 365d
    int remaining = seconds;
    final years = remaining ~/ year;
    remaining %= year;
    final months = remaining ~/ month;
    remaining %= month;
    final days = remaining ~/ day;
    remaining %= day;
    final hours = remaining ~/ hour;
    remaining %= hour;
    final minutes = remaining ~/ minute;
    remaining %= minute;
    final secs = remaining;

    final parts = <String>[];
    if (years > 0) parts.add('${years}y');
    if (months > 0) parts.add('${months}mo');
    if (days > 0) parts.add('${days}d');
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0) parts.add('${minutes}m');
    if (secs > 0 && parts.isEmpty) parts.add('${secs}s');
    return parts.isEmpty ? '0s' : parts.join(' ');
  }

  Future<void> _loadAll() async {
    _token?.cancel('Reload server status');
    final token = CancelToken();
    _token = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);

      final overviewRes = await _repo!.getServerOverviewRaw(cancelToken: token);
      final pgRes = await _repo!.getServerPostgresStatus(cancelToken: token);
      final logsDbRes = await _repo!.getLogsDbStatus(cancelToken: token);
      final addressDbRes = await _repo!.getAddressDbStatus(cancelToken: token);
      final healthRes = await _repo!.getHealthRaw(cancelToken: token);
      if (!mounted) return;

      bool hadFailure = false;
      ServerOverallStatus? nextOverall = _overall;
      ServerPostgresStatus? nextPg = _postgres;
      ServerPostgresStatus? nextLogsDb = _logsDb;
      ServerPostgresStatus? nextAddressDb = _addressDb;
      Map<String, dynamic> nextHealthRaw = _healthRaw;
      List<ServerServiceItem> nextServices = _services;

      overviewRes.when(
        success: (raw) {
          final level1 = _asMap(raw['data']);
          final level2 = _asMap(level1['data']);
          final payload = level2.isNotEmpty
              ? level2
              : level1.isNotEmpty
              ? level1
              : raw;
          nextOverall = ServerOverallStatus(payload);
          nextServices = ServerServiceItem.listFromOverview(raw);
        },
        failure: (_) => hadFailure = true,
      );
      pgRes.when(success: (d) => nextPg = d, failure: (_) => hadFailure = true);
      logsDbRes.when(
        success: (d) => nextLogsDb = d,
        failure: (_) => hadFailure = true,
      );
      addressDbRes.when(
        success: (d) => nextAddressDb = d,
        failure: (_) => hadFailure = true,
      );
      healthRes.when(
        success: (raw) {
          nextHealthRaw = raw;
        },
        failure: (_) => hadFailure = true,
      );

      setState(() {
        _overall = nextOverall;
        _postgres = nextPg;
        _logsDb = nextLogsDb;
        _addressDb = nextAddressDb;
        _healthRaw = nextHealthRaw;
        _services = nextServices;
        _loading = false;
        if (!hadFailure) {
          _errorShown = false;
        }
      });

      if (hadFailure && !_errorShown) {
        _errorShown = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't fully load server status.")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (_errorShown) return;
      _errorShown = true;
      final msg =
          (e is ApiException && (e.statusCode == 401 || e.statusCode == 403))
          ? 'Not authorized to view server status.'
          : "Couldn't load server status.";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double fs = AdaptiveUtils.getTitleFontSize(width);
    final overallUp = _overall?.isUp == true;
    final int? cpu = _overall != null ? _overall!.cpuPercent.round() : null;
    final int? mem = _overall != null ? _overall!.memPercent.round() : null;
    final int? disk = _overall != null ? _overall!.diskPercent.round() : null;
    final double? load1 = _overall != null ? _overall!.loadAvg1 : null;
    final double? load5 = _overall != null ? _overall!.loadAvg5 : null;
    final double? load15 = _overall != null ? _overall!.loadAvg15 : null;
    final pgPrimary = _logsDb ?? _postgres ?? _addressDb;
    final pgName = (pgPrimary?.dbName.isNotEmpty == true)
        ? pgPrimary!.dbName
        : "—";
    final pgConnections = pgPrimary?.connections;
    final pgDeadTuples = pgPrimary?.deadTuples;
    final addressDb = _addressDb;
    final healthData = _asMap(_healthRaw['data']);
    final health = healthData.isNotEmpty ? healthData : _healthRaw;
    final cpuCoresRaw = _firstPathValue(_healthRaw, const [
      'cpu.cores',
      'data.cpu.cores',
      'system.cpu.cores',
    ]);
    final int? cpuCores = _asInt(cpuCoresRaw);
    final load1Raw = _firstPathValue(_healthRaw, const [
      'cpu.load1',
      'data.cpu.load1',
      'system.cpu.load1',
    ]);
    final load5Raw = _firstPathValue(_healthRaw, const [
      'cpu.load5',
      'data.cpu.load5',
      'system.cpu.load5',
    ]);
    final load15Raw = _firstPathValue(_healthRaw, const [
      'cpu.load15',
      'data.cpu.load15',
      'system.cpu.load15',
    ]);
    final double? cpuLoad1 = _asDouble(load1Raw) ?? load1;
    final double? cpuLoad5 = _asDouble(load5Raw) ?? load5;
    final double? cpuLoad15 = _asDouble(load15Raw) ?? load15;
    final String cpuMeta = (cpuCores != null ||
            cpuLoad1 != null ||
            cpuLoad5 != null ||
            cpuLoad15 != null)
        ? "${cpuCores ?? 0}C · ${(cpuLoad1 ?? 0).toStringAsFixed(2)} / ${(cpuLoad5 ?? 0).toStringAsFixed(2)} / ${(cpuLoad15 ?? 0).toStringAsFixed(2)}"
        : "—";
    final redisStateRaw = _firstPathValue(health, const [
      'redis.state',
      'redis.status',
      'redis.connectionState',
    ]);
    final redisState = _statusFromAny(redisStateRaw, 'unknown');
    final redisUsedRaw = _firstPathValue(health, const [
      'redis.used',
      'redis.usedMB',
      'redis.memory',
      'redis.memoryMb',
      'redis.memoryMB',
    ]);
    final redisUsed = _valueOrDash(redisUsedRaw);
    final redisHitRateRaw = _firstPathValue(health, const [
      'redis.hitRate',
      'redis.hitrate',
      'redis.hit_rate',
    ]);
    final redisHitRate = _valueOrDash(redisHitRateRaw);
    final redisKeysRaw = _firstPathValue(health, const ['redis.keys']);
    final redisKeys = _valueOrDash(redisKeysRaw);
    final redisColor = _serviceColor(redisState);

    final socketClientsRaw = _firstPathValue(health, const [
      'socket.clients',
      'socketio.clients',
      'socketIo.clients',
    ]);
    final socketClients = _valueOrDash(socketClientsRaw);
    final socketRoomsRaw = _firstPathValue(health, const [
      'socket.rooms',
      'socketio.rooms',
      'socketIo.rooms',
    ]);
    final socketRooms = _valueOrDash(socketRoomsRaw);
    final socketEventsRaw = _firstPathValue(health, const [
      'socket.eventsPerSec',
      'socket.events_sec',
      'socketio.eventsPerSec',
      'socketIo.eventsPerSec',
    ]);
    final socketEvents = _valueOrDash(socketEventsRaw);

    final bullIngest = _statusFromAny(
      _firstPathValue(health, const ['bullmq.ingest', 'bull.ingest']),
      'unknown',
    );
    final bullNotifications = _statusFromAny(
      _firstPathValue(health, const [
        'bullmq.notifications',
        'bull.notifications',
      ]),
      'unknown',
    );
    final bullGeocode = _statusFromAny(
      _firstPathValue(health, const [
        'bullmq.geocode',
        'bullmq.geocoder',
        'bull.geocode',
      ]),
      'unknown',
    );
    final bullIngestWait = _valueOrDash(
      _firstPathValue(health, const [
        'bullmq.ingest.wait',
        'bullmq.ingest.waiting',
        'bull.ingest.wait',
        'bull.ingest.waiting',
      ]),
    );
    final bullIngestAct = _valueOrDash(
      _firstPathValue(health, const [
        'bullmq.ingest.active',
        'bull.ingest.active',
      ]),
    );
    final bullIngestDelay = _valueOrDash(
      _firstPathValue(health, const [
        'bullmq.ingest.delay',
        'bullmq.ingest.delayed',
        'bull.ingest.delay',
        'bull.ingest.delayed',
      ]),
    );
    final bullIngestFail = _valueOrDash(
      _firstPathValue(health, const [
        'bullmq.ingest.fail',
        'bullmq.ingest.failed',
        'bull.ingest.fail',
        'bull.ingest.failed',
      ]),
    );
    final bullNotificationsWait = _valueOrDash(
      _firstPathValue(health, const [
        'bullmq.notifications.wait',
        'bullmq.notifications.waiting',
        'bull.notifications.wait',
        'bull.notifications.waiting',
      ]),
    );
    final bullNotificationsAct = _valueOrDash(
      _firstPathValue(health, const [
        'bullmq.notifications.active',
        'bull.notifications.active',
      ]),
    );
    final bullNotificationsDelay = _valueOrDash(
      _firstPathValue(health, const [
        'bullmq.notifications.delay',
        'bullmq.notifications.delayed',
        'bull.notifications.delay',
        'bull.notifications.delayed',
      ]),
    );
    final bullNotificationsFail = _valueOrDash(
      _firstPathValue(health, const [
        'bullmq.notifications.fail',
        'bullmq.notifications.failed',
        'bull.notifications.fail',
        'bull.notifications.failed',
      ]),
    );
    final bullGeocodeWait = _valueOrDash(
      _firstPathValue(health, const [
        'bullmq.geocode.wait',
        'bullmq.geocode.waiting',
        'bullmq.geocoder.wait',
        'bullmq.geocoder.waiting',
        'bull.geocode.wait',
        'bull.geocode.waiting',
      ]),
    );
    final bullGeocodeAct = _valueOrDash(
      _firstPathValue(health, const [
        'bullmq.geocode.active',
        'bullmq.geocoder.active',
        'bull.geocode.active',
      ]),
    );
    final bullGeocodeDelay = _valueOrDash(
      _firstPathValue(health, const [
        'bullmq.geocode.delay',
        'bullmq.geocode.delayed',
        'bullmq.geocoder.delay',
        'bullmq.geocoder.delayed',
        'bull.geocode.delay',
        'bull.geocode.delayed',
      ]),
    );
    final bullGeocodeFail = _valueOrDash(
      _firstPathValue(health, const [
        'bullmq.geocode.fail',
        'bullmq.geocode.failed',
        'bullmq.geocoder.fail',
        'bullmq.geocoder.failed',
        'bull.geocode.fail',
        'bull.geocode.failed',
      ]),
    );

    final firebaseFcmRaw = _firstPathValue(health, const [
      'firebase.fcm',
      'firebase.status',
      'firebase.reachable',
    ]);
    final firebaseFcm = _statusFromAny(firebaseFcmRaw, 'unknown');
    final firebasePingRaw = _firstPathValue(health, const [
      'firebase.lastPing',
      'firebase.last_ping',
    ]);
    final firebaseLastPing = _valueOrDash(firebasePingRaw);
    final services = _services;
    final runningCount = services.where((s) => s.isUp).length;
    final hasServerData =
        _overall != null ||
        pgPrimary != null ||
        health.isNotEmpty ||
        services.isNotEmpty;
    final showSkeleton = _loading && !hasServerData;
    final loadAvgText = (load1 != null && load5 != null && load15 != null)
        ? "${load1.toStringAsFixed(2)} / ${load5.toStringAsFixed(2)} / ${load15.toStringAsFixed(2)}"
        : "—";
    final statusLocalRaw = _statusFromAny(
      _firstPathValue(_healthRaw, const [
        'local.status',
        'local.state',
        'local',
        'data.status',
        'status',
      ]),
      'unknown',
    );
    final statusLocal =
        statusLocalRaw.toLowerCase() == 'ok' ? 'Online' : statusLocalRaw;
    final localLastCheck = _monitoringLastCheckValue(_healthRaw, 'local');
    final hasServiceIssue = services.any((s) => !s.isUp);
    final needsAttention = !overallUp || hasServiceIssue;

    final topPadding = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF5F5F7),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              hp,
              topPadding + AppUtils.appBarHeightCustom + 28,
              hp,
              84,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            _buildMonitoringCard(
              context: context,
              loading: _loading,
              title: "Server Health Monitoring",
              subtitle: "Monitor uptime, dependencies, and safe service actions",
              localStatus: statusLocal,
              localLastCheck: localLastCheck,
              onRefresh: _loading ? null : _loadAll,
            ),
            const SizedBox(height: 12),
            _buildAlertCard(
              context: context,
              icon: Icons.warning_amber_rounded,
              title: "Important",
              message:
                  "Stopping Frontend, Backend, or Listener can lock you out of the application. Start and Restart are available, but Stop is disabled.",
            ),
            const SizedBox(height: 16),
            _buildMetricsSection(
              context: context,
              showSkeleton: showSkeleton,
              title: "Resource Overview",
              subtitle: "",
              loadAvgText: loadAvgText,
              metrics: [
                _MetricData(
                  label: "CPU Usage",
                  value: cpu == null ? "—" : "$cpu%",
                  percent: cpu,
                  icon: Icons.memory_outlined,
                  subtext: cpuMeta,
                ),
                _MetricData(
                  label: "Memory Usage",
                  value: mem == null ? "—" : "$mem%",
                  percent: mem,
                  icon: Icons.sd_storage_outlined,
                  subtext: mem == null ? "—" : "$mem% used",
                ),
                _MetricData(
                  label: "Disk Usage",
                  value: disk == null ? "—" : "$disk%",
                  percent: disk,
                  icon: Icons.storage_outlined,
                  subtext: disk == null ? "—" : "$disk% used",
                ),
                _MetricData(
                  label: "Uptime",
                  value: _uptimeText(),
                  percent: null,
                  icon: Icons.schedule,
                  subtext:
                      "Started: ${_formatLocalTimestamp(_valueOrDash(_overall?.startedAt))}",
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildServicesSection(
              context: context,
              showSkeleton: showSkeleton,
              title: "Services",
              subtitle: services.isEmpty
                  ? "No data"
                  : "$runningCount/${services.length} healthy",
              services: services,
            ),
            /*
            const SizedBox(height: 16),
            _buildRecommendationSection(
              context: context,
              needsAttention: needsAttention,
              overallUp: overallUp,
            ),
            if (!overallUp) ...[
              const SizedBox(height: 12),
              _buildAlertCard(
                context: context,
                icon: Icons.warning_amber_rounded,
                title: "Service Degradation Detected",
                message:
                    "Overall status indicates the server is down. Investigate critical services and infrastructure health.",
              ),
            ],
            const SizedBox(height: 20),
            _buildSectionHeaderCard(
              context: context,
              title: "Database Metrics",
              subtitle: pgName,
              child: Column(
                children: [
                  _buildInfoRow("Size", _pgSizeText(pgPrimary)),
                  _buildInfoRow(
                    "Connections",
                    pgConnections != null ? "$pgConnections" : "—",
                  ),
                  _buildInfoRow(
                    "Dead tuples",
                    pgDeadTuples != null ? "$pgDeadTuples" : "—",
                  ),
                  if (addressDb != null) ...[
                    const SizedBox(height: 10),
                    _buildInfoRow(
                      "Address DB size",
                      _pgSizeText(addressDb),
                      color: addressDb.isUp ? null : Colors.red,
                    ),
                    _buildInfoRow(
                      "Address DB connections",
                      "${addressDb.connections}",
                      color: addressDb.isUp ? null : Colors.red,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _actionChip("Refresh"),
                      _actionChip("Vacuum"),
                      _actionChip("Diagnostics"),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionHeaderCard(
              context: context,
              title: "Redis",
              child: Column(
                children: [
                  _buildInfoRow("State", redisState, color: redisColor),
                  _buildInfoRow("Used", redisUsed),
                  _buildInfoRow("Hit rate", redisHitRate),
                  _buildInfoRow("Keys", redisKeys),
                  const SizedBox(height: 12),
                  _actionChip("Restart Redis", color: Colors.orange),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionHeaderCard(
              context: context,
              title: "Socket.io",
              child: Column(
                children: [
                  _buildInfoRow("Clients", socketClients),
                  _buildInfoRow("Rooms", socketRooms),
                  _buildInfoRow("Events/sec", socketEvents),
                  const SizedBox(height: 12),
                  _actionChip("Restart Socket", color: Colors.orange),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionHeaderCard(
              context: context,
              title: "BullMQ",
              child: Column(
                children: [
                  _queueRow(
                    "ingest",
                    bullIngest,
                    wait: bullIngestWait,
                    act: bullIngestAct,
                    delay: bullIngestDelay,
                    fail: bullIngestFail,
                  ),
                  _queueRow(
                    "notifications",
                    bullNotifications,
                    wait: bullNotificationsWait,
                    act: bullNotificationsAct,
                    delay: bullNotificationsDelay,
                    fail: bullNotificationsFail,
                  ),
                  _queueRow(
                    "geocoder",
                    bullGeocode,
                    wait: bullGeocodeWait,
                    act: bullGeocodeAct,
                    delay: bullGeocodeDelay,
                    fail: bullGeocodeFail,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionHeaderCard(
              context: context,
              title: "Firebase",
              child: Column(
                children: [
                  _buildInfoRow(
                    "FCM",
                    firebaseFcm,
                    color: _serviceColor(firebaseFcm),
                  ),
                  _buildInfoRow("Last ping", firebaseLastPing),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildDangerZone(context, hp, fs),
            */
              ],
            ),
          ),
          Positioned(
            left: hp,
            right: hp,
            top: 0,
            child: SuperAdminHomeAppBar(
              title: 'Server',
              leadingIcon: Symbols.storage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double scale = (width / 420).clamp(0.9, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.surfaceVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 32 * scale,
            height: 32 * scale,
            decoration: BoxDecoration(
              color: colorScheme.onSurface,
              borderRadius: BorderRadius.circular(12 * scale),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.storage_rounded,
              color: colorScheme.surface,
              size: 15 * scale,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Server",
              style: GoogleFonts.roboto(
                fontSize: 16 * scale,
                height: 20 / 16,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.onSurface,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.close,
                color: colorScheme.surface,
                size: 15 * scale,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringCard({
    required BuildContext context,
    required bool loading,
    required String title,
    required String subtitle,
    required String localStatus,
    required String localLastCheck,
    required VoidCallback? onRefresh,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double scale = (width / 420).clamp(0.9, 1.0);
    final double fsSection = 18 * scale;
    final double fsMain = 14 * scale;
    final double fsSecondary = 12 * scale;
    final double fsMeta = 11 * scale;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(hp),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: fsSection,
                        height: 24 / 18,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.roboto(
                        fontSize: fsSecondary,
                        height: 16 / 12,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: onRefresh,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(8),
                  side:
                      BorderSide(color: colorScheme.onSurface.withOpacity(0.2)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: loading
                      ? const AppShimmer(width: 16, height: 16, radius: 8)
                      : Icon(
                          Icons.refresh_rounded,
                          color: colorScheme.onSurface,
                          size: 18 * scale,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? colorScheme.surfaceVariant
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Local agent status",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.roboto(
                          fontSize: fsMain,
                          height: 20 / 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Last check \u00b7 $localLastCheck",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.roboto(
                          fontSize: fsSecondary,
                          height: 16 / 12,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        localStatus.trim().isEmpty ? '—' : localStatus,
                        style: GoogleFonts.roboto(
                          fontSize: fsMeta,
                          height: 14 / 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringRow(BuildContext context, _MonitoringRowData row) {
    final colorScheme = Theme.of(context).colorScheme;
    final double scale =
        (MediaQuery.of(context).size.width / 420).clamp(0.9, 1.0);
    final statusText = row.status.trim().isEmpty ? '—' : row.status;
    final statusColor =
        statusText == '—' ? Colors.grey : _serviceColor(statusText);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.label,
                  style: GoogleFonts.roboto(
                    fontSize: 12 * scale,
                    height: 16 / 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  row.meta,
                  style: GoogleFonts.roboto(
                    fontSize: 11 * scale,
                    height: 14 / 11,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          _buildStatusPill(statusText, statusColor),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String text, Color color) {
    final double scale =
        (MediaQuery.of(context).size.width / 420).clamp(0.9, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: GoogleFonts.roboto(
          fontSize: 11 * scale,
          height: 14 / 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAlertCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String message,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double scale =
        (MediaQuery.of(context).size.width / 420).clamp(0.9, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.surfaceVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.onSurface, size: 16 * scale),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontSize: 14 * scale,
                    height: 20 / 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.roboto(
                    fontSize: 12 * scale,
                    height: 17 / 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSection({
    required BuildContext context,
    required bool showSkeleton,
    required String title,
    required String subtitle,
    required String loadAvgText,
    required List<_MetricData> metrics,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double scale =
        (MediaQuery.of(context).size.width / 420).clamp(0.9, 1.0);
    final double fsSection = 18 * scale;
    final double fsSecondary = 12 * scale;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? colorScheme.surfaceVariant
              : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: fsSection,
              height: 24 / 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          if (subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.roboto(
                fontSize: fsSecondary,
                height: 16 / 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (showSkeleton) ...[
            _buildMetricSkeleton(context),
          ] else ...[
            _buildMetricsGrid(context: context, metrics: metrics),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricsGrid({
    required BuildContext context,
    required List<_MetricData> metrics,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double spacing = 10;
        final double cardWidth =
            (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics.map((m) {
            return SizedBox(
              width: cardWidth,
              child: _buildMetricCard(context, m),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMetricCard(BuildContext context, _MetricData data) {
    final colorScheme = Theme.of(context).colorScheme;
    final double scale =
        (MediaQuery.of(context).size.width / 420).clamp(0.9, 1.0);
    final double fsLabel = 11 * scale;
    final double fsValue = 32 * scale;
    final double fsSecondary = 12 * scale;
    final percent = data.percent;
    final int? clamped = percent == null ? null : percent.clamp(0, 100).toInt();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? colorScheme.surfaceVariant
              : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data.label,
                  style: GoogleFonts.roboto(
                    fontSize: fsLabel,
                    height: 14 / 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              Icon(
                data.icon,
                size: 18 * scale,
                color: Colors.grey.shade500,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.roboto(
              fontSize: fsValue,
              height: 34 / 32,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.subtext,
            style: GoogleFonts.roboto(
              fontSize: fsSecondary,
              height: 14 / 11,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          if (clamped != null) ...[
            const SizedBox(height: 8),
            _metricProgressBar(context, clamped),
          ],
        ],
      ),
    );
  }

  Widget _metricProgressBar(BuildContext context, int? percent) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        minHeight: 6,
        value: ((percent ?? 0) / 100).clamp(0.0, 1.0),
        backgroundColor: colorScheme.onSurface.withOpacity(0.08),
        valueColor: AlwaysStoppedAnimation<Color>(
          colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildServicesSkeleton(BuildContext context) {
    return Column(
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.surfaceVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                AppShimmer(width: 120, height: 14, radius: 8),
                SizedBox(height: 12),
                AppShimmer(width: 200, height: 12, radius: 8),
                SizedBox(height: 12),
                AppShimmer(width: 160, height: 12, radius: 8),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildServicesSection({
    required BuildContext context,
    required bool showSkeleton,
    required String title,
    required String subtitle,
    required List<ServerServiceItem> services,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double scale =
        (MediaQuery.of(context).size.width / 420).clamp(0.9, 1.0);
    final double fsSection = 18 * scale;
    final double fsSecondary = 12 * scale;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontSize: fsSection,
                    height: 24 / 18,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.roboto(
                    fontSize: fsSecondary,
                    height: 16 / 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          if (showSkeleton) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildServicesSkeleton(context),
            ),
          ] else if (services.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildEmptyCard(context, "No services data available."),
            ),
          ] else ...[
            Column(
              children: services.map((s) {
                final statusText =
                    s.status.isNotEmpty ? s.status : 'unknown';
                final pid = _valueOrDash(
                  _firstPathValue(s.raw, const [
                    'pid',
                    'processId',
                    'process_id',
                  ]),
                );
                final port = _formatPortValue(
                  _firstPathValue(s.raw, const [
                    'port',
                    'ports',
                    'listenPort',
                    'listen_port',
                  ]),
                );
                final uptimeSec = _asInt(
                  _firstPathValue(s.raw, const [
                    'uptimeSec',
                    'uptimeSeconds',
                    'uptime_sec',
                    'uptime',
                  ]),
                );
                final description = _valueOrDash(
                  _firstPathValue(s.raw, const [
                    'description',
                    'note',
                    'details',
                  ]),
                );
                final message = _valueOrDash(
                  _firstPathValue(s.raw, const [
                    'message',
                  ]),
                );
                return Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
                  child: _buildServiceCard(
                    context: context,
                    name: s.name.isNotEmpty ? s.name : 'Service',
                    status: statusText,
                    pid: pid,
                    port: port,
                    uptimeSec: uptimeSec,
                    description: description,
                    message: message,
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildMetricSkeleton(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double spacing = 10;
        final double cardWidth =
            (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(4, (index) {
            return SizedBox(
              width: cardWidth,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppShimmer(width: 70, height: 10, radius: 8),
                    SizedBox(height: 8),
                    AppShimmer(width: 90, height: 16, radius: 8),
                    SizedBox(height: 10),
                    AppShimmer(width: double.infinity, height: 6, radius: 8),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildServiceCard({
    required BuildContext context,
    required String name,
    required String status,
    required String pid,
    required String port,
    required int? uptimeSec,
    required String description,
    required String message,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double scale =
        (MediaQuery.of(context).size.width / 420).clamp(0.9, 1.0);
    final double fsTitle = 14 * scale;
    final double fsSecondary = 12 * scale;
    final double fsMeta = 11 * scale;
    final statusColor = _serviceColor(status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.surfaceVariant),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.onSurface.withOpacity(0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: GoogleFonts.roboto(
                            fontSize: fsTitle,
                            height: 20 / 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildPill(context, status, statusColor),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Uptime",
                      style: GoogleFonts.roboto(
                        fontSize: fsMeta,
                        height: 14 / 11,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatUptimeAbbrev(
                        uptimeSec ?? 0,
                      ),
                      style: GoogleFonts.roboto(
                        fontSize: fsSecondary,
                        height: 16 / 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description == '—' ? "No description available." : description,
              style: GoogleFonts.roboto(
                fontSize: fsSecondary,
                height: 16 / 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withOpacity(0.65),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final double spacing = 8;
                final double cellWidth =
                    (constraints.maxWidth - spacing) / 2;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    SizedBox(
                      width: cellWidth,
                      child: _infoCell(context, "PID", pid),
                    ),
                    SizedBox(
                      width: cellWidth,
                      child: _infoCell(context, "Port", port),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.onSurface.withOpacity(0.08),
                ),
              ),
              child: Text(
                message == '—' ? "No message available." : message,
                style: GoogleFonts.roboto(
                  fontSize: fsSecondary,
                  height: 16 / 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.65),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (_serviceColor(status) == Colors.green) ...[
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      side: BorderSide(
                        color: colorScheme.onSurface.withOpacity(0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh,
                          size: 16 * scale,
                          color: colorScheme.onSurface,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Refresh",
                          style: GoogleFonts.roboto(
                            fontSize: fsTitle,
                            height: 20 / 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      side: BorderSide(
                        color: colorScheme.onSurface.withOpacity(0.2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow_outlined,
                          size: 16 * scale,
                          color: colorScheme.onSurface,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Start",
                          style: GoogleFonts.roboto(
                            fontSize: fsTitle,
                            height: 20 / 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCell(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    final double scale =
        (MediaQuery.of(context).size.width / 420).clamp(0.9, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.onSurface.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 11 * scale,
              height: 14 / 11,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 12 * scale,
              height: 16 / 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPill(BuildContext context, String text, Color color) {
    final double scale =
        (MediaQuery.of(context).size.width / 420).clamp(0.9, 1.0);
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: GoogleFonts.roboto(
          fontSize: 11 * scale,
          height: 14 / 11,
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildRecommendationSection({
    required BuildContext context,
    required bool needsAttention,
    required bool overallUp,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double fs = AdaptiveUtils.getTitleFontSize(
      MediaQuery.of(context).size.width,
    );
    final String message = needsAttention
        ? "Review unhealthy services and restart or investigate issues where necessary."
        : "System is healthy. Continue monitoring and run periodic checks.";
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Recommended Action",
            style: GoogleFonts.roboto(
              fontSize: fs + 5,
              height: 24 / 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Next step based on current system state",
            style: GoogleFonts.roboto(
              fontSize: fs - 1,
              height: 16 / 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  needsAttention
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle,
                  color: needsAttention ? Colors.orange : Colors.green,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        needsAttention ? "Action Required" : "All Good",
                        style: GoogleFonts.roboto(
                          fontSize: fs,
                          height: 18 / 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: GoogleFonts.roboto(
                          fontSize: fs,
                          height: 18 / 13,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface.withOpacity(0.65),
                        ),
                      ),
                      if (!overallUp)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            "Overall status is down. Prioritize incident response.",
                            style: GoogleFonts.roboto(
                              fontSize: fs,
                              height: 18 / 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.red,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeaderCard({
    required BuildContext context,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double scale =
        (MediaQuery.of(context).size.width / 420).clamp(0.9, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: 18 * scale,
                  height: 24 / 18,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(width: 8),
                Text(
                  subtitle,
                  style: GoogleFonts.roboto(
                    fontSize: 12 * scale,
                    height: 16 / 12,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyCard(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    final double scale =
        (MediaQuery.of(context).size.width / 420).clamp(0.9, 1.0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.surfaceVariant),
      ),
      child: Text(
        message,
        style: GoogleFonts.roboto(
          fontSize: 12 * scale,
          height: 16 / 12,
          color: colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context, double hp, double fs) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(hp),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.error.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: colorScheme.error,
                size: fs + 6,
              ),
              const SizedBox(width: 12),
              Text(
                "Delete Data (Logs)",
                style: GoogleFonts.roboto(
                  fontSize: fs + 4,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Permanently delete GPS logs for a date range.",
            style: GoogleFonts.roboto(
              fontSize: fs - 2,
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Select date range",
            style: GoogleFonts.roboto(
              fontSize: fs,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          CalendarDatePicker2(
            config: CalendarDatePicker2WithActionButtonsConfig(
              calendarType: CalendarDatePicker2Type.range,
              selectedDayHighlightColor: colorScheme.primary,
              dayTextStyle: TextStyle(
                color: colorScheme.onSurface,
              ),
              todayTextStyle: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              controlsTextStyle: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            value: _dates,
            onValueChanged: (dates) => setState(() => _dates = dates),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                "Delete Selected Range",
                style: GoogleFonts.roboto(
                  fontSize: fs,
                  color: colorScheme.onError,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    String? subtitle,
    String? status,
    Color? statusColor,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;

    // FIX: Add hp here
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double scale = (width / 420).clamp(0.9, 1.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(hp),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.storage_rounded,
                size: 16 * scale,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: 18 * scale,
                  height: 24 / 18,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface.withOpacity(0.9),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(width: 12),
                Text(
                  subtitle,
                  style: GoogleFonts.roboto(
                    fontSize: 12 * scale,
                    height: 16 / 12,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
              if (status != null) ...[
                const Spacer(),
                Text(
                  status,
                  style: GoogleFonts.roboto(
                    fontSize: 12 * scale,
                    height: 16 / 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    final colorScheme = Theme.of(context).colorScheme;
    final double scale =
        (MediaQuery.of(context).size.width / 420).clamp(0.9, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: GoogleFonts.roboto(
              fontSize: 12 * scale,
              height: 16 / 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 12 * scale,
              height: 16 / 12,
              color: color ?? colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLine(
    BuildContext context,
    double widthFactor, {
    double height = 14,
  }) {
    final width = MediaQuery.of(context).size.width;
    final clamped = widthFactor.clamp(0.15, 1.0).toDouble();
    return AppShimmer(width: width * clamped, height: height, radius: 8);
  }

  Widget _buildShimmerProgress(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppShimmer(width: width * 0.28, height: 14, radius: 8),
        const SizedBox(height: 8),
        AppShimmer(width: double.infinity, height: 8, radius: 8),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildProgress(String label, int? percent) {
    final colorScheme = Theme.of(context).colorScheme;
    final double scale =
        (MediaQuery.of(context).size.width / 420).clamp(0.9, 1.0);
    final int? clampedPercent = percent == null
        ? null
        : percent.clamp(0, 100).toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 12 * scale,
                height: 16 / 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              clampedPercent == null ? "—" : "$clampedPercent%",
              style: GoogleFonts.roboto(
                fontSize: 12 * scale,
                height: 16 / 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (clampedPercent == null)
          Container(
            width: double.infinity,
            height: 8,
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(999),
            ),
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: double.infinity,
              height: 8,
              color: colorScheme.surfaceVariant,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: clampedPercent / 100,
                  child: Container(
                    color: clampedPercent > 80
                        ? Colors.red
                        : clampedPercent > 60
                        ? Colors.orange
                        : colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _serviceRow(String name, String status, String since, Color color) {
    final double scale =
        (MediaQuery.of(context).size.width / 420).clamp(0.9, 1.0);
    final normalizedStatus = status.toLowerCase();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.roboto(
                    fontSize: 14 * scale,
                    height: 20 / 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "since $since",
                  style: GoogleFonts.roboto(
                    fontSize: 12 * scale,
                    height: 16 / 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          if (normalizedStatus != "running")
            _actionChip(
              "Restart",
              color: normalizedStatus == "stopped" ? Colors.red : Colors.orange,
            ),
        ],
      ),
    );
  }

  Widget _queueRow(
    String name,
    String state, {
    required String wait,
    required String act,
    required String delay,
    required String fail,
  }) {
    final double scale =
        (MediaQuery.of(context).size.width / 420).clamp(0.9, 1.0);
    final normalizedState = state.toLowerCase();
    final stateColor = normalizedState == 'unknown'
        ? Colors.grey
        : normalizedState == "paused"
        ? Colors.orange
        : _serviceColor(state);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            "$name ",
            style: GoogleFonts.roboto(
              fontSize: 14 * scale,
              height: 20 / 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            state,
            style: GoogleFonts.roboto(
              fontSize: 12 * scale,
              height: 16 / 12,
              color: stateColor,
            ),
          ),
          const Spacer(),
          Text(
            "wait:$wait act:$act delay:$delay fail:$fail",
            style: GoogleFonts.roboto(
              fontSize: 11 * scale,
              height: 14 / 11,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionChip(String label, {Color? color}) {
    final colorScheme = Theme.of(context).colorScheme;
    final double scale =
        (MediaQuery.of(context).size.width / 420).clamp(0.9, 1.0);
    return ActionChip(
      label: Text(
        label,
        style: GoogleFonts.roboto(
          fontSize: 14 * scale,
          height: 20 / 14,
          fontWeight: FontWeight.w600,
          color: color ?? colorScheme.primary,
        ),
      ),
      backgroundColor: (color ?? colorScheme.primary).withOpacity(0.1),
      onPressed: () {},
    );
  }
}

class _StatusItem {
  final String label;
  final String value;

  const _StatusItem(this.label, this.value);
}

class _MetricData {
  final String label;
  final String value;
  final String subtext;
  final int? percent;
  final IconData icon;

  const _MetricData({
    required this.label,
    required this.value,
    required this.subtext,
    required this.percent,
    required this.icon,
  });
}

class _MonitoringRowData {
  final String label;
  final String meta;
  final String status;

  const _MonitoringRowData({
    required this.label,
    required this.meta,
    required this.status,
  });
}
