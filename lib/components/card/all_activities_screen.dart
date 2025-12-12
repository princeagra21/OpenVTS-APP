// UPDATED: screens/all_activities_screen.dart (renamed from all_transactions_screen.dart)
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:fleet_stack/layout/app_layout.dart';
import 'package:fleet_stack/utils/adaptive_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AllActivitiesScreen extends StatefulWidget {
  final String activityType;

  const AllActivitiesScreen({
    super.key,
    required this.activityType,
  });

  @override
  State<AllActivitiesScreen> createState() => _AllActivitiesScreenState();
}

class _AllActivitiesScreenState extends State<AllActivitiesScreen> {
  List<DateTime?> _selectedRange = [];
  late List<Map<String, dynamic>> allActivities;

  @override
  void initState() {
    super.initState();
    _generateData();
  }

  void _generateData() {
    switch (widget.activityType) {
      case "Vehicles":
        allActivities = List.generate(50, (i) => {
              "id": "MH-12-AB-${1000 + i}",
              "name": ["Tata Ace", "Maruti Swift", "Hyundai Creta"][i % 3],
              "status": ["Active", "Idle"][i % 2],
              "date": DateTime.now().subtract(Duration(days: i)),
            });
        break;
      case "Transactions":
        allActivities = List.generate(50, (i) => {
              "id": "TXN-2024-${11 + (i ~/ 10)}-${100 + i % 10}",
              "value": "₹${10000 + i * 500}",
              "description":
                  "${["Aarav Sharma", "Vihaan Patel", "Aditya Singh"][i % 3]} • ${["License Purchase", "Payment Received", "Refund Issued"][i % 3]}",
              "status": ["Completed", "Pending", "Failed"][i % 3],
              "date": DateTime.now().subtract(Duration(days: i)),
            });
        break;
      case "Users":
        allActivities = List.generate(50, (i) => {
              "name": ["Aarav Sharma", "Vihaan Patel", "Aditya Singh", "Reyansh Kumar", "Arjun Reddy"][i % 5],
              "email": "${["aarav.s", "vihaan.p", "aditya.s", "reyansh.k", "arjun.r"][i % 5]}@example.com",
              "date": DateTime.now().subtract(Duration(days: i)),
            });
        break;
      default:
        allActivities = [];
    }
  }

  Future<void> _pickDateRange() async {
    final results = await showCalendarDatePicker2Dialog(
      context: context,
      dialogSize: const Size(350, 380),
      value: _selectedRange,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.range,
        selectedDayHighlightColor: Theme.of(context).colorScheme.primary,
      ),
    );

    if (results != null && results.length == 2) {
      setState(() => _selectedRange = results);
    }
  }

  String get formattedRange {
    if (_selectedRange.isEmpty || _selectedRange[0] == null) return 'All Dates';

    final df = DateFormat('MMM dd, yyyy');
    final start = df.format(_selectedRange[0]!);
    final end = _selectedRange.length > 1 && _selectedRange[1] != null ? df.format(_selectedRange[1]!) : start;
    return '$start - $end';
  }

  List<Map<String, dynamic>> get filteredActivities {
    if (_selectedRange.isEmpty || _selectedRange[0] == null) return allActivities;

    final start = _selectedRange[0]!;
    final end = (_selectedRange[1] ?? start).add(const Duration(days: 1)).subtract(const Duration(seconds: 1));

    return allActivities.where((activity) {
      final date = activity["date"] as DateTime;
      return date.isAfter(start.subtract(const Duration(seconds: 1))) && date.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();
  }

  Map<String, Color> getStatusColors(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return {
      "Active": colorScheme.primary,
      "Idle": colorScheme.primary.withOpacity(0.7),
      "Completed": colorScheme.primary,
      "Pending": colorScheme.primary.withOpacity(0.7),
      "Failed": colorScheme.error,
    };
  }

  Widget buildActivityItem(Map<String, dynamic> activity) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    final double mainFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final double subFontSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final double badgeFontSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final double itemPadding = AdaptiveUtils.getLeftSectionSpacing(screenWidth);

    final statusColors = getStatusColors(context);
    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(activity["date"]);

    Widget avatar;
    Widget content;
    Widget right = const SizedBox.shrink();

    switch (widget.activityType) {
      case "Vehicles":
        avatar = CircleAvatar(
          radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2.4,
          backgroundColor: colorScheme.surfaceVariant,
          child: Icon(Icons.directions_car, color: colorScheme.primary),
        );

        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(activity["id"], style: GoogleFonts.inter(fontSize: mainFontSize, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
            Text(activity["name"], style: GoogleFonts.inter(fontSize: subFontSize, color: colorScheme.onSurface.withOpacity(0.54))),
            Text(dateStr, style: GoogleFonts.inter(fontSize: subFontSize - 1, color: colorScheme.onSurface.withOpacity(0.7))),
          ],
        );

        right = Container(
          padding: EdgeInsets.symmetric(horizontal: itemPadding + 2, vertical: itemPadding - 2),
          decoration: BoxDecoration(
            color: statusColors[activity["status"]],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            activity["status"],
            style: GoogleFonts.inter(color: colorScheme.onPrimary, fontSize: badgeFontSize),
          ),
        );
        break;

      case "Transactions":
        avatar = CircleAvatar(
          radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2.4,
          backgroundColor: colorScheme.surfaceVariant,
          child: Icon(Icons.receipt_long, color: colorScheme.primary),
        );

        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(activity["id"],
                    style: GoogleFonts.inter(fontSize: mainFontSize, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                Text(activity["value"],
                    style: GoogleFonts.inter(fontSize: mainFontSize, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              activity["description"],
              style: GoogleFonts.inter(fontSize: subFontSize, color: colorScheme.onSurface.withOpacity(0.54)),
            ),
            const SizedBox(height: 2),
            Text(
              dateStr,
              style: GoogleFonts.inter(fontSize: subFontSize - 1, color: colorScheme.onSurface.withOpacity(0.7)),
            ),
          ],
        );

        right = Container(
          padding: EdgeInsets.symmetric(horizontal: itemPadding, vertical: itemPadding - 3),
          decoration: BoxDecoration(
            color: statusColors[activity["status"]],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            activity["status"],
            style: GoogleFonts.inter(color: colorScheme.onPrimary, fontSize: badgeFontSize),
          ),
        );
        break;

      case "Users":
        final name = activity["name"] as String;
        final initials = name.split(" ").map((e) => e.isNotEmpty ? e[0] : '').take(2).join();

        avatar = Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.primary.withOpacity(0.8), width: 2),
          ),
          child: CircleAvatar(
            radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2.4,
            backgroundColor: Colors.transparent,
            child: Text(initials, style: GoogleFonts.inter(fontSize: mainFontSize, fontWeight: FontWeight.bold, color: colorScheme.primary)),
          ),
        );

        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: GoogleFonts.inter(fontSize: mainFontSize, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
            Text(activity["email"], style: GoogleFonts.inter(fontSize: subFontSize, color: colorScheme.onSurface.withOpacity(0.54))),
            Text(dateStr, style: GoogleFonts.inter(fontSize: subFontSize - 1, color: colorScheme.onSurface.withOpacity(0.7))),
          ],
        );

        right = const SizedBox.shrink(); // No status for users
        break;

      default:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: itemPadding),
      child: Row(
        children: [
          avatar,
          SizedBox(width: itemPadding + 2),
          Expanded(child: content),
          if (right is! SizedBox) ...[
            SizedBox(width: itemPadding + 2),
            right,
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double hp = AdaptiveUtils.getHorizontalPadding(MediaQuery.of(context).size.width);
    final double fs = AdaptiveUtils.getSubtitleFontSize(MediaQuery.of(context).size.width);
    final String title = widget.activityType;
    final String subtitle = 'All ${widget.activityType}';

    return AppLayout(
      title: title,
      subtitle: subtitle,
      showLeftAvatar: false,
      showRightAvatar: false,
      leftAvatarText: '',
      actionIcons: [CupertinoIcons.search], // Optional: Add search if needed
      // onActionTaps: [...] if needed
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DATE RANGE PICKER
          Center(
            child: GestureDetector(
              onTap: _pickDateRange,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: hp, vertical: hp * 0.9),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.primary, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_month, size: fs + 4, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(formattedRange, style: GoogleFonts.inter(fontSize: fs, color: colorScheme.onSurface)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (filteredActivities.isEmpty)
            Center(
              child: Text('No activities in selected range',
                  style: GoogleFonts.inter(fontSize: fs, color: colorScheme.onSurface.withOpacity(0.6))),
            )
          else
            ListView.separated(
              shrinkWrap: true, // Added to fix unbounded height
              physics: NeverScrollableScrollPhysics(), // Added to disable inner scroll, let outer handle it
              padding: EdgeInsets.zero,
              itemCount: filteredActivities.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: colorScheme.onSurface.withOpacity(0.08)),
              itemBuilder: (_, index) => buildActivityItem(filteredActivities[index]),
            ),
        ],
      ),
    );
  }
}