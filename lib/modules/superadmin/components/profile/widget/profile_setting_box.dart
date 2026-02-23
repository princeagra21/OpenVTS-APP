import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/profile_tab/edit_admin_profile_screen.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/profile_tab/update_password_screen.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileSettingBox extends StatelessWidget {
  final String adminId;
  final String displayName;
  final String username;
  final String email;
  final String roleLabel;
  final String initials;
  final bool? isActive;
  final bool? isVerified;
  final bool loading;

  const ProfileSettingBox({
    super.key,
    this.adminId = '',
    this.displayName = '-',
    this.username = '-',
    this.email = '-',
    this.roleLabel = '-',
    this.initials = '--',
    this.isActive,
    this.isVerified,
    this.loading = false,
  });

  String _orDash(String value) {
    final text = value.trim();
    return text.isEmpty ? '-' : text;
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

    void openEditProfile() {
      final id = adminId.trim();
      if (id.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin ID is unavailable.')),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EditAdminProfileScreen(adminId: id)),
      );
    }

    void openUpdatePassword() {
      final id = adminId.trim();
      if (id.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin ID is unavailable.')),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => UpdatePasswordScreen(adminId: id)),
      );
    }

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
                        width: avatarRadius,
                        height: avatarRadius * 0.65,
                        radius: 10,
                      )
                    : Text(
                        _orDash(initials),
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
                        Expanded(
                          child: loading
                              ? const AppShimmer(
                                  width: double.infinity,
                                  height: 18,
                                  radius: 8,
                                )
                              : Text(
                                  _orDash(displayName),
                                  style: GoogleFonts.inter(
                                    fontSize: nameFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                        SizedBox(width: spacing),
                        loading
                            ? const AppShimmer(
                                width: 70,
                                height: 24,
                                radius: 12,
                              )
                            : Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: spacing + 4,
                                  vertical: spacing - 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _orDash(roleLabel),
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
                        ? const AppShimmer(width: 180, height: 16, radius: 8)
                        : Text(
                            _orDash(username),
                            style: GoogleFonts.inter(
                              fontSize: usernameFontSize,
                              color: colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: largeSpacing + 4),

          if (loading)
            const Row(
              children: [
                AppShimmer(width: 84, height: 24, radius: 12),
                SizedBox(width: 8),
                AppShimmer(width: 118, height: 24, radius: 12),
              ],
            )
          else
            Wrap(
              spacing: spacing + 4,
              runSpacing: 8,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing + 4,
                    vertical: spacing - 2,
                  ),
                  decoration: BoxDecoration(
                    color: (isActive == true)
                        ? Colors.green.withOpacity(0.2)
                        : colorScheme.surfaceVariant.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive == null
                        ? 'Status: -'
                        : (isActive! ? 'Active' : 'Inactive'),
                    style: GoogleFonts.inter(
                      fontSize: badgeFontSize,
                      color: (isActive == true)
                          ? Colors.green[800]
                          : colorScheme.onSurface.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing + 4,
                    vertical: spacing - 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _orDash(email) == '-' ? 'Email: -' : _orDash(email),
                    style: GoogleFonts.inter(
                      fontSize: badgeFontSize,
                      color: colorScheme.onSurface.withOpacity(0.85),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isVerified != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing + 4,
                      vertical: spacing - 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isVerified! ? 'Email Verified' : 'Email Unverified',
                      style: GoogleFonts.inter(
                        fontSize: badgeFontSize,
                        color: colorScheme.onSurface.withOpacity(0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),

          SizedBox(height: largeSpacing + 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: loading ? null : openEditProfile,
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
                      child: loading
                          ? const AppShimmer(width: 92, height: 14, radius: 8)
                          : Text(
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
                  onTap: loading ? null : openUpdatePassword,
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: loading
                          ? const AppShimmer(width: 122, height: 14, radius: 8)
                          : Text(
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
