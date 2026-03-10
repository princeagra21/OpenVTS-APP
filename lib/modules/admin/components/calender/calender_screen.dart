import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_calendar_event_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_calendar_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EventCalendarScreen extends StatefulWidget {
  const EventCalendarScreen({super.key});

  @override
  State<EventCalendarScreen> createState() => _EventCalendarScreenState();
}

class _EventCalendarScreenState extends State<EventCalendarScreen> {
  // Endpoint truth table (FleetStack-API-Reference.md + Postman):
  // - GET /admin/calendar/events?from=YYYY-MM-DD&to=YYYY-MM-DD
  // Key mapping used:
  // - list: data/events/items/results (tolerant)
  // - fields: id, title/name/label, type/category, date/start, time/startTime
  DateTime _selectedDate = DateTime.now();
  DateTime? _loadedMonth;
  String _selectedLegend = 'all';

  List<AdminCalendarEventItem> _events = const <AdminCalendarEventItem>[];
  AdminCalendarEventItem? _selectedEvent;

  bool _loading = false;
  bool _loadingMonth = false;
  bool _errorShown = false;

  CancelToken? _loadToken;

  final Map<String, List<AdminCalendarEventItem>> _monthCache = {};

  ApiClient? _apiClient;
  AdminCalendarRepository? _repo;

  AdminCalendarRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= AdminCalendarRepository(api: _apiClient!);
    return _repo!;
  }

  String _monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  String _dateOnly(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  bool _isCancelled(Object err) {
    return err is ApiException &&
        err.message.toLowerCase() == 'request cancelled';
  }

  void _showLoadErrorOnce(String message) {
    if (_errorShown || !mounted) return;
    _errorShown = true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadMonthEvents(DateTime date, {bool force = false}) async {
    final monthStart = DateTime(date.year, date.month, 1);
    final monthEnd = DateTime(date.year, date.month + 1, 0);
    final key = _monthKey(monthStart);

    if (!force && _monthCache.containsKey(key)) {
      if (!mounted) return;
      setState(() {
        _events = _monthCache[key]!;
        _loading = false;
        _loadedMonth = monthStart;
      });
      return;
    }

    if (_loadingMonth) return;
    _loadingMonth = true;

    _loadToken?.cancel('Reload calendar month');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loading = true);

    final result = await _repoOrCreate().getCalendarEvents(
      from: _dateOnly(monthStart),
      to: _dateOnly(monthEnd),
      cancelToken: token,
    );

    if (!mounted) {
      _loadingMonth = false;
      return;
    }

    result.when(
      success: (events) {
        _monthCache[key] = events;
        setState(() {
          _events = events;
          _loading = false;
          _loadedMonth = monthStart;
          _errorShown = false;

          final dayEvents = _eventsForDay(_selectedDate, events);
          _selectedEvent = dayEvents.isNotEmpty ? dayEvents.first : null;
        });
      },
      failure: (err) {
        setState(() {
          _events = const <AdminCalendarEventItem>[];
          _loading = false;
          _loadedMonth = monthStart;
          _selectedEvent = null;
        });

        if (!_isCancelled(err)) {
          final message = err is ApiException
              ? err.message
              : "Couldn't load calendar events.";
          _showLoadErrorOnce(message);
        }
      },
    );

    _loadingMonth = false;
  }

  List<AdminCalendarEventItem> _eventsForDay(
    DateTime day,
    List<AdminCalendarEventItem> source,
  ) {
    return source.where((event) {
      if (_selectedLegend != 'all' && event.normalizedType != _selectedLegend) {
        return false;
      }
      final dt = event.dateTime;
      if (dt == null) return false;
      return dt.year == day.year && dt.month == day.month && dt.day == day.day;
    }).toList();
  }

  List<AdminCalendarEventItem> get _selectedDayEvents =>
      _eventsForDay(_selectedDate, _events);

  bool _hasEventForDate(DateTime day) => _eventsForDay(day, _events).isNotEmpty;

  String _monthName(int month) {
    const names = [
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
    return names[(month - 1).clamp(0, 11)];
  }

  @override
  void initState() {
    super.initState();
    _loadMonthEvents(_selectedDate);
  }

  @override
  void dispose() {
    _loadToken?.cancel('EventCalendarScreen disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;
    final bool isMobile = width < 650;

    return AppLayout(
      title: 'Calendar',
      subtitle: 'Event',
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 3,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_monthName(_selectedDate.month)} ${_selectedDate.year}',
                              style: GoogleFonts.inter(
                                fontSize:
                                    AdaptiveUtils.getTitleFontSize(width) + 4,
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Today',
                              style: GoogleFonts.inter(
                                fontSize:
                                    AdaptiveUtils.getSubtitleFontSize(width) -
                                    3,
                                fontWeight: FontWeight.w500,
                                color: cs.onSurface.withOpacity(0.7),
                              ),
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
                            'Monochrome Calendar\nAdmin/User/Vehicle Events',
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
                  Wrap(
                    spacing: 20,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      _legendItem('Admin Created', 'admin', cs),
                      _legendItem('User Created', 'user', cs),
                      _legendItem('Vehicle Expiry', 'vehicle_expiry', cs),
                      _legendItem('Vehicle Added', 'vehicle_added', cs),
                    ],
                  ),
                  const SizedBox(height: 32),
                  CalendarDatePicker2(
                    config: CalendarDatePicker2Config(
                      calendarType: CalendarDatePicker2Type.single,
                      selectedDayHighlightColor: cs.primary,
                      weekdayLabelTextStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                      dayTextStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                      selectedDayTextStyle: GoogleFonts.inter(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      todayTextStyle: GoogleFonts.inter(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                      controlsTextStyle: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                      dayBuilder:
                          ({
                            required DateTime date,
                            bool? isSelected,
                            bool? isToday,
                            TextStyle? textStyle,
                            BoxDecoration? decoration,
                            bool? isDisabled,
                          }) {
                            final hasEvent = _hasEventForDate(
                              DateTime(date.year, date.month, date.day),
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
                                      '${date.day}',
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
                      if (dates.isEmpty) return;
                      final next = dates.first;
                      final monthChanged =
                          _loadedMonth == null ||
                          _loadedMonth!.year != next.year ||
                          _loadedMonth!.month != next.month;

                      setState(() {
                        _selectedDate = next;
                        final dayEvents = _selectedDayEvents;
                        _selectedEvent = dayEvents.isNotEmpty
                            ? dayEvents.first
                            : null;
                      });

                      if (monthChanged) {
                        _loadMonthEvents(next);
                      }
                    },
                  ),
                  const SizedBox(height: 40),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cs.onSurface.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_selectedDate.day} / ${_selectedDate.month} / ${_selectedDate.year}',
                      style: GoogleFonts.inter(
                        fontSize: AdaptiveUtils.getTitleFontSize(width),
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ..._buildEventList(context, cs, width),
                  const SizedBox(height: 32),
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
                        Text(
                          'Event Details',
                          style: GoogleFonts.inter(
                            fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_loading)
                          const Column(
                            children: [
                              AppShimmer(width: 180, height: 12, radius: 6),
                              SizedBox(height: 8),
                              AppShimmer(width: 220, height: 12, radius: 6),
                            ],
                          )
                        else
                          Text(
                            _selectedEvent == null
                                ? 'Select an event to view details.'
                                : (_selectedEvent!.description.isNotEmpty
                                      ? _selectedEvent!.description
                                      : _selectedEvent!.title),
                            style: GoogleFonts.inter(
                              fontSize:
                                  AdaptiveUtils.getSubtitleFontSize(width) - 3,
                              color: cs.onSurface.withOpacity(0.6),
                            ),
                            textAlign: TextAlign.center,
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

  List<Widget> _buildEventList(
    BuildContext context,
    ColorScheme cs,
    double width,
  ) {
    if (_loading) {
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.onSurface.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            children: [
              AppShimmer(width: double.infinity, height: 14, radius: 7),
              SizedBox(height: 10),
              AppShimmer(width: 180, height: 12, radius: 6),
            ],
          ),
        ),
      ];
    }

    final events = _selectedDayEvents;
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
              'No events for this date.',
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
      return GestureDetector(
        onTap: () => setState(() => _selectedEvent = event),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.onSurface.withOpacity(0.05)),
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
                      event.title.isEmpty ? '—' : event.title,
                      style: GoogleFonts.inter(
                        fontSize: AdaptiveUtils.getTitleFontSize(width),
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.time.isEmpty ? '—' : 'at ${event.time}',
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

  Widget _legendItem(String label, String type, ColorScheme cs) {
    return GestureDetector(
      onTap: () => setState(() {
        _selectedLegend = _selectedLegend == type ? 'all' : type;
        final dayEvents = _selectedDayEvents;
        _selectedEvent = dayEvents.isNotEmpty ? dayEvents.first : null;
      }),
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
            style: GoogleFonts.inter(fontSize: 12, color: cs.onSurface),
          ),
        ],
      ),
    );
  }
}
