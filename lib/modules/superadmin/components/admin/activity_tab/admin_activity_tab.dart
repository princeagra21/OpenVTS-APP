import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/network/result.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AdminActivityTab extends StatefulWidget {
  final String adminId;

  const AdminActivityTab({super.key, required this.adminId});

  @override
  State<AdminActivityTab> createState() => _AdminActivityTabState();
}

class _AdminActivityTabState extends State<AdminActivityTab> {
  final CancelToken _token = CancelToken();
  ApiClient? _api;
  bool _loading = false;
  bool _errorShown = false;
  List<_ActivityLog> _items = const <_ActivityLog>[];
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _selectedFilter = 'All';
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _token.cancel('AdminActivityTab disposed');
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );

      final res = await _api!.get(
        '/superadmin/admin/${widget.adminId}/activitylogs',
        queryParameters: const {'limit': 20},
        cancelToken: _token,
      );

      if (!mounted) return;

      res.when(
        success: (data) {
          final items = _extractItems(data);
          setState(() {
            _loading = false;
            _items = items;
          });
        },
        failure: (err) {
          setState(() => _loading = false);
          if (_errorShown) return;
          _errorShown = true;
          final msg =
              (err is ApiException &&
                      (err.statusCode == 401 || err.statusCode == 403))
                  ? 'Not authorized to load activity logs.'
                  : "Couldn't load activity logs.";
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (_errorShown) return;
      _errorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load activity logs.")),
      );
    }
  }

  List<_ActivityLog> _extractItems(Object? data) {
    final map = _coerceMap(data);
    final dataMap = _coerceMap(map['data']);
    final inner = _coerceMap(dataMap['data']);
    final rawList = inner['items'];
    if (rawList is List) {
      return rawList
          .whereType<Map>()
          .map((e) => _ActivityLog.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const <_ActivityLog>[];
  }

  List<_ActivityLog> _filteredItems() {
    final q = _query.trim().toLowerCase();
    final now = DateTime.now();
    final range = _dateRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );
    return _items.where((log) {
      if (log.createdAt != null) {
        if (log.createdAt!.isBefore(range.start) ||
            log.createdAt!.isAfter(range.end)) {
          return false;
        }
      }
      if (_selectedFilter != 'All') {
        final action = log.action.toUpperCase();
        if (!action.contains(_selectedFilter)) return false;
      }
      if (q.isEmpty) return true;
      final hay = <String>[
        log.action,
        log.entity,
        log.entityId?.toString() ?? '',
        log.ip,
        log.browser,
        log.platform,
        log.path,
        log.method,
        log.durationMs?.toString() ?? '',
      ].join(' ').toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  Map<String, dynamic> _coerceMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data.cast());
    return <String, dynamic>{};
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('d MMM, yyyy · hh:mm a').format(dt);
  }

  String _titleFor(_ActivityLog log) {
    final action = log.action.isEmpty ? 'Activity' : log.action;
    return action.replaceAll('.', ' · ');
  }

  String _subFor(_ActivityLog log) {
    final parts = <String>[];
    if (log.entity.isNotEmpty) {
      parts.add(log.entity.toUpperCase());
    }
    if (log.entityId != null) {
      parts.add('#${log.entityId}');
    }
    if (log.method.isNotEmpty) {
      parts.add(log.method.toUpperCase());
    }
    if (log.path.isNotEmpty) {
      parts.add(log.path);
    }
    return parts.isEmpty ? '—' : parts.join(' · ');
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '—';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays <= 7) return '${diff.inDays}d ago';
    return DateFormat('d MMM yyyy').format(dt);
  }

  IconData _iconForAction(String action) {
    final a = action.toLowerCase();
    if (a.contains('vehicle_sensor') || a.contains('sensor')) {
      return Icons.flash_on;
    }
    if (a.contains('payment') || a.contains('renew')) {
      return Icons.payments_outlined;
    }
    if (a.contains('vehicle')) {
      return Icons.directions_car_outlined;
    }
    if (a.contains('driver')) {
      return Icons.person_outline;
    }
    if (a.contains('team')) {
      return Icons.group_outlined;
    }
    if (a.contains('user') || a.contains('users')) {
      return Icons.person_search_outlined;
    }
    if (a.contains('link')) {
      return Icons.link_outlined;
    }
    if (a.contains('unlink')) {
      return Icons.link_off_outlined;
    }
    return Icons.event_note_outlined;
  }

  Widget _infoCell({
    required String label,
    required String value,
    required ColorScheme colorScheme,
    required double labelSize,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: labelSize,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: labelSize,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppShimmer(
        width: double.infinity,
        height: 320,
        radius: 12,
      );
    }
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 420).clamp(0.9, 1.0);
    final headerSize = 18 * scale;
    final labelSize = AdaptiveUtils.getSubtitleFontSize(width) - 2;
    final items = _filteredItems();
    final rangeLabel = _dateRange == null
        ? 'Date range'
        : '${DateFormat('d MMM').format(_dateRange!.start)}'
            ' - ${DateFormat('d MMM').format(_dateRange!.end)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Admin Activity',
                      style: GoogleFonts.roboto(
                        fontSize: headerSize,
                        height: 24 / 18,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _loading ? null : _loadLogs,
                    icon: Icon(
                      Icons.refresh,
                      size: 18,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search activity...',
                  hintStyle: GoogleFonts.roboto(
                    fontSize: labelSize,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.onSurface.withOpacity(0.12),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.onSurface.withOpacity(0.12),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                style: GoogleFonts.roboto(
                  fontSize: labelSize,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (_selectedFilter == value) return;
                        setState(() => _selectedFilter = value);
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'All', child: Text('All')),
                        PopupMenuItem(
                          value: 'ADMIN',
                          child: Text('Admin'),
                        ),
                        PopupMenuItem(
                          value: 'USER',
                          child: Text('User'),
                        ),
                        PopupMenuItem(
                          value: 'VEHICLE',
                          child: Text('Vehicle'),
                        ),
                        PopupMenuItem(
                          value: 'PAYMENT',
                          child: Text('Payment'),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: colorScheme.onSurface.withOpacity(0.12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.tune,
                              size: 16,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _selectedFilter,
                              style: GoogleFonts.roboto(
                                fontSize: labelSize,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final now = DateTime.now();
                        DateTime? start = _dateRange?.start;
                        DateTime? end = _dateRange?.end;
                        final picked = await showDialog<DateTimeRange>(
                          context: context,
                          builder: (ctx) {
                            var selection = <DateTime?>[start, end];
                            return Dialog(
                              insetPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 24,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: StatefulBuilder(
                                  builder: (context, setDialogState) {
                                    return CalendarDatePicker2(
                                      config: CalendarDatePicker2Config(
                                        calendarType:
                                            CalendarDatePicker2Type.range,
                                        currentDate: now,
                                        selectedDayHighlightColor:
                                            colorScheme.primary,
                                        firstDate: DateTime(2020, 1, 1),
                                        lastDate: DateTime(2035, 12, 31),
                                      ),
                                      value: selection,
                                      onValueChanged: (values) {
                                        setDialogState(() {
                                          selection = values;
                                        });
                                        if (values.length >= 2 &&
                                            values[0] != null &&
                                            values[1] != null) {
                                          Navigator.of(ctx).pop(
                                            DateTimeRange(
                                              start: values[0]!,
                                              end: values[1]!,
                                            ),
                                          );
                                        }
                                      },
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        );
                        if (picked == null) return;
                        setState(() => _dateRange = picked);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: colorScheme.onSurface.withOpacity(0.12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.date_range,
                              size: 16,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                rangeLabel,
                                style: GoogleFonts.roboto(
                                  fontSize: labelSize,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.onSurface.withOpacity(0.08),
                  ),
                ),
                child: _loading
                    ? Column(
                        children: List.generate(
                          3,
                          (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AppShimmer(
                              width: double.infinity,
                              height: 84,
                              radius: 12,
                            ),
                          ),
                        ),
                      )
                    : items.isEmpty
                        ? Text(
                            'No activity logs found.',
                            style: GoogleFonts.roboto(
                              fontSize: labelSize,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          )
                        : Column(
                            children: items.map((log) {
                              return Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: colorScheme.onSurface
                                        .withOpacity(0.08),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).brightness ==
                                                    Brightness.light
                                                ? Colors.grey.shade50
                                                : colorScheme.surfaceVariant,
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(
                                            _iconForAction(log.action),
                                            size: 18,
                                            color: colorScheme.onSurface
                                                .withOpacity(0.7),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                log.action.isNotEmpty
                                                    ? log.action
                                                    : 'Activity',
                                                style: GoogleFonts.roboto(
                                                  fontSize: headerSize - 1,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      colorScheme.onSurface,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                              .brightness ==
                                                          Brightness.light
                                                      ? Colors.grey.shade50
                                                      : colorScheme
                                                          .surfaceVariant,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    999,
                                                  ),
                                                ),
                                                child: Text(
                                                  log.entity.isNotEmpty
                                                      ? log.entity
                                                      : '—',
                                                  style: GoogleFonts.roboto(
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color:
                                                        colorScheme.onSurface,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                    ],
                                  ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _infoCell(
                                            label: 'IP',
                                            value:
                                                log.ip.isNotEmpty ? log.ip : '—',
                                            colorScheme: colorScheme,
                                            labelSize: labelSize,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _infoCell(
                                            label: 'Browser',
                                            value: log.browser.isNotEmpty
                                                ? log.browser
                                                : '—',
                                            colorScheme: colorScheme,
                                            labelSize: labelSize,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _infoCell(
                                            label: 'OS',
                                            value: log.platform.isNotEmpty
                                                ? log.platform
                                                : '—',
                                            colorScheme: colorScheme,
                                            labelSize: labelSize,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _infoCell(
                                            label: _timeAgo(log.createdAt),
                                            value: _formatDateTime(
                                              log.createdAt,
                                            ),
                                            colorScheme: colorScheme,
                                            labelSize: labelSize,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metaPill({
    required String label,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.12)),
      ),
      child: Text(
        label,
        style: GoogleFonts.roboto(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface.withOpacity(0.8),
        ),
      ),
    );
  }
}

class _ActivityLog {
  final int id;
  final String action;
  final String entity;
  final int? entityId;
  final String ip;
  final String browser;
  final String platform;
  final DateTime? createdAt;
  final String path;
  final String method;
  final int? durationMs;

  const _ActivityLog({
    required this.id,
    required this.action,
    required this.entity,
    required this.entityId,
    required this.ip,
    required this.browser,
    required this.platform,
    required this.createdAt,
    required this.path,
    required this.method,
    required this.durationMs,
  });

  factory _ActivityLog.fromMap(Map<String, dynamic> map) {
    final meta = map['meta'];
    final metaMap = meta is Map ? Map<String, dynamic>.from(meta.cast()) : null;
    final createdRaw = map['createdAt'];
    DateTime? createdAt;
    if (createdRaw is String && createdRaw.isNotEmpty) {
      createdAt = DateTime.tryParse(createdRaw)?.toLocal();
    }

    return _ActivityLog(
      id: _asInt(map['id']) ?? 0,
      action: _asString(map['action']),
      entity: _asString(map['entity']),
      entityId: _asInt(map['entityId']),
      ip: _asString(map['ip']),
      browser: _asString(map['browser']),
      platform: _asString(map['platform']),
      createdAt: createdAt,
      path: _asString(metaMap?['path']),
      method: _asString(metaMap?['method']),
      durationMs: _asInt(metaMap?['durationMs']),
    );
  }

  static String _asString(Object? value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }

  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }
}
