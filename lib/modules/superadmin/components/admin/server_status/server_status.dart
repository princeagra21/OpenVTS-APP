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
import 'package:fleet_stack/modules/superadmin/layout/app_layout.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double fs = AdaptiveUtils.getTitleFontSize(width);
    final overallUp = _overall?.isUp == true;
    final overallStatusText = _overall == null
        ? "Unknown"
        : (overallUp ? "Up" : "Down");
    final overallStatusColor = _overall == null
        ? Colors.grey
        : (overallUp ? Colors.green : Colors.red);
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
    final serviceRows = _services
        .map(
          (s) => <String, dynamic>{
            'name': s.name.isNotEmpty ? s.name : 'Service',
            'status': s.status.isNotEmpty ? s.status : 'unknown',
            'since': s.since.isNotEmpty ? s.since : "—",
            'color': _serviceColor(s.status),
          },
        )
        .toList();
    final runningCount = serviceRows
        .where((e) => e['status'].toString().toLowerCase() == 'running')
        .length;
    final hasServerData =
        _overall != null ||
        pgPrimary != null ||
        health.isNotEmpty ||
        serviceRows.isNotEmpty;
    final showSkeleton = _loading && !hasServerData;
    final loadAvgText = (load1 != null && load5 != null && load15 != null)
        ? "${load1.toStringAsFixed(2)} / ${load5.toStringAsFixed(2)} / ${load15.toStringAsFixed(2)}"
        : "—";

    return AppLayout(
      title: "FLEET STACK",
      subtitle: "Server Status",
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 3,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MAIN CARD
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(hp),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // REFRESH BUTTON (top-right)
                  Align(
                    alignment: Alignment.topRight,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _loadAll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        padding: EdgeInsets.symmetric(
                          horizontal: hp + 4,
                          vertical: hp - 4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: SizedBox(
                        width: 14,
                        height: 14,
                        child: _loading
                            ? const AppShimmer(width: 14, height: 14, radius: 7)
                            : Icon(
                                Icons.refresh_rounded,
                                color: colorScheme.onPrimary,
                              ),
                      ),
                      label: Text(
                        "Refresh",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // TITLE
                  Text(
                    "Server Status",
                    style: GoogleFonts.inter(
                      fontSize: fs + 8,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Monitor and manage server infrastructure",
                    style: GoogleFonts.inter(
                      fontSize: fs - 1,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (showSkeleton) ...[
                    _buildSection(
                      context: context,
                      title: "Overall",
                      children: [
                        _buildShimmerLine(context, 0.36),
                        const SizedBox(height: 10),
                        _buildShimmerLine(context, 0.52),
                        const SizedBox(height: 20),
                        _buildShimmerProgress(context),
                        _buildShimmerProgress(context),
                        _buildShimmerProgress(context),
                        const SizedBox(height: 8),
                        _buildShimmerLine(context, 0.66),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      context: context,
                      title: "PostgreSQL",
                      children: [
                        _buildShimmerLine(context, 0.4),
                        const SizedBox(height: 10),
                        _buildShimmerLine(context, 0.34),
                        const SizedBox(height: 10),
                        _buildShimmerLine(context, 0.32),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: const [
                            AppShimmer(width: 82, height: 28, radius: 14),
                            AppShimmer(width: 76, height: 28, radius: 14),
                            AppShimmer(width: 96, height: 28, radius: 14),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      context: context,
                      title: "Services",
                      children: List.generate(
                        4,
                        (_) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: _buildShimmerLine(context, 0.72),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      context: context,
                      title: "Redis",
                      children: [
                        _buildShimmerLine(context, 0.3),
                        const SizedBox(height: 10),
                        _buildShimmerLine(context, 0.25),
                        const SizedBox(height: 10),
                        _buildShimmerLine(context, 0.22),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      context: context,
                      title: "Socket.io",
                      children: [
                        _buildShimmerLine(context, 0.28),
                        const SizedBox(height: 10),
                        _buildShimmerLine(context, 0.26),
                        const SizedBox(height: 10),
                        _buildShimmerLine(context, 0.24),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      context: context,
                      title: "BullMQ",
                      children: List.generate(
                        3,
                        (_) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: _buildShimmerLine(context, 0.78),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      context: context,
                      title: "Firebase",
                      children: [
                        _buildShimmerLine(context, 0.27),
                        const SizedBox(height: 10),
                        _buildShimmerLine(context, 0.45),
                      ],
                    ),
                  ] else ...[
                    // OVERALL
                    _buildSection(
                      context: context,
                      title: "Overall",
                      status: overallStatusText,
                      statusColor: overallStatusColor,
                      children: [
                        _buildInfoRow("Uptime", _uptimeText()),
                        _buildInfoRow(
                          "Started",
                          _valueOrDash(_overall?.startedAt),
                        ),
                        const SizedBox(height: 20),
                        _buildProgress("CPU", cpu),
                        _buildProgress("Memory", mem),
                        _buildProgress("Disk", disk),
                        const SizedBox(height: 12),
                        Text(
                          "Load avg: $loadAvgText",
                          style: GoogleFonts.inter(
                            fontSize: fs - 2,
                            color: colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildSection(
                      context: context,
                      title: "PostgreSQL",
                      subtitle: pgName,
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
                        const SizedBox(height: 16),
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
                    const SizedBox(height: 24),

                    _buildSection(
                      context: context,
                      title: "Services",
                      subtitle: serviceRows.isEmpty
                          ? "No data"
                          : "$runningCount/${serviceRows.length} running",
                      children: serviceRows.isEmpty
                          ? [_buildInfoRow("Status", "No services data")]
                          : serviceRows.map((s) {
                              final statusText = s['status'].toString();
                              final colorValue = s['color'];
                              final rowColor = colorValue is Color
                                  ? colorValue
                                  : _serviceColor(statusText);
                              return _serviceRow(
                                s['name'].toString(),
                                statusText,
                                s['since'].toString(),
                                rowColor,
                              );
                            }).toList(),
                    ),
                    const SizedBox(height: 24),

                    _buildSection(
                      context: context,
                      title: "Redis",
                      children: [
                        _buildInfoRow("State", redisState, color: redisColor),
                        _buildInfoRow("Used", redisUsed),
                        _buildInfoRow("Hit rate", redisHitRate),
                        _buildInfoRow("Keys", redisKeys),
                        const SizedBox(height: 16),
                        _actionChip("Restart Redis", color: Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildSection(
                      context: context,
                      title: "Socket.io",
                      children: [
                        _buildInfoRow("Clients", socketClients),
                        _buildInfoRow("Rooms", socketRooms),
                        _buildInfoRow("Events/sec", socketEvents),
                        const SizedBox(height: 16),
                        _actionChip("Restart Socket", color: Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildSection(
                      context: context,
                      title: "BullMQ",
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
                    const SizedBox(height: 24),

                    _buildSection(
                      context: context,
                      title: "Firebase",
                      children: [
                        _buildInfoRow(
                          "FCM",
                          firebaseFcm,
                          color: _serviceColor(firebaseFcm),
                        ),
                        _buildInfoRow("Last ping", firebaseLastPing),
                      ],
                    ),
                  ],
                  const SizedBox(height: 32),

                  // DANGER ZONE: DELETE LOGS
                  Container(
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
                              style: GoogleFonts.inter(
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
                          style: GoogleFonts.inter(
                            fontSize: fs - 2,
                            color: colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Select date range",
                          style: GoogleFonts.inter(
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
                          onValueChanged: (dates) =>
                              setState(() => _dates = dates),
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
                              style: GoogleFonts.inter(
                                fontSize: fs,
                                color: colorScheme.onError,
                                fontWeight: FontWeight.w600,
                              ),
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
    final double fs = AdaptiveUtils.getTitleFontSize(width);

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
                size: fs + 6,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: fs + 3,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface.withOpacity(0.9),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(width: 12),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: fs - 2,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
              if (status != null) ...[
                const Spacer(),
                Text(
                  status,
                  style: GoogleFonts.inter(
                    fontSize: fs - 1,
                    fontWeight: FontWeight.bold,
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
    final double fs = AdaptiveUtils.getTitleFontSize(
      MediaQuery.of(context).size.width,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: GoogleFonts.inter(
              fontSize: fs - 1,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: fs - 1,
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
    final double fs = AdaptiveUtils.getTitleFontSize(
      MediaQuery.of(context).size.width,
    );
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
              style: GoogleFonts.inter(
                fontSize: fs - 1,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              clampedPercent == null ? "—" : "$clampedPercent%",
              style: GoogleFonts.inter(
                fontSize: fs - 1,
                fontWeight: FontWeight.w600,
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
    final double fs = AdaptiveUtils.getTitleFontSize(
      MediaQuery.of(context).size.width,
    );
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
                  style: GoogleFonts.inter(
                    fontSize: fs - 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "since $since",
                  style: GoogleFonts.inter(
                    fontSize: fs - 4,
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
    final double fs = AdaptiveUtils.getTitleFontSize(
      MediaQuery.of(context).size.width,
    );
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
            style: GoogleFonts.inter(
              fontSize: fs - 1,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            state,
            style: GoogleFonts.inter(fontSize: fs - 3, color: stateColor),
          ),
          const Spacer(),
          Text(
            "wait:$wait act:$act delay:$delay fail:$fail",
            style: GoogleFonts.inter(
              fontSize: fs - 5,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionChip(String label, {Color? color}) {
    final colorScheme = Theme.of(context).colorScheme;
    final double fs = AdaptiveUtils.getTitleFontSize(
      MediaQuery.of(context).size.width,
    );
    return ActionChip(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: fs - 3,
          fontWeight: FontWeight.w600,
          color: color ?? colorScheme.primary,
        ),
      ),
      backgroundColor: (color ?? colorScheme.primary).withOpacity(0.1),
      onPressed: () {},
    );
  }
}
