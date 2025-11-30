// components/profile/profile_box.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/adaptive_utils.dart';

class ProfileBox extends StatelessWidget {
  const ProfileBox({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    // All sizes now come from our shared AdaptiveUtils
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth); // 8 / 12 / 16
    final double avatarRadius = AdaptiveUtils.getAvatarSize(screenWidth) / 2; // 13 / 15 / 16
    final double avatarFontSize = AdaptiveUtils.getFsAvatarFontSize(screenWidth); // 13–16
    final double nameFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth)- 4; // 14–18
    final double usernameFontSize = AdaptiveUtils.getTitleFontSize(screenWidth); // 13–15
    final double badgeFontSize = AdaptiveUtils.getTitleFontSize(screenWidth)- 4; // 11–13
    final double buttonFontSize = AdaptiveUtils.getTitleFontSize(screenWidth) + 1; // 14–16
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth); // 6–10
    final double largeSpacing = padding; // 8–16

    return Container(
      padding: EdgeInsets.all(padding + 8), // slightly larger than others for hierarchy
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
          // Top row: Avatar + Name + Status
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: Colors.black,
                child: Text(
                  "MS",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: avatarFontSize,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              SizedBox(width: largeSpacing),

              // Name & badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            "Muhammad Sani",
                            style: GoogleFonts.inter(
                              fontSize: nameFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: spacing),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: spacing + 4,
                            vertical: spacing - 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Admin",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: badgeFontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing / 2),
                    Text(
                      "@danmasana",
                      style: GoogleFonts.inter(
                        fontSize: usernameFontSize,
                        color: Colors.black.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: largeSpacing),

              // Status switch
             Column(
  children: [
    Transform.scale(
      scale: 0.75, // 🔥 decrease size (0.6, 0.7, 0.8…)
      child: Switch(
        value: true,
        onChanged: (value) {},
        activeColor: Colors.black,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    Text(
      "Status",
      style: GoogleFonts.inter(
        fontSize: badgeFontSize,
        color: Colors.black.withOpacity(0.6),
      ),
    ),
  ],
),

            ],
          ),

          SizedBox(height: largeSpacing + 4),

          // Status badges
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing + 4,
                  vertical: spacing - 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Active",
                  style: GoogleFonts.inter(
                    fontSize: badgeFontSize,
                    color: Colors.green[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: spacing + 4),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing + 4,
                  vertical: spacing - 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Email Verified",
                  style: GoogleFonts.inter(
                    fontSize: badgeFontSize,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: largeSpacing + 8),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1.5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      "Edit Profile",
                      style: GoogleFonts.inter(
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: spacing + 4),
              Expanded(
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Text(
                      "Update Password",
                      style: GoogleFonts.inter(
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}