// components/common/navigate_box.dart
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

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    // Adaptive values from our shared utils
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth); // 8 / 12 / 16
    final double titleFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 3; // 12–16
    final double tabFontSize = AdaptiveUtils.getTitleFontSize(screenWidth);     // 12–14
    final double tabHorizontalPadding = padding;
    final double tabVerticalPadding = AdaptiveUtils.getLeftSectionSpacing(screenWidth); // 6–10
    final double tabSpacing = AdaptiveUtils.getIconPaddingLeft(screenWidth); // 6–12

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
          // "NAVIGATE" title
          Text(
            "NAVIGATE",
            style: GoogleFonts.inter(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.7),
              letterSpacing: 0.8,
            ),
          ),

          const SizedBox(height: 12),

          // Horizontal tab bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                "Profile",
                "Credit History",
                "Documents",
                "Vehicles",
                "Setting",
                "Roles"
              ].map((tab) {
                final bool isSelected = selectedTab == tab;

                return Padding(
                  padding: EdgeInsets.only(right: tabSpacing),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () => setState(() => selectedTab = tab),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: tabHorizontalPadding,
                        vertical: tabVerticalPadding,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.black
                            : Colors.black.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        tab,
                        style: GoogleFonts.inter(
                          fontSize: tabFontSize,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
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