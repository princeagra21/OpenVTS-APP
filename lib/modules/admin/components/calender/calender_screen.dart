// 🔥 FULLY UPDATED WITH APPTHEME COLOR SCHEME
// EventCalendarScreen (Drop-in Replacement)

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_calendar_event_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_calendar_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/components/appbars/admin_home_appbar.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/admin/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:intl/intl.dart';

class EventCalendarScreen extends StatefulWidget {
  const EventCalendarScreen({super.key});

  @override
  State<EventCalendarScreen> createState() => _EventCalendarScreenState();
}

class _EventCalendarScreenState extends State<EventCalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _weekAnchor = DateTime.now();
  final Set<String> _selectedTypes = <String>{'user'};
  AdminCalendarEventItem? _selectedEvent;
  final TextEditingController _eventSearchController = TextEditingController();
  List<AdminCalendarEventItem> _events = const [];
  final Map<String, List<AdminCalendarEventItem>> _monthCache = {};
  final Map<String, List<AdminCalendarEventItem>> _dayCache = {};
  bool _loadingMonth = false;
  bool _loadingDay = false;
  bool _loading = false;
  bool _errorShown = false;
  CancelToken? _token;
  ApiClient? _api;
  AdminCalendarRepository? _repo;
  DateTime? _loadedMonth;
  DateTime? _loadedDay;
  List<AdminCalendarEventItem> _dayItems = const [];
  final ScrollController _weekScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _weekAnchor = DateTime.now();
    _eventSearchController.addListener(() => setState(() {}));
    _loadMonth(_selectedDate);
  }

  @override
  void dispose() {
    _token?.cancel('Calendar disposed');
    _eventSearchController.dispose();
    _weekScrollController.dispose();
    super.dispose();
  }

  DateTime _dayKey(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _monthStart(DateTime d) => DateTime(d.year, d.month, 1);

  DateTime _monthEnd(DateTime d) => DateTime(d.year, d.month + 1, 0);

  String _monthKey(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}";

  String _fmtDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  String _monthTitle(DateTime d) {
    const monthNames = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${monthNames[d.month - 1]} ${d.year}';
  }

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    final day = date.day;
    String suffix = 'th';
    if (day % 10 == 1 && day % 100 != 11) suffix = 'st';
    if (day % 10 == 2 && day % 100 != 12) suffix = 'nd';
    if (day % 10 == 3 && day % 100 != 13) suffix = 'rd';
    return '$day$suffix';
  }

  Future<void> _pickMonth() async {
    final initial = _loadedMonth ?? _selectedDate;
    final picked = await showDialog<DateTime?>(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CalendarDatePicker2(
              config: CalendarDatePicker2Config(
                calendarType: CalendarDatePicker2Type.single,
                selectedDayHighlightColor: Theme.of(ctx).colorScheme.primary,
                firstDate: DateTime(2020, 1, 1),
                lastDate: DateTime(2035, 12, 31),
              ),
              value: [initial],
              onValueChanged: (values) {
                if (values.isNotEmpty && values.first != null) {
                  Navigator.of(ctx).pop(values.first);
                }
              },
            ),
          ),
        );
      },
    );

    if (picked == null) return;
    final month = _monthStart(picked);
    setState(() => _selectedDate = month);
    _loadMonth(month, force: true);
  }

  String _normType(String raw) {
    final s = raw.toLowerCase().replaceAll(' ', '').replaceAll('_', '');
    if (s.contains('admin')) return 'admin';
    if (s.contains('user')) return 'user';
    if (s.contains('vehicle') && s.contains('exp')) return 'vehicle_expiry';
    if (s.contains('vehicle') && s.contains('add')) return 'vehicle_added';
    if (s == 'vehicleexpiry') return 'vehicle_expiry';
    if (s == 'vehicleadded') return 'vehicle_added';
    if (s == 'vehicle') return 'vehicle';
    return s;
  }

  bool _matchesType(AdminCalendarEventItem e) {
    if (_selectedTypes.isEmpty) return true;
    final t = _normType(e.type);
    if (_selectedTypes.contains('vehicle')) {
      if (t == 'vehicle' || t == 'vehicle_expiry' || t == 'vehicle_added') {
        return true;
      }
    }
    if (_selectedTypes.contains('vehicle_expiry') && t == 'vehicle_expiry') {
      return true;
    }
    if (_selectedTypes.contains('user') && t == 'user') {
      return true;
    }
    return false;
  }

  Map<DateTime, List<AdminCalendarEventItem>> get _eventsByDate {
    final out = <DateTime, List<AdminCalendarEventItem>>{};
    for (final e in _events.where(_matchesType)) {
      final d = e.date;
      if (d == null) continue;
      final key = _dayKey(d);
      out.putIfAbsent(key, () => <AdminCalendarEventItem>[]).add(e);
    }
    return out;
  }

  Map<String, dynamic> _map(Object? v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v.cast());
    return const <String, dynamic>{};
  }

  List _list(Object? v) => v is List ? v : const [];

  String _firstNonEmpty(List<Object?> values, {String fallback = ''}) {
    for (final v in values) {
      final t = (v ?? '').toString().trim();
      if (t.isNotEmpty) return t;
    }
    return fallback;
  }

  String _eventDisplayTitle(AdminCalendarEventItem e) {
    final t = e.title.trim();
    if (t.isNotEmpty) return t;
    final d = e.description.trim();
    if (d.isNotEmpty) return d;
    final byType = _normType(e.type).contains('user') ? 'User' : 'Event';
    return byType;
  }

  List<AdminCalendarEventItem> _buildDayItems(Map<String, dynamic> root) {
    final dataMap = _map(_map(root)['data']);
    final inner = _map(dataMap['data']);
    final dateStr = inner['date']?.toString() ?? _fmtDate(_selectedDate);
    final out = <AdminCalendarEventItem>[];

    for (final it in _list(inner['usersCreated'])) {
      final m = _map(it);
      out.add(
        AdminCalendarEventItem(<String, dynamic>{
          'type': 'USER_CREATED',
          'id': m['uid'] ?? m['id'],
          'title': _firstNonEmpty([
            m['name'],
            m['userName'],
            m['username'],
            m['fullName'],
            m['email'],
          ]),
          'description': _firstNonEmpty([m['email'], m['name']]),
          'createdAt': m['createdAt'],
          'date': dateStr,
        }),
      );
    }

    for (final it in _list(inner['vehiclesCreated'])) {
      final m = _map(it);
      out.add(
        AdminCalendarEventItem(<String, dynamic>{
          'type': 'VEHICLE_CREATED',
          'id': m['id'],
          'title': _firstNonEmpty([m['name'], m['plateNumber']]),
          'description': _firstNonEmpty([m['plateNumber'], m['name']]),
          'createdAt': m['createdAt'],
          'date': dateStr,
        }),
      );
    }

    for (final it in _list(inner['vehiclesExpiry'])) {
      final m = _map(it);
      out.add(
        AdminCalendarEventItem(<String, dynamic>{
          'type': 'VEHICLE_EXPIRY',
          'id': m['id'],
          'title': _firstNonEmpty([m['name'], m['plateNumber']]),
          'description': _firstNonEmpty([m['plateNumber'], m['name']]),
          'createdAt': m['createdAt'],
          'date': dateStr,
        }),
      );
    }

    return out;
  }

  Future<void> _loadDay(DateTime date) async {
    final key = _fmtDate(date);
    if (_dayCache.containsKey(key)) {
      setState(() {
        _dayItems = _dayCache[key] ?? const [];
        _loadedDay = date;
        _loadingDay = false;
      });
      return;
    }

    setState(() => _loadingDay = true);
    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= AdminCalendarRepository(api: _api!);
      final res = await _repo!.getCalendarDayDetails(date: key);
      if (!mounted) return;
      res.when(
        success: (data) {
          final items = _buildDayItems(data);
          setState(() {
            _dayCache[key] = items;
            _dayItems = items;
            _loadedDay = date;
            _loadingDay = false;
          });
        },
        failure: (_) {
          if (!mounted) return;
          setState(() {
            _dayItems = const [];
            _loadedDay = date;
            _loadingDay = false;
          });
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _dayItems = const [];
        _loadedDay = date;
        _loadingDay = false;
      });
    }
  }

  void _loadDayIfNeeded(DateTime date) {
    // Day details endpoint can return richer data (e.g. user names)
    // even when month snapshot map misses/normalizes the day entries.
    _loadDay(date);
  }

  String _eventLabel(AdminCalendarEventItem e) {
    final t = _normType(e.type);
    if (t.contains('user')) return 'Users Created';
    if (t.contains('admin')) return 'Admins Created';
    if (t.contains('vehicle') && t.contains('expiry')) return 'Vehicle Expiry';
    if (t.contains('vehicle')) return 'Vehicles';
    return 'Events';
  }

  String _eventEntity(AdminCalendarEventItem e) {
    final t = _normType(e.type);
    if (t.contains('user')) return 'User';
    if (t.contains('admin')) return 'Admin';
    if (t.contains('vehicle')) return 'Vehicle';
    return 'Event';
  }

  String _eventId(AdminCalendarEventItem e) {
    final t = _normType(e.type);
    if (t.contains('user') && e.userId.isNotEmpty) return e.userId;
    if (t.contains('admin') && e.adminId.isNotEmpty) return e.adminId;
    if (t.contains('vehicle') && e.vehicleId.isNotEmpty) return e.vehicleId;
    return e.id;
  }

  String _eventTime(AdminCalendarEventItem e) {
    if (e.time.trim().isNotEmpty) return e.time;
    final dt = e.createdAt ?? e.date;
    if (dt == null) return '-';
    return DateFormat('hh:mm a').format(dt);
  }

  String _eventSubtitle(AdminCalendarEventItem e) {
    final t = _normType(e.type);
    if (t.contains('user')) return 'User Registration';
    if (t.contains('admin')) return 'Admin Registration';
    if (t.contains('vehicle') && t.contains('expiry')) return 'Vehicle Expiry';
    if (t.contains('vehicle')) return 'Vehicle Registration';
    return 'Event';
  }

  Widget _headerTab(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 420).clamp(0.9, 1.0);
    final double fsChip = 14 * scale;
    final double iconSize = 14 * scale;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? cs.onSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: cs.onSurface.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: selected ? cs.surface : cs.onSurface,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: fsChip,
                height: 20 / 14,
                fontWeight: FontWeight.w600,
                color: selected ? cs.surface : cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadMonth(DateTime anyDateInMonth, {bool force = false}) async {
    final month = _monthStart(anyDateInMonth);
    _loadedMonth = month;
    final key = _monthKey(month);

    if (!force && _monthCache.containsKey(key)) {
      if (!mounted) return;
      setState(() {
        _events = _monthCache[key] ?? const [];
        _loading = false;
      });
      return;
    }

    if (_loadingMonth) return;
    _loadingMonth = true;
    _token?.cancel('Reload calendar month');
    final token = CancelToken();
    _token = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= AdminCalendarRepository(api: _api!);
      final res = await _repo!.getCalendarEvents(
        from: _fmtDate(_monthStart(anyDateInMonth)),
        to: _fmtDate(_monthEnd(anyDateInMonth)),
        cancelToken: token,
      );
      if (!mounted) return;
      res.when(
        success: (rows) {
          setState(() {
            _monthCache[key] = rows;
            _events = rows;
            _loading = false;
            _errorShown = false;
          });
          _loadDayIfNeeded(_selectedDate);
        },
        failure: (err) {
          setState(() => _loading = false);
          if (_errorShown) return;
          _errorShown = true;
          final msg =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to view calendar events.'
              : "Couldn't load calendar events.";
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
        const SnackBar(content: Text("Couldn't load calendar events.")),
      );
    } finally {
      _loadingMonth = false;
    }
  }

  Map<DateTime, List<Map<String, dynamic>>> get _effectiveEventMap {
    final byDate = _eventsByDate;
    if (byDate.isEmpty) return const {};
    final out = <DateTime, List<Map<String, dynamic>>>{};
    byDate.forEach((k, v) {
      out[k] = v
          .map(
            (e) => <String, dynamic>{
              'title': e.title.isNotEmpty ? e.title : 'Event',
              'type': _normType(e.type),
              'time': e.time.isNotEmpty
                  ? e.time
                  : (e.date != null
                        ? '${e.date!.hour.toString().padLeft(2, '0')}:${e.date!.minute.toString().padLeft(2, '0')}'
                        : ''),
              '__event': e,
            },
          )
          .toList();
    });
    return out;
  }

  AdminCalendarEventItem _eventFromMap(
    Map<String, dynamic> event,
    DateTime selectedDate,
  ) {
    final existing = event['__event'];
    if (existing is AdminCalendarEventItem) return existing;
    return AdminCalendarEventItem(<String, dynamic>{
      'title': event['title'],
      'type': event['type'],
      'time': event['time'],
      'date': _fmtDate(selectedDate),
    });
  }

  String _eventDetailText(AdminCalendarEventItem? e) {
    if (e == null) return "Select an event to view details.";
    final description = e.description.trim();
    if (description.isNotEmpty) return description;
    final time = e.time.trim();
    if (time.isNotEmpty) return "Time: $time";
    final dt = e.createdAt ?? e.date;
    if (dt != null) {
      return "Date: ${dt.day}/${dt.month}/${dt.year}";
    }
    return "No additional details.";
  }

  void _openSelectedEventTarget() {
    final e = _selectedEvent;
    if (e == null) return;

    final vehicleId = e.vehicleId.trim();
    final adminId = e.adminId.trim();
    String? route;
    if (vehicleId.isNotEmpty) {
      route = '/superadmin/vehicles/details/$vehicleId';
    } else if (adminId.isNotEmpty) {
      route = '/superadmin/admins/details/$adminId';
    }
    if (route == null) return;

    try {
      context.push(route);
    } catch (err) {
      if (kDebugMode) {
        debugPrint('Calendar open route failed: $err');
      }
    }
  }

  List<AdminCalendarEventItem> _eventsForDate(DateTime date) {
    final key = _dayKey(date);
    final useDayItems =
        _loadedDay != null && _dayKey(_loadedDay!) == key && _dayItems.isNotEmpty;
    if (useDayItems) return List<AdminCalendarEventItem>.from(_dayItems);
    final raw = _effectiveEventMap[key] ?? const <Map<String, dynamic>>[];
    return raw.map((e) => _eventFromMap(e, date)).toList(growable: false);
  }

  Future<void> _openEventsBottomSheet(DateTime date) async {
    final items = _eventsForDate(date);
    if (items.isEmpty) return;
    final cs = Theme.of(context).colorScheme;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.82,
          ),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Event',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final e = items[index];
                    final subtitle = _eventSubtitle(e);
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.onSurface.withOpacity(0.1)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              _normType(e.type).contains('expiry')
                                  ? Icons.event_busy_outlined
                                  : _normType(e.type).contains('vehicle')
                                  ? Icons.directions_car_outlined
                                  : _normType(e.type).contains('admin')
                                  ? Icons.admin_panel_settings_outlined
                                  : Icons.person_outline,
                              size: 18,
                              color: cs.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _eventDisplayTitle(e),
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: cs.onSurface.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _eventTime(e),
                                  style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: cs.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemCount: items.length,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;
    final bool isMobile = width < 650;
    final double topPadding = MediaQuery.of(context).padding.top;
    final eventMap = _effectiveEventMap;
    final currentMonth = _loadedMonth ?? _selectedDate;
    final showSkeleton = _loading && _events.isEmpty;
    final scale = (width / 420).clamp(0.9, 1.0);
    final double fsHeader = 16 * scale;
    final double fsMonth = 18 * scale;
    final double fsButton = 14 * scale;
    final double fsChip = 14 * scale;
    final double fsWeekday = 11 * scale;
    final double fsDate = 14 * scale;
    final double fsDateSelected = 14 * scale;
    final double fsSearch = 14 * scale;
    final double fsLabel = 12 * scale;
    final double fsEventTitle = 14 * scale;
    final double fsEventSecondary = 12 * scale;
    final double fsEventMeta = 11 * scale;

    Widget navButton(IconData icon, VoidCallback onTap) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.onSurface.withOpacity(0.2)),
          ),
          child: Icon(icon, size: fsButton, color: cs.onSurface),
        ),
      );
    }

    void shiftDay(int delta) {
      final next = _weekAnchor.add(Duration(days: delta));
      setState(() {
        _weekAnchor = next;
        _selectedDate = next;
        _selectedEvent = null;
      });
      if (_loadedMonth == null || _monthStart(_loadedMonth!) != _monthStart(next)) {
        _loadMonth(next);
      }
      _loadDayIfNeeded(next);
    }

    void jumpToToday() {
      final now = DateTime.now();
      setState(() {
        _weekAnchor = now;
        _selectedDate = now;
        _selectedEvent = null;
      });
      _loadMonth(now, force: true);
      _loadDayIfNeeded(now);
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                hp,
                topPadding + AppUtils.appBarHeightCustom + 28,
                hp,
                hp,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(hp),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cs.onSurface.withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _pickMonth,
                                child: Text(
                                  _monthTitle(currentMonth),
                                  style: GoogleFonts.roboto(
                                    fontSize: fsMonth,
                                    height: 24 / 18,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ),
                            ),
                            navButton(Icons.chevron_left, () => shiftDay(-1)),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: jumpToToday,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: cs.onSurface.withOpacity(0.2),
                                  ),
                                ),
                                child: Text(
                                  _dayLabel(_selectedDate),
                                  style: GoogleFonts.roboto(
                                    fontSize: fsButton,
                                    height: 20 / 14,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            navButton(Icons.chevron_right, () => shiftDay(1)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _headerTab(
                                context,
                                label: 'User',
                                icon: Symbols.person,
                                selected: _selectedTypes.contains('user'),
                                onTap: () {
                                  setState(() {
                                    if (_selectedTypes.contains('user')) {
                                      _selectedTypes.remove('user');
                                    } else {
                                      _selectedTypes.add('user');
                                    }
                                    if (_selectedTypes.isEmpty) {
                                      _selectedTypes.add('user');
                                    }
                                  });
                                  _loadDayIfNeeded(_selectedDate);
                                },
                              ),
                              const SizedBox(width: 8),
                              _headerTab(
                                context,
                                label: 'Vehicle',
                                icon: Symbols.directions_car,
                                selected: _selectedTypes.contains('vehicle'),
                                onTap: () {
                                  setState(() {
                                    if (_selectedTypes.contains('vehicle')) {
                                      _selectedTypes.remove('vehicle');
                                    } else {
                                      _selectedTypes.add('vehicle');
                                    }
                                    if (_selectedTypes.isEmpty) {
                                      _selectedTypes.add('vehicle');
                                    }
                                  });
                                  _loadDayIfNeeded(_selectedDate);
                                },
                              ),
                              const SizedBox(width: 8),
                              _headerTab(
                                context,
                                label: 'Expiry',
                                icon: Symbols.event,
                                selected:
                                    _selectedTypes.contains('vehicle_expiry'),
                                onTap: () {
                                  setState(() {
                                    if (_selectedTypes
                                        .contains('vehicle_expiry')) {
                                      _selectedTypes.remove('vehicle_expiry');
                                    } else {
                                      _selectedTypes.add('vehicle_expiry');
                                    }
                                    if (_selectedTypes.isEmpty) {
                                      _selectedTypes.add('vehicle_expiry');
                                    }
                                  });
                                  _loadDayIfNeeded(_selectedDate);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(hp),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cs.onSurface.withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Month Snapshot',
                          style: GoogleFonts.roboto(
                            fontSize: fsMonth,
                            height: 24 / 18,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (showSkeleton)
                          AppShimmer(
                            width: double.infinity,
                            height: isMobile ? 300 : 340,
                            radius: 16,
                          )
                        else
                          CalendarDatePicker2(
                            key: ValueKey(_monthKey(currentMonth)),
                            displayedMonthDate: currentMonth,
                            onDisplayedMonthChanged: (displayedMonth) {
                              final monthStart = _monthStart(displayedMonth);
                              if (_loadedMonth == null ||
                                  _monthStart(_loadedMonth!) != monthStart) {
                                _loadMonth(displayedMonth);
                              }
                            },
                            config: CalendarDatePicker2Config(
                              calendarType: CalendarDatePicker2Type.single,
                              currentDate: _selectedDate,
                              selectedDayHighlightColor: cs.primary,
                              weekdayLabelTextStyle: GoogleFonts.roboto(
                                fontSize: fsWeekday,
                                height: 14 / 11,
                                fontWeight: FontWeight.w500,
                                color: cs.onSurface,
                              ),
                              dayTextStyle: GoogleFonts.roboto(
                                fontSize: fsDate,
                                height: 20 / 14,
                                fontWeight: FontWeight.w500,
                                color: cs.onSurface,
                              ),
                              selectedDayTextStyle: GoogleFonts.roboto(
                                color: cs.onPrimary,
                                fontSize: fsDateSelected,
                                height: 20 / 14,
                                fontWeight: FontWeight.w600,
                              ),
                              todayTextStyle: GoogleFonts.roboto(
                                color: cs.primary,
                                fontSize: fsDate,
                                height: 20 / 14,
                                fontWeight: FontWeight.w600,
                              ),
                              controlsTextStyle: GoogleFonts.roboto(
                                fontSize: fsButton,
                                height: 20 / 14,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                              dayBuilder: ({
                                required DateTime date,
                                bool? isSelected,
                                bool? isToday,
                                TextStyle? textStyle,
                                BoxDecoration? decoration,
                                bool? isDisabled,
                              }) {
                                final hasEvent = eventMap.containsKey(_dayKey(date));
                                return Center(
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isSelected == true
                                          ? cs.primary
                                          : isToday == true
                                              ? cs.primary.withOpacity(0.08)
                                              : null,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Text(
                                          '${date.day}',
                                          style: GoogleFonts.roboto(
                                            fontSize: fsDate,
                                            height: 20 / 14,
                                            fontWeight: isSelected == true
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            color: isSelected == true ? cs.onPrimary : cs.onSurface,
                                          ),
                                        ),
                                        if (hasEvent)
                                          Positioned(
                                            bottom: 3,
                                            child: Container(
                                              width: 7,
                                              height: 7,
                                              decoration: BoxDecoration(
                                                color: isSelected == true
                                                    ? cs.onPrimary
                                                    : cs.primary,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: cs.surface,
                                                  width: 1,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            value: [_selectedDate],
                            onValueChanged: (dates) {
                              if (dates.isNotEmpty) {
                                final nextDate = dates.first;
                                final nextMonth = _monthStart(nextDate);
                                final shouldOpenEventsSheet =
                                    (eventMap[_dayKey(nextDate)] ?? const []).isNotEmpty;
                                setState(() {
                                  _selectedDate = nextDate;
                                  _selectedEvent = null;
                                  _weekAnchor = nextDate;
                                });
                                if (_loadedMonth == null ||
                                    _monthStart(_loadedMonth!) != nextMonth) {
                                  _loadMonth(nextDate);
                                }
                                _loadDayIfNeeded(nextDate);
                                if (shouldOpenEventsSheet) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (!mounted) return;
                                    _openEventsBottomSheet(nextDate);
                                  });
                                }
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: hp,
            right: hp,
            top: 0,
            child: AdminHomeAppBar(
              title: 'Calendar',
              leadingIcon: Symbols.date_range,
            ),
          ),
        ],
      ),
    );
  }

  // EVENT LIST REUSABLE BUILDER
  List<Widget> _buildEventList(
    BuildContext context,
    ColorScheme cs,
    double width,
    Map<DateTime, List<Map<String, dynamic>>> eventMap,
    bool loading,
  ) {
    if (loading) {
      return List<Widget>.generate(
        3,
        (index) => Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.onSurface.withOpacity(0.05)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppShimmer(width: 160, height: 16, radius: 8),
              SizedBox(height: 8),
              AppShimmer(width: 90, height: 12, radius: 8),
            ],
          ),
        ),
      );
    }

    final events = eventMap[_dayKey(_selectedDate)] ?? [];

    if (events.isEmpty) {
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.onSurface.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              "No events for this date.",
              style: GoogleFonts.roboto(
                fontSize: 12 * (width / 420).clamp(0.9, 1.0),
                height: 16 / 12,
                fontWeight: FontWeight.w500,
                color: cs.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ];
    }

    return events.map((event) {
      final selected = _selectedEvent?.id.isNotEmpty == true
          ? (_selectedEvent!.id == _eventFromMap(event, _selectedDate).id)
          : false;
      return GestureDetector(
        onTap: () => setState(
          () => _selectedEvent = _eventFromMap(event, _selectedDate),
        ),
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? cs.primary.withOpacity(0.35)
                  : cs.onSurface.withOpacity(0.05),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['title'],
                      style: GoogleFonts.roboto(
                        fontSize: 14 * (width / 420).clamp(0.9, 1.0),
                        height: 20 / 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "at ${event['time']}",
                      style: GoogleFonts.roboto(
                        fontSize: 12 * (width / 420).clamp(0.9, 1.0),
                        height: 16 / 12,
                        color: cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  // LEGEND UI
  Widget _legendItem(
    String label,
    ColorScheme cs, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 11 * (MediaQuery.of(context).size.width / 420).clamp(0.9, 1.0),
              height: 14 / 11,
              color: selected ? cs.primary : cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
