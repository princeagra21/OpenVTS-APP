// components/fleet/fleet_overview_box.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/adaptive_utils.dart';

class CustomBox extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double radius;

  const CustomBox({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.radius = 25.0, // default to 25 to match your design
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);

    return Container(
      width: width ?? double.infinity,
      height: height,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class FleetOverviewBox extends StatelessWidget {
  const FleetOverviewBox({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final colorScheme = Theme.of(context).colorScheme;

    // Adaptive values from our design system
    final double titleFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 2;     // 14–18
    final double bigNumberFontSize = titleFontSize * 2.4; // ~34–43, scales perfectly
    final double descriptionFontSize = AdaptiveUtils.getTitleFontSize(screenWidth) ; // 13–15
    final double badgeFontSize = AdaptiveUtils.getTitleFontSize(screenWidth);     // 12–14
    final double capsuleFontSize = AdaptiveUtils.getTitleFontSize(screenWidth) ;   // 13–15
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth);         // 6–10

    return CustomBox(
      radius: 25.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title + Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Your fleet Today",
                style: GoogleFonts.inter(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            //  Container(
              //  padding: EdgeInsets.symmetric(
                //  horizontal: spacing + 4,
                //  vertical: spacing - 2,
              //  ),
               // decoration: BoxDecoration(
                 // border: Border.all(color: colorScheme.onSurface, width: 1),
     //             borderRadius: BorderRadius.circular(20),
       ///         ),
       //         child: Text(
        //          "Today 12M",
        //          style: GoogleFonts.inter(
        //            fontSize: badgeFontSize,
        //            fontWeight: FontWeight.w600,
        //            color: colorScheme.onSurface,
        //          ),
        //        ),
         //     ),
            ],
          ),

          SizedBox(height: spacing + 4),

          // Big Number
          Text(
            "3579",
            style: GoogleFonts.inter(
              fontSize: bigNumberFontSize,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              height: 1.1,
              letterSpacing: -1.5,
            ),
          ),

          SizedBox(height: spacing),

          // Description
          Text(
            "Total Vehicles across all admins",
            style: GoogleFonts.inter(
              fontSize: descriptionFontSize,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),

          SizedBox(height: spacing + 6),

          // Capsules
          Wrap(
            spacing: spacing + 4,
            runSpacing: spacing + 2,
            children: [
              _capsule(context, "Active 2300", capsuleFontSize, spacing),
              _capsule(context, "Users 2097", capsuleFontSize, spacing),
              _capsule(context, "Admins 234", capsuleFontSize, spacing),
              _capsule(context, "Licenses used 34298", capsuleFontSize, spacing),
            ],
          ),
        ],
      ),
    );
  }

 Widget _capsule(BuildContext context, String text, double fontSize, double spacing) {
  final cs = Theme.of(context).colorScheme;

  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: spacing + 8,
      vertical: spacing,
    ),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(999), // TRUE PILL
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: cs.onSurface,
      ),
    ),
  );
}

}