// components/activity/recent_activity_box.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/adaptive_utils.dart';

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
    final double screenWidth = MediaQuery.of(context).size.width;

    final double hPadding = AdaptiveUtils.getHorizontalPadding(screenWidth) - 4; // 4–12
    final double vPadding = AdaptiveUtils.getLeftSectionSpacing(screenWidth) - 2; // 4–8
    final double fontSize = AdaptiveUtils.getTitleFontSize(screenWidth);         // 11–13

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
        decoration: BoxDecoration(
          color: selected ? (selectedBackground ?? Colors.black) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.black,
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
  String activityTab = "Vehicles";

  final Map<String, Color> statusColors = {
    "Active": Colors.black,
    "Idle": Colors.black.withOpacity(0.7),
    "Completed": Colors.black,
    "Pending": Colors.black.withOpacity(0.7),
    "Failed": Colors.red.shade900,
  };

  late final List<Map<String, dynamic>> vehicleActivities;
  late final List<Map<String, dynamic>> transactionActivities;
  late final List<Map<String, dynamic>> userActivities;

  @override
  void initState() {
    super.initState();
    vehicleActivities = List.generate(10, (i) => {
          "id": "MH-12-AB-${1000 + i}",
          "name": ["Tata Ace", "Maruti Swift", "Hyundai Creta"][i % 3],
          "status": ["Active", "Idle"][i % 2],
          "time": "${["Today", "Yesterday", "2 days ago"][i % 3]}, ${10 + i % 12}:${(i * 3 % 60).toString().padLeft(2, '0')}",
        });

    transactionActivities = List.generate(10, (i) => {
          "id": "TXN-2024-11-${100 + i}",
          "value": "₹${10000 + i * 1000}",
          "description": "${["Aarav Sharma", "Vihaan Patel", "Aditya Singh"][i % 3]} • ${["License Purchase", "Payment Received", "Refund Issued"][i % 3]}",
          "status": ["Completed", "Pending", "Failed"][i % 3],
        });

    userActivities = List.generate(10, (i) => {
          "name": ["Aarav Sharma", "Vihaan Patel", "Aditya Singh", "Reyansh Kumar", "Arjun Reddy"][i % 5],
          "email": "${["aarav.s", "vihaan.p", "aditya.s", "reyansh.k", "arjun.r"][i % 5]}@example.com",
          "time": "${["Today", "Yesterday", "2 days ago"][i % 3]}, ${13 + i % 12}:${(i * 5 % 60).toString().padLeft(2, '0')}",
        });
  }

  List<Map<String, dynamic>> get currentActivities {
    return switch (activityTab) {
      "Vehicles" => vehicleActivities,
      "Transactions" => transactionActivities,
      _ => userActivities,
    };
  }

  Widget buildActivityItem(Map<String, dynamic> activity) {
    final double screenWidth = MediaQuery.of(context).size.width;

    final double mainFontSize   = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2; // 12–16
    final double subFontSize    = AdaptiveUtils.getTitleFontSize(screenWidth);      // 11–13
    final double badgeFontSize  = AdaptiveUtils.getTitleFontSize(screenWidth);      // 11–13
    final double itemPadding    = AdaptiveUtils.getLeftSectionSpacing(screenWidth); // 6–10

    Widget avatar;
    Widget content;
    Widget right = const SizedBox.shrink();

    switch (activityTab) {
      case "Vehicles":
        avatar = CircleAvatar(
          radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2.4,
          backgroundColor: Colors.grey[200],
          child: const Icon(Icons.directions_car, color: Colors.black),
        );

        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(activity["id"], style: GoogleFonts.inter(fontSize: mainFontSize, fontWeight: FontWeight.w600)),
            Text(activity["name"], style: GoogleFonts.inter(fontSize: subFontSize, color: Colors.black54)),
            Text(activity["time"], style: GoogleFonts.inter(fontSize: subFontSize, color: Colors.black54)),
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
            style: GoogleFonts.inter(color: Colors.white, fontSize: badgeFontSize),
          ),
        );

      case "Transactions":
        avatar = CircleAvatar(
          radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2.4,
          backgroundColor: Colors.grey[200],
          child: const Icon(Icons.receipt_long, color: Colors.black),
        );

        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(activity["id"], style: GoogleFonts.inter(fontSize: mainFontSize, fontWeight: FontWeight.w600)),
                Text(activity["value"], style: GoogleFonts.inter(fontSize: mainFontSize, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    activity["description"],
                    style: GoogleFonts.inter(fontSize: subFontSize, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: itemPadding, vertical: itemPadding - 3),
                  decoration: BoxDecoration(
                    color: statusColors[activity["status"]],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    activity["status"],
                    style: GoogleFonts.inter(color: Colors.white, fontSize: badgeFontSize),
                  ),
                ),
              ],
            ),
          ],
        );

      default: // Users
        final name = activity["name"] as String;
        final initials = name.split(" ").map((e) => e.isNotEmpty ? e[0] : '').take(2).join();

        avatar = Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black.withOpacity(0.8), width: 2),
          ),
          child: CircleAvatar(
            radius: AdaptiveUtils.getAvatarSize(screenWidth) / 2.4,
            backgroundColor: Colors.transparent,
            child: Text(initials, style: GoogleFonts.inter(fontSize: mainFontSize, fontWeight: FontWeight.bold)),
          ),
        );

        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: GoogleFonts.inter(fontSize: mainFontSize, fontWeight: FontWeight.w600)),
            Text(activity["email"], style: GoogleFonts.inter(fontSize: subFontSize, color: Colors.black54)),
          ],
        );

        right = Text(activity["time"], style: GoogleFonts.inter(fontSize: subFontSize, color: Colors.black54));
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
    final double screenWidth = MediaQuery.of(context).size.width;

    final double padding       = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double titleFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth);
    final double linkFontSize  = AdaptiveUtils.getTitleFontSize(screenWidth) + 1;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
              Text("Recent Activity", style: GoogleFonts.inter(fontSize: titleFontSize, fontWeight: FontWeight.bold)),
              InkWell(
                onTap: () {},
                child: Text("View all", style: GoogleFonts.inter(fontSize: linkFontSize, color: Colors.black)),
              ),
            ],
          ),

          SizedBox(height: padding),

          Center(
            child: Wrap(
              spacing: AdaptiveUtils.getIconPaddingLeft(screenWidth) - 4,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: ["Vehicles", "Transactions", "Users"].map((tab) {
                return SmallTab(
                  label: tab,
                  selected: activityTab == tab,
                  onTap: () => setState(() => activityTab = tab),
                );
              }).toList(),
            ),
          ),

          SizedBox(height: padding - 2),

          SizedBox(
            height: 320,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: currentActivities.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.black.withOpacity(0.08)),
              itemBuilder: (_, index) => buildActivityItem(currentActivities[index]),
            ),
          ),
        ],
      ),
    );
  }
}