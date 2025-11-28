import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final bool isSmallScreen = MediaQuery.of(context).size.width < 420;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 10 : 14,
          vertical: isSmallScreen ? 5 : 6,
        ),
        decoration: BoxDecoration(
          color: selected ? (selectedBackground ?? Colors.black) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isSmallScreen ? 10.58 : 11.96,
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
    "Idle": Colors.black,
    "Completed": Colors.black,
    "Pending": Colors.black,
    "Failed": Colors.black,
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
    final bool isSmallScreen = MediaQuery.of(context).size.width < 420;
    final textStyle = GoogleFonts.inter(
      fontSize: isSmallScreen ? 12 : 14,
      color: Colors.black,
    );
    final subTextStyle = GoogleFonts.inter(
      fontSize: isSmallScreen ? 10 : 12,
      color: Colors.black54,
    );

    Widget avatar;
    Widget content;
    Widget right;

    switch (activityTab) {
      case "Vehicles":
        avatar = CircleAvatar(
          backgroundColor: Colors.grey[200],
          child: const Icon(Icons.directions_car, color: Colors.black),
        );
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(activity["id"], style: textStyle),
            Text(activity["name"], style: subTextStyle),
            Text(activity["time"], style: subTextStyle),
          ],
        );
        right = Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColors[activity["status"]],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            activity["status"],
            style: GoogleFonts.inter(color: Colors.white, fontSize: isSmallScreen ? 10 : 12),
          ),
        );
      case "Transactions":
  avatar = CircleAvatar(
    backgroundColor: Colors.grey[200],
    child: const Icon(Icons.receipt_long, color: Colors.black),
  );

  content = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // TOP ROW — ID + PRICE
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            activity["id"],
            style: textStyle,
          ),
          Text(
            activity["value"],
            style: GoogleFonts.inter(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),

      const SizedBox(height: 4),

      // BOTTOM ROW — DESCRIPTION + STATUS BADGE
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              activity["description"],
              style: subTextStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColors[activity["status"]],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              activity["status"],
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: isSmallScreen ? 10 : 12,
              ),
            ),
          ),
        ],
      ),
    ],
  );

  // Transactions does not need a right widget
  right = const SizedBox.shrink();
  break;

      default: // Users
        final name = activity["name"] as String;
        final initials = name.split(" ").map((e) => e[0]).join();
        avatar = Container(
  padding: const EdgeInsets.all(2), // Thickness of border
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(color: Colors.black.withOpacity(0.8), width: 2), // Black border
  ),
  child: CircleAvatar(
    backgroundColor: Colors.transparent,
    child: Text(
      initials,
      style: const TextStyle(color: Colors.black),
    ),
  ),
);

        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: textStyle),
            Text(activity["email"], style: subTextStyle),
          ],
        );
        right = Text(activity["time"], style: subTextStyle);
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 12),
      child: Row(
        children: [
          avatar,
          const SizedBox(width: 12),
          Expanded(child: content),
          const SizedBox(width: 12),
          right,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 420;
    final bool isVerySmallScreen = screenWidth < 360;

    final titleStyle = GoogleFonts.inter(
      fontSize: isVerySmallScreen ? 14.72 : 16.56,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
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
              Text(
                "Recent Activity",
                style: titleStyle,
              ),
              InkWell(
                onTap: () {}, // Add navigation if needed
                child: Text(
                  "View all",
                  style: GoogleFonts.inter(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
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
          const SizedBox(height: 10),
          SizedBox(
            height: 300,
            child: ListView.separated(
              itemCount: currentActivities.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) => buildActivityItem(currentActivities[index]),
            ),
          ),
        ],
      ),
    );
  }
}