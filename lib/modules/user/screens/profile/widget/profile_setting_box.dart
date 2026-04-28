// components/profile/profile_box.dart
import 'package:fleet_stack/core/models/admin_profile.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/user/screens/profile/widget/edit_admin_profile_screen.dart';
import 'package:fleet_stack/modules/user/screens/profile/widget/update_password_screen.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileSettingBox extends StatelessWidget {
  final AdminProfile? profile;
  final bool loading;
  final Future<void> Function()? onUpdated;

  const ProfileSettingBox({
    super.key,
    required this.profile,
    required this.loading,
    this.onUpdated,
  });

  String _safe(String? value) {
    final v = value?.trim() ?? '';
    return v.isEmpty ? '—' : v;
  }

  String _initials(String value) {
    final v = value.trim();
    if (v.isEmpty || v == '—') return '--';
    final parts = v.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '--';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  String _roleText() {
    final v = profile?.role.trim() ?? '';
    if (v.isEmpty) return '—';
    return v.toUpperCase() == 'ADMIN' ? 'Admin' : v;
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
    final displayUsername = _safe(profile?.username);
    final role = _roleText();
    final isActive = profile?.isActive ?? false;
    final emailVerified = profile?.emailVerified ?? false;

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
          Row(
            children: [
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: colorScheme.primary,
                child: loading
                    ? AppShimmer(
                        width: avatarFontSize + 10,
                        height: 14,
                        radius: 7,
                      )
                    : Text(
                        _initials(displayName),
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
                          child: loading
                              ? AppShimmer(
                                  width: screenWidth * 0.32,
                                  height: nameFontSize + 6,
                                  radius: 8,
                                )
                              : Text(
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
                          child: loading
                              ? const AppShimmer(
                                  width: 42,
                                  height: 12,
                                  radius: 6,
                                )
                              : Text(
                                  role,
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
                    loading
                        ? AppShimmer(
                            width: screenWidth * 0.22,
                            height: usernameFontSize + 4,
                            radius: 7,
                          )
                        : Text(
                            '@$displayUsername',
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
            ],
          ),
          SizedBox(height: largeSpacing + 4),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing + 4,
                  vertical: spacing - 2,
                ),
                decoration: BoxDecoration(
                  color: (isActive ? Colors.green : Colors.grey).withOpacity(
                    0.2,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: loading
                    ? const AppShimmer(width: 40, height: 12, radius: 6)
                    : Text(
                        isActive ? 'Active' : '—',
                        style: GoogleFonts.inter(
                          fontSize: badgeFontSize,
                          color: isActive
                              ? Colors.green[800]
                              : colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              SizedBox(width: spacing),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.verified_rounded,
                      size: badgeFontSize + 4,
                      color: emailVerified
                          ? Colors.blueAccent
                          : colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(width: 2),
                  loading
                      ? const AppShimmer(width: 88, height: 12, radius: 6)
                      : Text(
                          emailVerified ? 'Email Verified' : '—',
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
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EditAdminProfileScreen(initialProfile: profile),
                      ),
                    );
                    if (changed == true) {
                      await onUpdated?.call();
                    }
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
                        'Edit Profile',
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
                  onTap: () async {
                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UpdatePasswordScreen(),
                      ),
                    );
                    if (changed == true) {
                      await onUpdated?.call();
                    }
                  },
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        'Update Password',
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
