// 🔥 FULLY UPDATED WITH APPTHEME COLOR SCHEME
// EventCalendarScreen (Drop-in Replacement)

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/calendar_event_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/superadmin/layout/app_layout.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class EventCalendarScreen extends StatefulWidget {
  const EventCalendarScreen({super.key});

  @override
  State<EventCalendarScreen> createState() => _EventCalendarScreenState();
}

class _EventCalendarScreenState extends State<EventCalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedType;
  CalendarEventItem? _selectedEvent;
  List<CalendarEventItem> _events = const [];
  final Map<String, List<CalendarEventItem>> _monthCache = {};
  bool _loadingMonth = false;
  bool _loading = false;
  bool _errorShown = false;
  CancelToken? _token;
  ApiClient? _api;
  SuperadminRepository? _repo;
  DateTime? _loadedMonth;

  final Map<DateTime, List<Map<String, dynamic>>> _fallbackEvents = {
    DateTime(2025, 12, 8): [
      {'title': 'Admin Created', 'type': 'admin', 'time': '09:15'},
      {'title': 'User Created', 'type': 'user', 'time': '14:30'},
    ],
    DateTime(2025, 12, 12): [
      {'title': 'Vehicle Expiry', 'type': 'vehicle', 'time': '00:00'},
      {'title': 'Vehicle Added', 'type': 'vehicle', 'time': '11:45'},
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadMonth(_selectedDate);
  }

  @override
  void dispose() {
    _token?.cancel('Calendar disposed');
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

  bool _matchesType(CalendarEventItem e) {
    if (_selectedType == null || _selectedType!.isEmpty) return true;
    final want = _selectedType!;
    final t = _normType(e.type);
    if (want == 'vehicle') {
      return t == 'vehicle' || t == 'vehicle_expiry' || t == 'vehicle_added';
    }
    return t == want;
  }

  Map<DateTime, List<CalendarEventItem>> get _eventsByDate {
    final out = <DateTime, List<CalendarEventItem>>{};
    for (final e in _events.where(_matchesType)) {
      final d = e.date;
      if (d == null) continue;
      final key = _dayKey(d);
      out.putIfAbsent(key, () => <CalendarEventItem>[]).add(e);
    }
    return out;
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
      _repo ??= SuperadminRepository(api: _api!);
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
        },
        failure: (err) {
          setState(() => _loading = false);
          if (_errorShown) return;
          _errorShown = true;
          final msg =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to view calendar events.'
              : "Couldn't load calendar events. Showing fallback values.";
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
        const SnackBar(
          content: Text(
            "Couldn't load calendar events. Showing fallback values.",
          ),
        ),
      );
    } finally {
      _loadingMonth = false;
    }
  }

  Map<DateTime, List<Map<String, dynamic>>> get _effectiveEventMap {
    final byDate = _eventsByDate;
    if (byDate.isEmpty) return _fallbackEvents;
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

  CalendarEventItem _eventFromMap(
    Map<String, dynamic> event,
    DateTime selectedDate,
  ) {
    final existing = event['__event'];
    if (existing is CalendarEventItem) return existing;
    return CalendarEventItem(<String, dynamic>{
      'title': event['title'],
      'type': event['type'],
      'time': event['time'],
      'date': _fmtDate(selectedDate),
    });
  }

  String _eventDetailText(CalendarEventItem? e) {
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme; // Short alias
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;
    final bool isMobile = width < 650;
    final eventMap = _effectiveEventMap;

    return AppLayout(
      title: "FLEET STACK",
      subtitle: "White Label",
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 3,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // OUTER CARD
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
                  // HEADER
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "December 2025",
                              style: GoogleFonts.inter(
                                fontSize:
                                    AdaptiveUtils.getTitleFontSize(width) + 4,
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () =>
                                      _loadMonth(_selectedDate, force: true),
                                  behavior: HitTestBehavior.opaque,
                                  child: Text(
                                    "Today",
                                    style: GoogleFonts.inter(
                                      fontSize:
                                          AdaptiveUtils.getSubtitleFontSize(
                                            width,
                                          ) -
                                          3,
                                      fontWeight: FontWeight.w500,
                                      color: cs.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                                if (_loading) ...[
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        cs.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      if (!isMobile)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: cs.onSurface.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Monochrome Calendar\nAdmin/User/Vehicle Events",
                            style: GoogleFonts.inter(
                              fontSize:
                                  AdaptiveUtils.getSubtitleFontSize(width) - 6,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // LEGEND
                  Wrap(
                    spacing: 20,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      _legendItem(
                        "Admin Created",
                        cs,
                        selected: _selectedType == 'admin',
                        onTap: () => setState(
                          () => _selectedType = _selectedType == 'admin'
                              ? null
                              : 'admin',
                        ),
                      ),
                      _legendItem(
                        "User Created",
                        cs,
                        selected: _selectedType == 'user',
                        onTap: () => setState(
                          () => _selectedType = _selectedType == 'user'
                              ? null
                              : 'user',
                        ),
                      ),
                      _legendItem(
                        "Vehicle Expiry",
                        cs,
                        selected:
                            _selectedType == 'vehicle_expiry' ||
                            _selectedType == 'vehicle',
                        onTap: () => setState(
                          () =>
                              _selectedType = _selectedType == 'vehicle_expiry'
                              ? null
                              : 'vehicle_expiry',
                        ),
                      ),
                      _legendItem(
                        "Vehicle Added",
                        cs,
                        selected:
                            _selectedType == 'vehicle_added' ||
                            _selectedType == 'vehicle',
                        onTap: () => setState(
                          () => _selectedType = _selectedType == 'vehicle_added'
                              ? null
                              : 'vehicle_added',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // CALENDAR
                  CalendarDatePicker2(
                    config: CalendarDatePicker2Config(
                      calendarType: CalendarDatePicker2Type.single,
                      selectedDayHighlightColor: cs.primary,

                      // Weekdays
                      weekdayLabelTextStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),

                      // Normal day
                      dayTextStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),

                      // Selected day
                      selectedDayTextStyle: GoogleFonts.inter(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),

                      // Today
                      todayTextStyle: GoogleFonts.inter(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),

                      // Month navigation arrows + month text
                      controlsTextStyle: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),

                      // Day cell builder
                      dayBuilder:
                          ({
                            required DateTime date,
                            bool? isSelected,
                            bool? isToday,
                            TextStyle? textStyle,
                            BoxDecoration? decoration,
                            bool? isDisabled,
                          }) {
                            final hasEvent = eventMap.containsKey(
                              _dayKey(date),
                            );

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
                                      "${date.day}",
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected == true
                                            ? cs.onPrimary
                                            : cs.onSurface,
                                      ),
                                    ),

                                    if (hasEvent)
                                      Positioned(
                                        bottom: 3,
                                        child: Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: cs.primary,
                                            shape: BoxShape.circle,
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
                        setState(() {
                          _selectedDate = nextDate;
                          _selectedEvent = null;
                        });
                        if (_loadedMonth == null ||
                            _monthStart(_loadedMonth!) != nextMonth) {
                          _loadMonth(nextDate);
                        }
                      }
                    },
                  ),

                  const SizedBox(height: 40),

                  // SELECTED DATE CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.onSurface.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${_selectedDate.day} / ${_selectedDate.month} / ${_selectedDate.year}",
                      style: GoogleFonts.inter(
                        fontSize: AdaptiveUtils.getTitleFontSize(width),
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // EVENTS LIST
                  ..._buildEventList(context, cs, width, eventMap),

                  const SizedBox(height: 32),

                  // DETAILS BOX
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cs.surface.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.onSurface.withOpacity(0.06)),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _openSelectedEventTarget,
                          behavior: HitTestBehavior.opaque,
                          child: Text(
                            "Event Details",
                            style: GoogleFonts.inter(
                              fontSize:
                                  AdaptiveUtils.getTitleFontSize(width) + 2,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _eventDetailText(_selectedEvent),
                          style: GoogleFonts.inter(
                            fontSize:
                                AdaptiveUtils.getSubtitleFontSize(width) - 3,
                            color: cs.onSurface.withOpacity(0.6),
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

  // EVENT LIST REUSABLE BUILDER
  List<Widget> _buildEventList(
    BuildContext context,
    ColorScheme cs,
    double width,
    Map<DateTime, List<Map<String, dynamic>>> eventMap,
  ) {
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
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getSubtitleFontSize(width),
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
                      style: GoogleFonts.inter(
                        fontSize: AdaptiveUtils.getTitleFontSize(width),
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "at ${event['time']}",
                      style: GoogleFonts.inter(
                        fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
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
            style: GoogleFonts.inter(
              fontSize: 12,
              color: selected ? cs.primary : cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
