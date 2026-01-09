// components/recent_activity_box.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:intl/intl.dart';

class SmallTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedBackground;

  const SmallTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedBackground,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    final double hPadding = AdaptiveUtils.getHorizontalPadding(screenWidth) - 4;
    final double vPadding = AdaptiveUtils.getLeftSectionSpacing(screenWidth) - 2;
    final double fontSize = AdaptiveUtils.getTitleFontSize(screenWidth);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
        decoration: BoxDecoration(
          color: selected
              ? (selectedBackground ?? colorScheme.primary)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.onSurface, width: 1),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: selected
                ? colorScheme.onPrimary
                : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class RecentActivityBox extends StatefulWidget {
  const RecentActivityBox({super.key});

  @override
  State<RecentActivityBox> createState() => _RecentActivityBoxState();
}

class _RecentActivityBoxState extends State<RecentActivityBox> {
  String activityTab = "Recent Activity";

  late final List<Map<String, dynamic>> recentActivities;

  @override
  void initState() {
    super.initState();
    recentActivities = [
      {
        "date": DateTime.now().subtract(Duration(hours: 1, minutes: 18)),
        "description": "Policy updated for Fleet-APAC"
      },
      {
        "date": DateTime.now().subtract(Duration(hours: 2, minutes: 37)),
        "description": "User Priya created a TrackLink"
      },
      {
        "date": DateTime.now().subtract(Duration(hours: 2, minutes: 52)),
        "description": "12 vehicles added to Group Warehousing"
      },
      {
        "date": DateTime.now().subtract(Duration(days: 1)),
        "description": "Admin billed for 200 credits"
      },
      {
        "date": DateTime.now().subtract(Duration(days: 2)),
        "description": "System maintenance completed"
      },
      {
        "date": DateTime.now().subtract(Duration(days: 3, hours: 4)),
        "description": "Vehicle MH-12-AB-1234 started trip"
      },
      {
        "date": DateTime.now().subtract(Duration(hours: 5)),
        "description": "Route optimized for Trip #456"
      },
      {
        "date": DateTime.now().subtract(Duration(minutes: 30)),
        "description": "Alert: Overspeed detected for MH-01-BB-5678"
      },
      {
        "date": DateTime.now().subtract(Duration(days: 4)),
        "description": "User Raj updated profile"
      },
      {
        "date": DateTime.now().subtract(Duration(days: 5)),
        "description": "Group Logistics permissions changed"
      },
    ];
  }

  List<Map<String, dynamic>> get currentActivities {
    return recentActivities;
  }

  String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${diff.inDays} days ago';
    }
  }

  Widget buildActivityItem(Map<String, dynamic> activity) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    final double mainFontSize =
        AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;
    final double subFontSize =
        AdaptiveUtils.getTitleFontSize(screenWidth);
    final double itemPadding =
        AdaptiveUtils.getLeftSectionSpacing(screenWidth);

    final avatar = CircleAvatar(
      radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2.4,
      backgroundColor: colorScheme.surfaceVariant,
      child: Icon(Icons.history, color: colorScheme.primary),
    );

    final content = Text(
      '${formatRelative(activity["date"])} ${activity["description"]}',
      style: GoogleFonts.inter(
        fontSize: mainFontSize - 3,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: itemPadding),
      child: Row(
        children: [
          avatar,
          SizedBox(width: itemPadding + 2),
          Expanded(child: content),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    final double padding =
        AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double titleFontSize =
        AdaptiveUtils.getSubtitleFontSize(screenWidth);
    final double linkFontSize =
        AdaptiveUtils.getTitleFontSize(screenWidth) + 1;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing:
                    AdaptiveUtils.getIconPaddingLeft(screenWidth) - 4,
                runSpacing: 8,
                children: ["Recent Activity"].map((tab) {
                  return SmallTab(
                    label: tab,
                    selected: activityTab == tab,
                    onTap: () => setState(() => activityTab = tab),
                  );
                }).toList(),
              ),
              InkWell(
                onTap: () {
                  context.push(
                    '/admin/all-activities',
                    extra: {'type': activityTab},
                  );
                },
                child: Text("View all",
                    style: GoogleFonts.inter(
                        fontSize: linkFontSize,
                        color: colorScheme.primary)),
              ),
            ],
          ),
          SizedBox(height: 20),
          SizedBox(
            height: 320,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: currentActivities.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: colorScheme.onSurface.withOpacity(0.08),
              ),
              itemBuilder: (_, i) =>
                  buildActivityItem(currentActivities[i]),
            ),
          ),
        ],
      ),
    );
  }
}