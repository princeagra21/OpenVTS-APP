// screens/all_activities_screen.dart
import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
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
  late List<Map<String, dynamic>> allActivities;

  @override
  void initState() {
    super.initState();
    _generateData();
  }

  void _generateData() {
    final List<String> descTemplates = [
      "Policy updated for Fleet-APAC",
      "User Priya created a TrackLink",
      "12 vehicles added to Group Warehousing",
      "Admin billed for 200 credits",
      "System maintenance completed",
      "Vehicle MH-12-AB-1234 started trip",
      "Route optimized for Trip #456",
      "Alert: Overspeed detected for MH-01-BB-5678",
      "User Raj updated profile",
      "Group Logistics permissions changed",
    ];
    if (widget.activityType == "Recent Activity") {
      allActivities = List.generate(50, (i) => {
            "description": descTemplates[i % descTemplates.length],
            "date": DateTime.now().subtract(Duration(days: i)),
          });
    } else {
      allActivities = [];
    }
  }

  List<Map<String, dynamic>> get filteredActivities {
    return allActivities;
  }

  Widget buildActivityItem(Map<String, dynamic> activity) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    final double mainFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final double subFontSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final double itemPadding = AdaptiveUtils.getLeftSectionSpacing(screenWidth);

    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(activity["date"]);

    final avatar = CircleAvatar(
      radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2.4,
      backgroundColor: colorScheme.surfaceVariant,
      child: Icon(Icons.history, color: colorScheme.primary),
    );

    final content = Text(
      activity["description"],
      style: GoogleFonts.inter(fontSize: mainFontSize, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
    );

    final right = Text(
      dateStr,
      style: GoogleFonts.inter(fontSize: subFontSize, color: colorScheme.onSurface.withOpacity(0.54)),
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: itemPadding),
      child: Row(
        children: [
          avatar,
          SizedBox(width: itemPadding + 2),
          Expanded(child: content),
          SizedBox(width: itemPadding + 2),
          right,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
