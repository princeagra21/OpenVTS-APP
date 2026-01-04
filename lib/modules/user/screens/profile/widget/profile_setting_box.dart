// components/profile/profile_box.dart
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/user/screens/profile/widget/edit_admin_profile_screen.dart';
import 'package:fleet_stack/modules/user/screens/profile/widget/update_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileSettingBox extends StatelessWidget {
  const ProfileSettingBox({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double avatarRadius = AdaptiveUtils.getAvatarSize(screenWidth) / 2;
    final double avatarFontSize = AdaptiveUtils.getFsAvatarFontSize(screenWidth);
    final double nameFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth) - 4;
    final double usernameFontSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final double badgeFontSize = AdaptiveUtils.getTitleFontSize(screenWidth) - 4;
    final double buttonFontSize = AdaptiveUtils.getTitleFontSize(screenWidth) + 1;
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth);
    final double largeSpacing = padding;

    return Container(
      padding: EdgeInsets.all(padding + 8),
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
          /// Top Row: Avatar + Name + Status
          Row(
            children: [
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: colorScheme.primary,
                child: Text(
                  "MS",
                  style: GoogleFonts.inter(
                    color: colorScheme.onPrimary,
                    fontSize: avatarFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: largeSpacing),
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
                              color: colorScheme.onSurface,
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
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Admin",
                            style: GoogleFonts.inter(
                              color: colorScheme.onPrimary,
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
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: largeSpacing),

              /*
              Column(
                children: [
                  Transform.scale(
                    scale: 0.75,
                    child: Switch(
                      value: true,
                      onChanged: (value) {},
                      activeColor: colorScheme.onPrimary,
                      activeTrackColor: colorScheme.primary,
                      inactiveThumbColor: colorScheme.onPrimary,
                      inactiveTrackColor: colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  Text(
                    "Status",
                    style: GoogleFonts.inter(
                      fontSize: badgeFontSize,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              */
            ],
          ),

          SizedBox(height: largeSpacing + 4),

          /// Status badges
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: spacing + 4, vertical: spacing - 2),
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
              SizedBox(width: spacing),

              // Verified badge + plain text 
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.verified_rounded,
                      size: badgeFontSize + 4,
                      color: Colors.blueAccent,
                    ),
                  ),
                  SizedBox(width: 2),
                  Text(
                    "Email Verified",
                    style: GoogleFonts.inter(
                      fontSize: badgeFontSize,
                      color: colorScheme.onSurface.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: largeSpacing + 8),

          /// Action Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditAdminProfileScreen(),
                      ),
                    );
                  },
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.primary, width: 1.5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        "Edit Profile",
                        style: GoogleFonts.inter(
                          fontSize: buttonFontSize,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: spacing + 4),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UpdatePasswordScreen(),
                      ),
                    );
                  },
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        "Update Password",
                        style: GoogleFonts.inter(
                          fontSize: buttonFontSize,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimary,
                        ),
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
