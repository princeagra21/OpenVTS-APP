// 🔥 FULLY UPDATED WITH APPTHEME COLOR SCHEME  
// EventCalendarScreen (Drop-in Replacement)

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

  // Sample Events
  final Map<DateTime, List<Map<String, dynamic>>> _events = {
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
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme; // Short alias
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
                            Text(
                              "Today",
                              style: GoogleFonts.inter(
                                fontSize:
                                    AdaptiveUtils.getSubtitleFontSize(width) - 3,
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
                              horizontal: 14, vertical: 8),
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
                      _legendItem("Admin Created", cs),
                      _legendItem("User Created", cs),
                      _legendItem("Vehicle Expiry", cs),
                      _legendItem("Vehicle Added", cs),
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
                      dayBuilder: ({
                        required DateTime date,
                        bool? isSelected,
                        bool? isToday,
                        TextStyle? textStyle,
                        BoxDecoration? decoration,
                        bool? isDisabled,
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
                      if (dates.first != null) {
                        setState(() => _selectedDate = dates.first!);
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
                  ..._buildEventList(context, cs, width),

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
                        Text(
                          "Event Details",
                          style: GoogleFonts.inter(
                            fontSize:
                                AdaptiveUtils.getTitleFontSize(width) + 2,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Select an event to view details.",
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
      BuildContext context, ColorScheme cs, double width) {
    final events = _events[DateTime(
            _selectedDate.year, _selectedDate.month, _selectedDate.day)] ??
        [];

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
      return Container(
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
                      fontSize:
                          AdaptiveUtils.getSubtitleFontSize(width) - 5,
                      color: cs.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // LEGEND UI
  Widget _legendItem(String label, ColorScheme cs) {
    return Row(
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
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}
