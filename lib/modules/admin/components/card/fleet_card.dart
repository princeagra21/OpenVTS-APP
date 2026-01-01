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
    final double revenueFontSize = titleFontSize * 1.2; // ~25–32 for emphasis

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
            "3577",
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
         SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  physics: const BouncingScrollPhysics(),
  child: Row(
    children: [
      _capsule(
        context,
        Icons.people_alt_rounded,
        "Users",
        "3,847",
        capsuleFontSize - 2,
        capsuleFontSize + 4,
        spacing,
      ),
      SizedBox(width: spacing + 4),
      _capsule(
        context,
        Icons.schedule_rounded,
        "Expiry (30d)",
        "129",
        capsuleFontSize - 2,
        capsuleFontSize + 4,
        spacing,
      ),
      SizedBox(width: spacing + 4),
      _capsule(
        context,
        Icons.cancel_rounded,
        "Expired",
        "74",
        capsuleFontSize - 2,
        capsuleFontSize + 4,
        spacing,
        iconColor: Colors.redAccent,
      ),
    ],
  ),
),



          SizedBox(height: spacing + 12),
 /*
          // Divider for section separation
          Divider(
            color: colorScheme.onSurface.withOpacity(0.1),
            thickness: 1,
          ),

          SizedBox(height: spacing + 6),

          // Revenue and Forecasting Section - Improved with larger numbers, better spacing, and color differentiation
         
          Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Revenue • Last Month",
            style: GoogleFonts.inter(
              fontSize: descriptionFontSize,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spacing / 2),
          Text(
            "\$48,234",
            style: GoogleFonts.inter(
              fontSize: revenueFontSize,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
              height: 1.1,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Forecasting • This Month",
            style: GoogleFonts.inter(
              fontSize: descriptionFontSize,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spacing / 2),
          Text(
            "\$57,067",
            style: GoogleFonts.inter(
              fontSize: revenueFontSize,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
              height: 1.1,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  ],
) */

        ],
      ),
    );
  }

Widget _capsule(
  BuildContext context,
  IconData icon,
  String label,
  String value,
  double labelFontSize,
  double valueFontSize,
  double spacing, {
  double width = 100,
  Color? iconColor, // 👈 optional icon color
}) {
  final cs = Theme.of(context).colorScheme;

  return SizedBox(
    width: width,
    child: Container(
      padding: EdgeInsets.all(spacing),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // icon + label
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: labelFontSize + 2,
                color: iconColor ?? cs.onSurface, // 👈 fallback
              ),
              SizedBox(width: spacing / 1.5),
              Text(
                label,
                style: TextStyle(
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),

          SizedBox(height: spacing / 2),

          // value
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    ),
  );
}


}