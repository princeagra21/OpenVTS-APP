import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:fleet_stack/layout/app_layout.dart';
import 'package:fleet_stack/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EventCalendarScreen extends StatefulWidget {
  const EventCalendarScreen({super.key});

  @override
  State<EventCalendarScreen> createState() => _EventCalendarScreenState();
}

class _EventCalendarScreenState extends State<EventCalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();

  // Sample events data
  final Map<DateTime, List<Map<String, dynamic>>> _events = {
    DateTime(2025, 12, 8): [
      {'title': 'Admin Created', 'type': 'admin', 'time': '09:15'},
      {'title': 'User Created', 'type': 'user', 'time': '14:30'},
    ],
    DateTime(2025, 12, 12): [
      {'title': 'Vehicle Expiry', 'type': 'vehicle', 'time': '00:00'},
      {'title': 'Vehicle Added', 'type': 'vehicle', 'time': '11:45'},
    ],
    DateTime(2025, 12, 15): [
      {'title': 'User Created', 'type': 'user', 'time': '10:20'},
    ],
    DateTime(2025, 12, 20): [
      {'title': 'Vehicle Added', 'type': 'vehicle', 'time': '16:55'},
    ],
  };

  // --------------------------------------
// FORMAT WEEKDAY (Mon, Tue…)
// --------------------------------------
String _formatWeekday(int weekday) {
  const names = [
    "", // index 0 unused
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday",
  ];
  return names[weekday];
}

// --------------------------------------
// FORMAT MONTH (Jan, Feb…)
// --------------------------------------
String _formatMonth(int month) {
  const months = [
    "", // index 0 unused
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ];
  return months[month];
}

  List<Map<String, dynamic>> get _eventsForSelectedDate {
    final key = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    return _events[key] ?? [];
  }

  @override
Widget build(BuildContext context) {
  final double width = MediaQuery.of(context).size.width;
  final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;
  final bool isMobile = width < 650;

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
          // OUTER CONTAINER
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(hp),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==========================
                // HEADER
                // ==========================
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Today",
                            style: GoogleFonts.inter(
                              fontSize:
                                  AdaptiveUtils.getSubtitleFontSize(width) - 3,
                              fontWeight: FontWeight.w500,
                              color: Colors.black.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // INFO CHIP – WRAPS ON MOBILE
                    if (!isMobile)
                      Container(
                        constraints: const BoxConstraints(maxWidth: 260),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Monochrome Calendar\nAdmin/User/Vehicle Events",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize:
                                AdaptiveUtils.getSubtitleFontSize(width) - 6,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 32),

                // ==========================
                // LEGEND — NOW WRAPS SAFELY
                // ==========================
                Wrap(
                  spacing: 20,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    _legendItem("Admin Created"), 
                    _legendItem("User Created"),
                    _legendItem("Vehicle Expiry"),
                    _legendItem("Vehicle Added"),
                  ],
                ),

                const SizedBox(height: 32),

                // ==========================
                // CALENDAR
                // ==========================
                LayoutBuilder(
                  builder: (context, constraints) {
                    return CalendarDatePicker2(
                      config: CalendarDatePicker2Config(
                        calendarType: CalendarDatePicker2Type.single,
                        selectedDayHighlightColor: Colors.black,
                        

                        weekdayLabelTextStyle: GoogleFonts.inter(
                          fontSize: 12, // Added size for weekdays
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),

                        dayTextStyle: GoogleFonts.inter(
                          fontSize: 12, // Reduced size for days
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),

                        selectedDayTextStyle: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),

                        todayTextStyle: GoogleFonts.inter(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),

                        controlsTextStyle: GoogleFonts.inter(
                          fontSize: 14, // Reduced from 16
                          fontWeight: FontWeight.w600, // Reduced from w700
                          color: Colors.black87,
                        ),

                        dayBuilder: ({
                          required DateTime date,
                          BoxDecoration? decoration,
                          bool? isDisabled,
                          bool? isSelected,
                          bool? isToday,
                          TextStyle? textStyle,
                        }) {
                          final hasEvent = _events.containsKey(
                            DateTime(date.year, date.month, date.day),
                          );

                          return Center(
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isSelected == true
                                    ? Colors.black
                                    : isToday == true
                                        ? Colors.black.withOpacity(0.08)
                                        : null,
                                shape: BoxShape.circle,
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Text(
                                    "${date.day}",
                                    style: GoogleFonts.inter(
                                      fontSize: 12, // Reduced from 14
                                      fontWeight: FontWeight.w600,
                                      color: isSelected == true
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  if (hasEvent)
                                    Positioned(
                                      bottom: 3,
                                      child: Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Colors.black,
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
                        if (dates.isNotEmpty && dates.first != null) {
                          setState(() {
                            _selectedDate = dates.first!;
                          });
                        }
                      },
                    );
                  },
                ),

                const SizedBox(height: 40),

                // ==========================
                // SELECTED DATE
                // ==========================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${_formatWeekday(_selectedDate.weekday)} ${_selectedDate.day} ${_formatMonth(_selectedDate.month)} ${_selectedDate.year}",
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getTitleFontSize(width),
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ==========================
                // EVENTS LIST
                // ==========================
                if (_eventsForSelectedDate.isEmpty)
                  _emptyEvents(width)
                else
                  Column(
                    children: _eventsForSelectedDate.map((event) {
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.black.withOpacity(0.05)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.black,
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
                                      fontSize:
                                          AdaptiveUtils.getTitleFontSize(width),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "at ${event['time']}",
                                    style: GoogleFonts.inter(
                                      fontSize:
                                          AdaptiveUtils.getSubtitleFontSize(
                                                  width) -
                                              5,
                                      color: Colors.black.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 32),

                // ==========================
                // DETAILS SECTION
                // ==========================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black.withOpacity(0.05)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Event Details",
                        style: GoogleFonts.inter(
                          fontSize:
                              AdaptiveUtils.getTitleFontSize(width) + 2,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Select an event to view details.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize:
                              AdaptiveUtils.getSubtitleFontSize(width) - 3,
                          color: Colors.black.withOpacity(0.6),
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
Widget _legendItem(String label) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: Colors.black87,
        ),
      ),
    ],
  );
}
Widget _emptyEvents(double width) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Center(
      child: Text(
        "No events for this date.",
        style: GoogleFonts.inter(
          fontSize: AdaptiveUtils.getSubtitleFontSize(width),
          fontWeight: FontWeight.w500,
          color: Colors.black.withOpacity(0.7),
        ),
      ),
    ),
  );
}
}