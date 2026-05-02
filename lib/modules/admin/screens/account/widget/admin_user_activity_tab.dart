import 'dart:convert';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/components/appbars/admin_home_appbar.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/admin/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AdminUserActivityTab extends StatefulWidget {
  final String userId;

  const AdminUserActivityTab({super.key, required this.userId});

  @override
  State<AdminUserActivityTab> createState() => _AdminUserActivityTabState();
}

class _AdminUserActivityTabState extends State<AdminUserActivityTab> {
  final CancelToken _token = CancelToken();
  final TextEditingController _searchController = TextEditingController();

  ApiClient? _api;
  bool _loading = false;
  bool _errorShown = false;
  List<_ActivityLog> _items = const <_ActivityLog>[];
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
    _token.cancel('AdminUserActivityTab disposed');
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
        '/admin/users/${widget.userId}/activitylogs',
        queryParameters: const {'limit': 20},
        cancelToken: _token,
      );

      if (!mounted) return;
      res.when(
        success: (data) {
          setState(() {
            _loading = false;
            _items = _extractItems(data);
            _errorShown = false;
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
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

  Map<String, dynamic> _coerceMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data.cast());
    return <String, dynamic>{};
  }

  DateTime _startOfDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  DateTime _endOfDay(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day, 23, 59, 59, 999);

  List<_ActivityLog> _filteredItems() {
    final q = _query.trim().toLowerCase();
    final DateTime? rangeStart = _dateRange == null
        ? null
        : _startOfDay(_dateRange!.start);
    final DateTime? rangeEnd = _dateRange == null
        ? null
        : _endOfDay(_dateRange!.end);

    return _items.where((log) {
      if (log.createdAt != null && rangeStart != null && rangeEnd != null) {
        if (log.createdAt!.isBefore(rangeStart) || log.createdAt!.isAfter(rangeEnd)) {
          return false;
        }
      }
      if (_selectedFilter != 'All' && !_matchesFilter(log, _selectedFilter)) {
        return false;
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

  bool _matchesFilter(_ActivityLog log, String filter) {
    final action = log.action.toUpperCase();
    final entity = log.entity.toUpperCase();
    switch (filter) {
      case 'Security':
        return action.contains('AUTH') ||
            action.contains('LOGIN') ||
            action.contains('LOGOUT') ||
            action.contains('PASSWORD') ||
            action.contains('SECURITY');
      case 'Settings':
        return action.contains('SETTING') ||
            action.contains('PREFERENCE') ||
            action.contains('CONFIG') ||
            action.contains('UPDATE');
      case 'Billing':
        return action.contains('PAYMENT') ||
            action.contains('CREDIT') ||
            action.contains('TRANSACTION') ||
            action.contains('BILL') ||
            action.contains('RENEW') ||
            action.contains('PRICING') ||
            action.contains('PLAN');
      case 'Vehicles':
        return action.contains('VEHICLE') ||
            action.contains('DEVICE') ||
            entity.contains('VEHICLE');
      case 'Drivers':
        return action.contains('DRIVER') || entity.contains('DRIVER');
      default:
        return true;
    }
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('d MMM, yyyy · hh:mm a').format(dt);
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

  String _friendlyAction(String raw) {
    final action = raw.trim();
    if (action.isEmpty) return 'Activity';
    final parts = action.split('.');
    if (parts.length >= 2) {
      final entity = parts[parts.length - 2].replaceAll('_', ' ');
      final op = parts.last.replaceAll('_', ' ');
      return '${_titleCase(entity)} · ${_titleCase(op)}';
    }
    return _titleCase(action.replaceAll('.', ' ').replaceAll('_', ' '));
  }

  String _titleCase(String value) {
    final words = value
        .split(' ')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return words
        .map(
          (w) =>
              '${w.substring(0, 1).toUpperCase()}${w.length > 1 ? w.substring(1).toLowerCase() : ''}',
        )
        .join(' ');
  }

  IconData _iconForAction(String action) {
    final a = action.toLowerCase();
    if (a.contains('sensor')) return Icons.flash_on;
    if (a.contains('payment') || a.contains('renew')) {
      return Icons.payments_outlined;
    }
    if (a.contains('vehicle')) return Icons.directions_car_outlined;
    if (a.contains('driver')) return Icons.person_outline;
    if (a.contains('team')) return Icons.group_outlined;
    if (a.contains('user')) return Icons.person_search_outlined;
    if (a.contains('link')) return Icons.link_outlined;
    if (a.contains('unlink')) return Icons.link_off_outlined;
    return Icons.event_note_outlined;
  }

  Widget _infoCell({
    required String label,
    required String value,
    required ColorScheme colorScheme,
    required double labelSize,
  }) {
    final valueSize = labelSize + 1.5;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: labelSize,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: valueSize,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            softWrap: true,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppShimmer(width: double.infinity, height: 320, radius: 12);
    }
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 420).clamp(0.9, 1.0);
    final headerSize = 18 * scale;
    final labelSize = AdaptiveUtils.getSubtitleFontSize(width) - 2;
    final items = _filteredItems();
    final rangeLabel = _dateRange == null
        ? 'Date range'
        : '${DateFormat('d MMM').format(_dateRange!.start)} - ${DateFormat('d MMM').format(_dateRange!.end)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'User Activity',
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
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
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
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.12)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
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
                        PopupMenuItem(value: 'Security', child: Text('Security')),
                        PopupMenuItem(value: 'Settings', child: Text('Settings')),
                        PopupMenuItem(value: 'Billing', child: Text('Billing')),
                        PopupMenuItem(value: 'Vehicles', child: Text('Vehicles')),
                        PopupMenuItem(value: 'Drivers', child: Text('Drivers')),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.tune, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.7)),
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
                        final start = _dateRange?.start;
                        final end = _dateRange?.end;
                        final picked = await showDialog<DateTimeRange>(
                          context: context,
                          builder: (ctx) {
                            var selection = <DateTime>[
                              if (start != null) start,
                              if (end != null) end,
                            ];
                            return Dialog(
                              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: StatefulBuilder(
                                  builder: (context, setDialogState) {
                                    return CalendarDatePicker2(
                                      config: CalendarDatePicker2Config(
                                        calendarType: CalendarDatePicker2Type.range,
                                        currentDate: now,
                                        selectedDayHighlightColor: colorScheme.primary,
                                        firstDate: DateTime(2020, 1, 1),
                                        lastDate: DateTime(2035, 12, 31),
                                      ),
                                      value: selection,
                                      onValueChanged: (values) {
                                        setDialogState(() => selection = values);
                                        if (values.length >= 2) {
                                          Navigator.of(ctx).pop(
                                            DateTimeRange(
                                              start: _startOfDay(values.first),
                                              end: _endOfDay(values.last),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.12)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.date_range, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.7)),
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
                  border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
                ),
                child: items.isEmpty
                    ? Text(
                        'No activity logs found.',
                        style: GoogleFonts.roboto(
                          fontSize: labelSize,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      )
                    : Column(
                        children: items.map((log) {
                          return InkWell(
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => _ActivityLogDetailsScreen(log: log),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).brightness == Brightness.light
                                              ? Colors.grey.shade50
                                              : colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          _iconForAction(log.action),
                                          size: 18,
                                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _friendlyAction(log.action),
                                              style: GoogleFonts.roboto(
                                                fontSize: headerSize,
                                                fontWeight: FontWeight.w700,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              log.action.isNotEmpty ? log.action : '—',
                                              style: GoogleFonts.roboto(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: colorScheme.onSurface.withValues(alpha: 0.65),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).brightness == Brightness.light
                                                    ? Colors.grey.shade50
                                                    : colorScheme.surfaceContainerHighest,
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                log.entity.isNotEmpty ? log.entity : '—',
                                                style: GoogleFonts.roboto(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: colorScheme.onSurface,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _infoCell(
                                          label: 'IP',
                                          value: log.ip.isNotEmpty ? log.ip : '—',
                                          colorScheme: colorScheme,
                                          labelSize: labelSize,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _infoCell(
                                          label: 'Browser',
                                          value: log.browser.isNotEmpty ? log.browser : '—',
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
                                          value: log.platform.isNotEmpty ? log.platform : '—',
                                          colorScheme: colorScheme,
                                          labelSize: labelSize,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _infoCell(
                                          label: _timeAgo(log.createdAt),
                                          value: _formatDateTime(log.createdAt),
                                          colorScheme: colorScheme,
                                          labelSize: labelSize,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
  final String userName;
  final String userUsername;
  final String userLoginType;
  final Map<String, dynamic> metadata;

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
    required this.userName,
    required this.userUsername,
    required this.userLoginType,
    required this.metadata,
  });

  factory _ActivityLog.fromMap(Map<String, dynamic> map) {
    final meta = map['meta'];
    final metaMap = meta is Map ? Map<String, dynamic>.from(meta.cast()) : null;
    final user = map['user'];
    final userMap = user is Map ? Map<String, dynamic>.from(user.cast()) : null;
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
      userName: _asString(userMap?['name']),
      userUsername: _asString(userMap?['username']),
      userLoginType: _asString(userMap?['loginType']),
      metadata: metaMap ?? <String, dynamic>{},
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

class _ActivityLogDetailsScreen extends StatelessWidget {
  final _ActivityLog log;

  const _ActivityLogDetailsScreen({required this.log});

  String _prettyDate(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('EEE, MMM d, yyyy, hh:mm:ss a').format(dt);
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '—';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _safe(String value) {
    final text = value.trim();
    return text.isEmpty ? '—' : text;
  }

  String _friendlyAction(String raw) {
    final action = raw.trim();
    if (action.isEmpty) return 'Activity';
    final parts = action.split('.');
    if (parts.length >= 2) {
      final entity = parts[parts.length - 2].replaceAll('_', ' ');
      final op = parts.last.replaceAll('_', ' ');
      return '${_titleCase(entity)} · ${_titleCase(op)}';
    }
    return _titleCase(action.replaceAll('.', ' ').replaceAll('_', ' '));
  }

  String _titleCase(String value) {
    final words = value
        .split(' ')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return words
        .map(
          (w) =>
              '${w.substring(0, 1).toUpperCase()}${w.length > 1 ? w.substring(1).toLowerCase() : ''}',
        )
        .join(' ');
  }

  String _metadataJson() {
    if (log.metadata.isEmpty) return '{}';
    return const JsonEncoder.withIndent('  ').convert(log.metadata);
  }

  Widget _infoCard(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final labelFs = AdaptiveUtils.getTitleFontSize(width);
    final valueFs = labelFs + 1.5;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: labelFs,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: valueFs,
              height: 1.3,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            softWrap: true,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(width);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF5F5F7),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(hp, AppUtils.appBarHeightCustom + 20, hp, 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? colorScheme.surfaceContainerHighest
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.event_note_outlined,
                            color: colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Activity Log Details',
                                style: GoogleFonts.roboto(
                                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) + 1,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _friendlyAction(log.action),
                                style: GoogleFonts.roboto(
                                  fontSize: AdaptiveUtils.getTitleFontSize(width) + 1,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _infoCard(context, label: 'Entity', value: _safe(log.entity))),
                        const SizedBox(width: 10),
                        Expanded(child: _infoCard(context, label: 'Platform', value: _safe(log.platform))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _infoCard(
                      context,
                      label: 'Action',
                      value: '${_friendlyAction(log.action)}\n${_safe(log.action)}',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _infoCard(context, label: 'IP Address', value: _safe(log.ip))),
                        const SizedBox(width: 10),
                        Expanded(child: _infoCard(context, label: 'Browser', value: _safe(log.browser))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _infoCard(
                      context,
                      label: 'Time',
                      value: '${_prettyDate(log.createdAt)}\n${_timeAgo(log.createdAt)}',
                    ),
                    const SizedBox(height: 10),
                    _infoCard(
                      context,
                      label: 'Performed by',
                      value: '${_safe(log.userName)} @${_safe(log.userUsername)} · ${_safe(log.userLoginType)}',
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Metadata',
                            style: GoogleFonts.roboto(
                              fontSize: AdaptiveUtils.getTitleFontSize(width),
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 220),
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.08)),
                            ),
                            child: SingleChildScrollView(
                              child: SelectableText(
                                _metadataJson(),
                                style: GoogleFonts.roboto(
                                  fontSize: AdaptiveUtils.getTitleFontSize(width) + 0.5,
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface,
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
            ),
          ),
          Positioned(
            left: hp,
            right: hp,
            top: 0,
            child: AdminHomeAppBar(
              title: 'Activity Log Details',
              leadingIcon: Icons.event_note_outlined,
              onClose: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }
}
