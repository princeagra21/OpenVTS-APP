import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_log_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_logs_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/components/appbars/admin_home_appbar.dart';
import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:fleet_stack/modules/admin/screens/logs/log_details_screen.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final CancelToken _token = CancelToken();
  ApiClient? _apiClient;
  AdminLogsRepository? _repo;
  bool _loading = false;
  bool _errorShown = false;
  List<AdminLogItem> _items = const <AdminLogItem>[];

  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _selectedFilter = 'All';
  DateTimeRange? _dateRange;

  AdminLogsRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= AdminLogsRepository(api: _apiClient!);
    return _repo!;
  }

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _token.cancel('LogsScreen disposed');
    _searchController.dispose();
    super.dispose();
  }

  bool _isCancelled(Object err) {
    return err is ApiException &&
        err.message.toLowerCase() == 'request cancelled';
  }

  Future<void> _loadLogs() async {
    if (!mounted) return;
    setState(() => _loading = true);

    final result = await _repoOrCreate().getLogs(
      limit: 100,
      cancelToken: _token,
    );

    if (!mounted) return;

    result.when(
      success: (items) {
        setState(() {
          _items = items;
          _loading = false;
          _errorShown = false;
        });
      },
      failure: (err) {
        setState(() {
          _items = const <AdminLogItem>[];
          _loading = false;
        });
        if (_isCancelled(err)) return;
        if (_errorShown) return;
        _errorShown = true;
        final message = err is ApiException
            ? err.message
            : "Couldn't load activity logs.";
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      },
    );
  }

  DateTime? _parseLogDate(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;

    final numeric = int.tryParse(value);
    if (numeric != null) {
      if (numeric > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(numeric, isUtc: true)
            .toLocal();
      }
      if (numeric > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(numeric * 1000, isUtc: true)
            .toLocal();
      }
    }

    final parsedIso = DateTime.tryParse(value);
    if (parsedIso != null) return parsedIso.toLocal();

    final commaParts = value.split(',');
    if (commaParts.isNotEmpty) {
      final dateParts = commaParts.first.trim().split('/');
      if (dateParts.length == 3) {
        final d = int.tryParse(dateParts[0]);
        final m = int.tryParse(dateParts[1]);
        final y = int.tryParse(dateParts[2]);
        if (d != null && m != null && y != null) {
          return DateTime(y, m, d).toLocal();
        }
      }
    }

    return null;
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

  String _stringFromRaw(AdminLogItem log, List<String> keys) {
    for (final key in keys) {
      final value = log.raw[key];
      if (value == null) continue;
      final out = value.toString().trim();
      if (out.isNotEmpty && out.toLowerCase() != 'null') return out;
    }
    return '';
  }

  String _actionFor(AdminLogItem log) {
    final action = _stringFromRaw(log, ['action']);
    if (action.isNotEmpty) return action;
    if (log.message.isNotEmpty) return log.message;
    if (log.type.isNotEmpty) return log.type;
    return 'Activity';
  }

  String _entityFor(AdminLogItem log) {
    final entity = _stringFromRaw(log, ['entity', 'entityName']);
    if (entity.isNotEmpty) return entity;
    if (log.entity.isNotEmpty) return log.entity;
    return '—';
  }

  int? _entityId(AdminLogItem log) {
    final raw = log.raw['entityId'] ?? log.raw['id'] ?? log.raw['uid'];
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  String _pathFor(AdminLogItem log) {
    final meta = log.raw['meta'];
    if (meta is Map) {
      final map = Map<String, dynamic>.from(meta.cast());
      final value = map['path'];
      if (value != null) return value.toString();
    }
    return _stringFromRaw(log, ['path']);
  }

  String _methodFor(AdminLogItem log) {
    final meta = log.raw['meta'];
    if (meta is Map) {
      final map = Map<String, dynamic>.from(meta.cast());
      final value = map['method'];
      if (value != null) return value.toString();
    }
    return _stringFromRaw(log, ['method']);
  }

  int? _durationMs(AdminLogItem log) {
    final meta = log.raw['meta'];
    if (meta is Map) {
      final map = Map<String, dynamic>.from(meta.cast());
      final value = map['durationMs'];
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
    }
    return null;
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

  List<AdminLogItem> _filteredItems() {
    final q = _query.trim().toLowerCase();
    final now = DateTime.now();
    final range = _dateRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
      999,
    );

    return _items.where((log) {
      final createdAt = _parseLogDate(log.time);
      if (createdAt != null) {
        if (createdAt.isBefore(start) || createdAt.isAfter(end)) {
          return false;
        }
      }
      if (_selectedFilter != 'All') {
        final hay = '${_actionFor(log)} ${_entityFor(log)} ${log.type}'
            .toUpperCase();
        if (!hay.contains(_selectedFilter)) return false;
      }
      if (q.isEmpty) return true;
      final hay = <String>[
        _actionFor(log),
        _entityFor(log),
        _entityId(log)?.toString() ?? '',
        _stringFromRaw(log, ['ip', 'ipAddress']),
        _stringFromRaw(log, ['browser', 'userAgent']),
        _stringFromRaw(log, ['platform', 'os', 'device']),
        _pathFor(log),
        _methodFor(log),
        _durationMs(log)?.toString() ?? '',
        log.message,
        log.type,
        log.channel,
      ].join(' ').toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  Future<void> _pickDateRange() async {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    var selection = <DateTime?>[_dateRange?.start, _dateRange?.end];

    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                final hasFullRange =
                    selection.length >= 2 &&
                    selection[0] != null &&
                    selection[1] != null;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Date Range',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CalendarDatePicker2(
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
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() => _dateRange = null);
                            Navigator.pop(ctx);
                          },
                          child: const Text('Reset'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: hasFullRange
                              ? () {
                                  final start = selection[0]!;
                                  final end = selection[1]!;
                                  Navigator.pop(
                                    ctx,
                                    DateTimeRange(start: start, end: end),
                                  );
                                }
                              : null,
                          child: const Text('Show Logs'),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    if (!mounted || picked == null) return;
    setState(() => _dateRange = picked);
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
            softWrap: true,
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

    return AppLayout(
      title: 'ADMIN',
      subtitle: 'Logs & Activity',
      showAppBar: false,
      customTopBar: AdminHomeAppBar(
        title: 'Logs & Activity',
        leadingIcon: Icons.list_alt,
        onClose: () => context.go('/admin/home'),
      ),
      actionIcons: const [Icons.settings],
      showLeftAvatar: false,
      leftAvatarText: 'SA',
      child: _loading
          ? const AppShimmer(
              width: double.infinity,
              height: 320,
              radius: 12,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                                    color:
                                        colorScheme.onSurface.withOpacity(0.12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.tune,
                                      size: 16,
                                      color:
                                          colorScheme.onSurface.withOpacity(0.7),
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
                              onTap: _pickDateRange,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color:
                                        colorScheme.onSurface.withOpacity(0.12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 16,
                                      color:
                                          colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        rangeLabel,
                                        style: GoogleFonts.roboto(
                                          fontSize: labelSize,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface,
                                        ),
                                        softWrap: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      items.isEmpty
                          ? Text(
                              'No activity found',
                              style: GoogleFonts.roboto(
                                fontSize: labelSize,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            )
                          : Column(
                              children: items.map((log) {
                                final action = _actionFor(log);
                                final entity = _entityFor(log);
                                final createdAt = _parseLogDate(log.time);
                                final ip =
                                    _stringFromRaw(log, ['ip', 'ipAddress']);
                                final browser = _stringFromRaw(
                                  log,
                                  ['browser', 'userAgent'],
                                );
                                final platform = _stringFromRaw(
                                  log,
                                  ['platform', 'os', 'device'],
                                );
                                return InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            AdminLogDetailsScreen(log: log),
                                      ),
                                    );
                                  },
                                  child: Container(
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.light
                                                  ? Colors.grey.shade50
                                                  : colorScheme.surfaceVariant,
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            alignment: Alignment.center,
                                            child: Icon(
                                              _iconForAction(action),
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
                                                  action.isNotEmpty
                                                      ? action
                                                      : 'Activity',
                                                  softWrap: true,
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
                                                    entity.isNotEmpty
                                                        ? entity
                                                        : '—',
                                                    style: GoogleFonts.roboto(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: colorScheme
                                                          .onSurface,
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
                                      IntrinsicHeight(
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Expanded(
                                              child: _infoCell(
                                                label: 'IP',
                                                value:
                                                    ip.isNotEmpty ? ip : '—',
                                                colorScheme: colorScheme,
                                                labelSize: labelSize,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: _infoCell(
                                                label: 'Browser',
                                                value: browser.isNotEmpty
                                                    ? browser
                                                    : '—',
                                                colorScheme: colorScheme,
                                                labelSize: labelSize,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      IntrinsicHeight(
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Expanded(
                                              child: _infoCell(
                                                label: 'OS',
                                                value: platform.isNotEmpty
                                                    ? platform
                                                    : '—',
                                                colorScheme: colorScheme,
                                                labelSize: labelSize,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: _infoCell(
                                                label: _timeAgo(createdAt),
                                                value: _formatDateTime(createdAt),
                                                colorScheme: colorScheme,
                                                labelSize: labelSize,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
