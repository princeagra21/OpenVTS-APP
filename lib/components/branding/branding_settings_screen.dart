import 'package:fleet_stack/components/small_box/small_box.dart';
import 'package:fleet_stack/layout/app_layout.dart';
import 'package:fleet_stack/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BrandingSettingsScreen extends StatelessWidget {
  const BrandingSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;

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
            _BrandingSettingsBox(),

            const SizedBox(height: 24),

            // You can add more boxes here like profile screen
          ],
        ),
      ),
    );
  }
}

class _BrandingSettingsBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(hp),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    // LEFT: Title Texts
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "White Label",
          style: GoogleFonts.inter(
            fontSize: AdaptiveUtils.getTitleFontSize(width),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Branding Settings",
          style: GoogleFonts.inter(
            fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
            fontWeight: FontWeight.w800,
            color: Colors.black.withOpacity(0.9),
          ),
        ),
      ],
    ),

    // RIGHT: Save Button
    ElevatedButton.icon(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        padding: EdgeInsets.symmetric(
          horizontal: hp + 2,
          vertical: hp - 4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      icon: Icon(
        Icons.save_outlined,
        color: Colors.white,
        size: AdaptiveUtils.getIconSize(width),
      ),
      label: Text(
        "Save Changes",
        style: GoogleFonts.inter(
          fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  ],
),


          SizedBox(height: hp * 2),

        Container(
  width: double.infinity,
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surface, // theme surface color
    borderRadius: BorderRadius.circular(12),      // rounded corners
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        spreadRadius: 1,
        blurRadius: 8,
        offset: Offset(0, 4),
      ),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Header Row
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.language,
            size: AdaptiveUtils.getIconSize(width),
            color: Colors.black87,
          ),
          SizedBox(width: hp / 2),
          Text(
            "Base URL Configuration",
            style: GoogleFonts.inter(
              fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
              fontWeight: FontWeight.w800,
              color: Colors.black.withOpacity(0.9),
            ),
          ),
        ],
      ),
      SizedBox(height: 16),

      // Label
      Text(
        "Base URL",
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      SizedBox(height: 8),

      // TextField with editable text
      TextField(
        controller: TextEditingController(text: "app.fleetstack.com"),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.black),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.black),
          ),
        ),
        style: TextStyle(color: Colors.black),
      ),

      SizedBox(height: 4),

      // Helper text below the TextField
      Text(
        "Enter your custom domain without http:// or https://",
        style: GoogleFonts.inter(
          fontSize: 12,
          color: Colors.black54,
        ),
      ),

      SizedBox(height: 24,),
      Container(
  width: double.infinity,
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surface, // theme surface color
    borderRadius: BorderRadius.circular(12),      // rounded corners
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        spreadRadius: 1,
        blurRadius: 8,
        offset: Offset(0, 4),
      ),
    ],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Header Row with icon
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.storage, // server icon
            size: 24,      // adjust size if needed
            color: Colors.black87,
          ),
          SizedBox(width: 8),
          Text(
            "Server Information",
            style: GoogleFonts.inter(
              fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
              fontWeight: FontWeight.w800,
              color: Colors.black.withOpacity(0.9),
            ),
          ),
        ],
      ),

      SizedBox(height: 16),

     // Server IP Row
Row(
  children: [
    Text(
      "Server IP:",
      style: GoogleFonts.inter(
        fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 6,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    ),
    SizedBox(width: 6), // spacing between label and tab
    SmallTab(
      label: "192.168.1.100",
      selected: false,
      fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 6,
      onTap: () {
        // optional tap action
      },
    ),
  ],
),

      SizedBox(height: 8),

      // Helper text
      Text(
        "Use this IP address for DNS configuration",
        style: GoogleFonts.inter(
          fontSize: 12,
          color: Colors.black54,
        ),
      ),
      
    ],
  ),
),
SizedBox(height: 13),
Divider(thickness: 0.5, color: Colors.black.withOpacity(0.7),),
SizedBox(height: 13),

Container(
  width: double.infinity,
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Header Row: icon + text
      Row(
        children: [
          Icon(
            Icons.image,
            size: 24,
            color: Colors.black87,
          ),
          SizedBox(width: 8),
          Text(
            "Favicon & Logos",
            style: GoogleFonts.inter(
              fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
              fontWeight: FontWeight.w800,
              color: Colors.black.withOpacity(0.9),
            ),
          ),
        ],
      ),

      SizedBox(height: 16),

     // ----------------------------
// Favicon Container
_buildSingleUploadContainer(
  context: context,
  width: width,
  title: "Favicon",
  smallTabLabel: "16x16 or 32x32 px",
),

SizedBox(height: 16),

// ----------------------------
// Dark Logo Container
_buildSingleUploadContainer(
  context: context,
  width: width,
  title: "Dark Logo",
  smallTabLabel: "For light backgrounds",
),

SizedBox(height: 16),

// ----------------------------
// Light Logo Container
_buildSingleUploadContainer(
  context: context,
  width: width,
  title: "Light Logo",
  smallTabLabel: "For dark backgrounds",
),

    ],
  ),
),


    ],
  ),
),


        ],
      ),
    );
 
 
  }

  
Widget _buildSingleUploadContainer({
  required BuildContext context,
  required double width,
  required String title,
  required String smallTabLabel,
}) {
  // Responsive height
  double boxHeight = width < 500 ? 85 : 110;

  return Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),

      // Softer shadow
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          spreadRadius: 0.5,
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(width: 12),

            // 🔥 NEW SMALL TAG
            buildSmallTag(smallTabLabel, width),
          ],
        ),

        SizedBox(height: 10),

        Row(
          children: [
            // Upload
            Expanded(
              child: Container(
                height: boxHeight,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black45, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_file, size: 26, color: Colors.black54),
                      SizedBox(height: 4),
                      Text(
                        "Click to upload\nICO, PNG (max 2MB)",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 6,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(width: 12),

            // Preview
            Expanded(
              child: Stack(
                children: [
                  Container(
                    height: boxHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[200],
                    ),
                    child: Center(
                      child: Text(
                        "Preview",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    top: 4,
                    right: 4,
                    child: InkWell(
                      onTap: () {},
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}



Widget buildSmallTag(String text, double width) {
  final bool isSmall = width < 420;

  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: isSmall ? 8 : 10,
      vertical: isSmall ? 4 : 5,
    ),
    decoration: BoxDecoration(
      color: Colors.white10,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: isSmall ? 9.5 : 11,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    ),
  );
}

}