// components/profile/profile_box.dart
import 'package:fleet_stack/core/models/admin_profile.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/user/screens/profile/widget/edit_admin_profile_screen.dart';
import 'package:fleet_stack/modules/user/screens/profile/widget/update_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileSettingBox extends StatelessWidget {
  final AdminProfile? profile;
  final String initials;
  final bool loading;
  final VoidCallback? onProfileChanged;

  const ProfileSettingBox({
    super.key,
    this.profile,
    this.initials = 'MS',
    this.loading = false,
    this.onProfileChanged,
  });

  String _safe(String? value, {String fallback = '—'}) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? fallback : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double avatarRadius = AdaptiveUtils.getAvatarSize(screenWidth) / 2;
    final double avatarFontSize = AdaptiveUtils.getFsAvatarFontSize(
      screenWidth,
    );
    final double nameFontSize =
        AdaptiveUtils.getSubtitleFontSize(screenWidth) - 4;
    final double usernameFontSize = AdaptiveUtils.getTitleFontSize(screenWidth);
    final double badgeFontSize =
        AdaptiveUtils.getTitleFontSize(screenWidth) - 4;
    final double buttonFontSize =
        AdaptiveUtils.getTitleFontSize(screenWidth) + 1;
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth);
    final double largeSpacing = padding;
    final displayName = _safe(profile?.fullName);
    final username = () {
      final raw = _safe(profile?.username, fallback: '');
      if (raw.isEmpty) return '—';
      return raw.startsWith('@') ? raw : '@$raw';
    }();
    final roleLabel = _safe(profile?.role);
    final isActive = profile?.isActive ?? false;
    final emailVerified = profile?.emailVerified ?? false;
    final hasProfile = profile != null;
    final statusLabel = hasProfile ? (isActive ? 'Active' : 'Inactive') : '—';
    final statusBg = hasProfile
        ? (isActive ? Colors.green : Colors.red).withOpacity(0.2)
        : colorScheme.outline.withOpacity(0.2);
    final statusFg = hasProfile
        ? (isActive ? Colors.green[800]! : Colors.red[800]!)
        : colorScheme.onSurface.withOpacity(0.8);
    final verifiedLabel = hasProfile
        ? (emailVerified ? 'Email Verified' : 'Email Not Verified')
        : 'Verification —';

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
                  initials,
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
                            displayName,
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
                            roleLabel,
                            style: GoogleFonts.inter(
                              color: colorScheme.onPrimary,
                              fontSize: badgeFontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (loading) ...[
                          SizedBox(width: spacing),
                          const AppShimmer(width: 14, height: 14, radius: 7),
                        ],
                      ],
                    ),
                    SizedBox(height: spacing / 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: usernameFontSize,
                              color: colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
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
                padding: EdgeInsets.symmetric(
                  horizontal: spacing + 4,
                  vertical: spacing - 2,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: badgeFontSize,
                    color: statusFg,
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
                    verifiedLabel,
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
                    Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EditAdminProfileScreen(initialProfile: profile),
                      ),
                    ).then((result) {
                      if (result == true) {
                        onProfileChanged?.call();
                      }
                    });
                  },
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: colorScheme.primary,
                        width: 1.5,
                      ),
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
                    Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UpdatePasswordScreen(),
                      ),
                    ).then((result) {
                      if (result == true) {
                        onProfileChanged?.call();
                      }
                    });
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
