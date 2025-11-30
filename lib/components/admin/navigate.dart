import 'package:fleet_stack/components/small_box/small_box.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/adaptive_utils.dart';

class NavigateBox extends StatefulWidget {
  const NavigateBox({super.key});

  @override
  State<NavigateBox> createState() => _NavigateBoxState();
}

class _NavigateBoxState extends State<NavigateBox> {
  String selectedTab = "Profile";

  final List<String> tabs = [
    "Profile",
    "Credit History",
    "Documents",
    "Vehicles",
    "Setting",
    "Roles"
  ];

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth); // 8 /12/16

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
          Text(
            "NAVIGATE",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.7),
              letterSpacing: 0.8,
            ),
          ),

          const SizedBox(height: 12),

          // -------------------------
          //   USE SMALLTAB HERE
          // -------------------------
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: tabs.map((tab) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: SmallTab(
                    label: tab,
                    selected: selectedTab == tab,
                    onTap: () => setState(() => selectedTab = tab),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
