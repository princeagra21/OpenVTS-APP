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

  final List<Map<String, dynamic>> _fallbackServices = const [
    {"name": "HTTP API", "status": "running", "since": "08/12/2025, 05:43:51"},
    {
      "name": "Device Ingest",
      "status": "running",
      "since": "08/12/2025, 00:43:51",
    },
    {
      "name": "WebSocket",
      "status": "degraded",
      "since": "08/12/2025, 06:13:51",
    },
    {
      "name": "Background Jobs",
      "status": "running",
      "since": "07/12/2025, 06:43:51",
    },
    {
      "name": "Notifications",
      "status": "stopped",
      "since": "08/12/2025, 06:38:51",
    },
    {"name": "Redis", "status": "running", "since": "08/12/2025, 04:43:51"},
  ];

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
    if (o == null) return "5d 13h 59m 5s";
    if (o.uptimeText.trim().isNotEmpty) return o.uptimeText;
    if (o.uptimeSeconds <= 0) return "5d 13h 59m 5s";
    final d = Duration(seconds: o.uptimeSeconds);
    final days = d.inDays;
    final hours = d.inHours % 24;
    final mins = d.inMinutes % 60;
    final secs = d.inSeconds % 60;
    return "${days}d ${hours}h ${mins}m ${secs}s";
  }

  String _pgSizeText(ServerPostgresStatus? p) {
    if (p == null) return "86 GB";
    if (p.sizeGb > 0) return "${p.sizeGb.toStringAsFixed(0)} GB";
    if (p.sizeBytes > 0) {
      final gb = p.sizeBytes / (1024 * 1024 * 1024);
      return "${gb.toStringAsFixed(1)} GB";
    }
    return "86 GB";
  }

  Map<String, dynamic> _asMap(Object? v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v.cast());
    return const <String, dynamic>{};
  }

  String _asString(Object? v) => v == null ? '' : v.toString();

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

      final overallRes = await _repo!.getServerOverallStatus(
        cancelToken: token,
      );
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

      overallRes.when(
        success: (d) => nextOverall = d,
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
          nextServices = ServerServiceItem.listFromHealth(raw);
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
          const SnackBar(
            content: Text(
              "Couldn't fully load server status. Showing fallback values.",
            ),
          ),
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
          : "Couldn't load server status. Showing fallback values.";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double fs = AdaptiveUtils.getTitleFontSize(width);
    final overallUp = _overall?.isUp ?? false;
    final overallStatusText = overallUp ? "Up" : "Down";
    final overallStatusColor = overallUp ? Colors.green : Colors.red;
    final cpu = _overall != null ? _overall!.cpuPercent.round() : 41;
    final mem = _overall != null ? _overall!.memPercent.round() : 63;
    final disk = _overall != null ? _overall!.diskPercent.round() : 72;
    final load1 = _overall != null ? _overall!.loadAvg1 : 0.52;
    final load5 = _overall != null ? _overall!.loadAvg5 : 0.61;
    final load15 = _overall != null ? _overall!.loadAvg15 : 0.73;
    final pgPrimary = _logsDb ?? _postgres ?? _addressDb;
    final pgName = (pgPrimary?.dbName.isNotEmpty == true)
        ? pgPrimary!.dbName
        : "fleetstack";
    final pgConnections = pgPrimary != null ? pgPrimary.connections : 38;
    final pgDeadTuples = pgPrimary != null ? pgPrimary.deadTuples : 120000;
    final addressDb = _addressDb;
    final healthData = _asMap(_healthRaw['data']);
    final health = healthData.isNotEmpty ? healthData : _healthRaw;
    final redisStateRaw = _firstPathValue(health, const [
      'redis.state',
      'redis.status',
      'redis.connectionState',
    ]);
    final redisState = _statusFromAny(redisStateRaw, 'connected');
    final redisUsedRaw = _firstPathValue(health, const [
      'redis.used',
      'redis.usedMB',
      'redis.memory',
      'redis.memoryMb',
      'redis.memoryMB',
    ]);
    final redisUsed = _asString(redisUsedRaw).trim().isNotEmpty
        ? _asString(redisUsedRaw)
        : '977 MB';
    final redisHitRateRaw = _firstPathValue(health, const [
      'redis.hitRate',
      'redis.hitrate',
      'redis.hit_rate',
    ]);
    final redisHitRate = _asString(redisHitRateRaw).trim().isNotEmpty
        ? _asString(redisHitRateRaw)
        : '91%';
    final redisKeysRaw = _firstPathValue(health, const ['redis.keys']);
    final redisKeys = _asString(redisKeysRaw).trim().isNotEmpty
        ? _asString(redisKeysRaw)
        : '785,123';
    final redisColor = _serviceColor(redisState);

    final socketClientsRaw = _firstPathValue(health, const [
      'socket.clients',
      'socketio.clients',
      'socketIo.clients',
    ]);
    final socketClients = _asString(socketClientsRaw).trim().isNotEmpty
        ? _asString(socketClientsRaw)
        : '1,420';
    final socketRoomsRaw = _firstPathValue(health, const [
      'socket.rooms',
      'socketio.rooms',
      'socketIo.rooms',
    ]);
    final socketRooms = _asString(socketRoomsRaw).trim().isNotEmpty
        ? _asString(socketRoomsRaw)
        : '220';
    final socketEventsRaw = _firstPathValue(health, const [
      'socket.eventsPerSec',
      'socket.events_sec',
      'socketio.eventsPerSec',
      'socketIo.eventsPerSec',
    ]);
    final socketEvents = _asString(socketEventsRaw).trim().isNotEmpty
        ? _asString(socketEventsRaw)
        : '340';

    final bullIngest = _statusFromAny(
      _firstPathValue(health, const ['bullmq.ingest', 'bull.ingest']),
      'Active',
    );
    final bullNotifications = _statusFromAny(
      _firstPathValue(health, const [
        'bullmq.notifications',
        'bull.notifications',
      ]),
      'paused',
    );
    final bullGeocode = _statusFromAny(
      _firstPathValue(health, const [
        'bullmq.geocode',
        'bullmq.geocoder',
        'bull.geocode',
      ]),
      'Active',
    );

    final firebaseFcmRaw = _firstPathValue(health, const [
      'firebase.fcm',
      'firebase.status',
      'firebase.reachable',
    ]);
    final firebaseFcm = _statusFromAny(firebaseFcmRaw, 'reachable');
    final firebasePingRaw = _firstPathValue(health, const [
      'firebase.lastPing',
      'firebase.last_ping',
    ]);
    final firebaseLastPing = _asString(firebasePingRaw).trim().isNotEmpty
        ? _asString(firebasePingRaw)
        : "08/12/2025, 06:44:46";
    final serviceRows = _services.isNotEmpty
        ? _services
              .map(
                (s) => <String, dynamic>{
                  'name': s.name.isNotEmpty ? s.name : 'Service',
                  'status': s.status.isNotEmpty ? s.status : 'unknown',
                  'since': s.since.isNotEmpty ? s.since : "—",
                  'color': _serviceColor(s.status),
                },
              )
              .toList()
        : _fallbackServices;
    final runningCount = serviceRows
        .where((e) => e['status'].toString().toLowerCase() == 'running')
        .length;

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
                            ? CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.onPrimary,
                                ),
                              )
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
                        (_overall?.startedAt.isNotEmpty == true)
                            ? _overall!.startedAt
                            : "02/12/2025, 16:44:46",
                      ),
                      const SizedBox(height: 20),
                      _buildProgress("CPU", cpu),
                      _buildProgress("Memory", mem),
                      _buildProgress("Disk", disk),
                      const SizedBox(height: 12),
                      Text(
                        "Load avg: ${load1.toStringAsFixed(2)} / ${load5.toStringAsFixed(2)} / ${load15.toStringAsFixed(2)}",
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
                      _buildInfoRow("Connections", "$pgConnections"),
                      _buildInfoRow("Dead tuples", "$pgDeadTuples"),
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
                    subtitle: "$runningCount/${serviceRows.length} running",
                    children: serviceRows
                        .map(
                          (s) => _serviceRow(
                            s['name'].toString(),
                            s['status'].toString(),
                            s['since'].toString(),
                            s['color'] as Color,
                          ),
                        )
                        .toList(),
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
                        wait: 42,
                        act: 6,
                        delay: 3,
                        fail: 1,
                      ),
                      _queueRow(
                        "notifications",
                        bullNotifications,
                        wait: 0,
                        act: 0,
                        delay: 0,
                        fail: 0,
                      ),
                      _queueRow(
                        "geocoder",
                        bullGeocode,
                        wait: 12,
                        act: 2,
                        delay: 1,
                        fail: 0,
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

  Widget _buildProgress(String label, int percent) {
    final colorScheme = Theme.of(context).colorScheme;
    final double fs = AdaptiveUtils.getTitleFontSize(
      MediaQuery.of(context).size.width,
    );
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
              "$percent%",
              style: GoogleFonts.inter(
                fontSize: fs - 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percent / 100,
          backgroundColor: colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation(
            percent > 80
                ? Colors.red
                : percent > 60
                ? Colors.orange
                : colorScheme.primary,
          ),
          minHeight: 8,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _serviceRow(String name, String status, String since, Color color) {
    final double fs = AdaptiveUtils.getTitleFontSize(
      MediaQuery.of(context).size.width,
    );
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
          if (status != "running")
            _actionChip(
              "Restart",
              color: status == "stopped" ? Colors.red : Colors.orange,
            ),
        ],
      ),
    );
  }

  Widget _queueRow(
    String name,
    String state, {
    required int wait,
    required int act,
    required int delay,
    required int fail,
  }) {
    final double fs = AdaptiveUtils.getTitleFontSize(
      MediaQuery.of(context).size.width,
    );
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
            style: GoogleFonts.inter(
              fontSize: fs - 3,
              color: state == "paused" ? Colors.orange : Colors.green,
            ),
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
