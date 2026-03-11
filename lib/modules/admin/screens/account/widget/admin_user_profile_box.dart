import 'package:fleet_stack/core/models/admin_user_details.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/screens/account/widget/admin_user_details_ui.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminUserProfileBox extends StatelessWidget {
  final AdminUserDetails? details;
  final bool loading;

  const AdminUserProfileBox({
    super.key,
    required this.details,
    required this.loading,
  });

  String _initials(String name, String username) {
    final source = name == '—' ? username : name;
    if (source == '—') return '--';
    final clean = source.replaceAll('@', ' ').trim();
    final parts = clean
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '--';
    return parts.take(2).map((e) => e[0]).join().toUpperCase();
  }

  String _usernameLabel(String username) {
    if (username == '—') return '—';
    return username.startsWith('@') ? username : '@$username';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
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
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth);
    final double largeSpacing = padding;

    final displayName = safeText(
      details?.fullName,
      fallback: safeText(details?.username),
    );
    final displayUsername = _usernameLabel(safeText(details?.username));
    final roleLabel = safeText(details?.summary.roleLabel);
    final statusLabel = safeText(details?.statusLabel);
    final emailVerified = details?.emailVerified == true;
    final phoneVerified = details?.mobileVerified == true;

    return Container(
      padding: EdgeInsets.all(padding + 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: colorScheme.primary,
                child: loading && details == null
                    ? AppShimmer(
                        width: avatarRadius * 1.2,
                        height: avatarRadius * 0.6,
                        radius: 8,
                      )
                    : Text(
                        _initials(displayName, displayUsername),
                        style: GoogleFonts.inter(
                          color: colorScheme.onPrimary,
                          fontSize: avatarFontSize,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
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
                          child: loading && details == null
                              ? const AppShimmer(
                                  width: double.infinity,
                                  height: 18,
                                  radius: 8,
                                )
                              : Text(
                                  displayName,
                                  style: GoogleFonts.inter(
                                    fontSize: nameFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
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
                          child: loading && details == null
                              ? AppShimmer(
                                  width: 56,
                                  height: badgeFontSize + 4,
                                  radius: 8,
                                )
                              : Text(
                                  roleLabel,
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
                    loading && details == null
                        ? const AppShimmer(width: 140, height: 14, radius: 8)
                        : Text(
                            displayUsername,
                            style: GoogleFonts.inter(
                              fontSize: usernameFontSize,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: largeSpacing + 4),
          Wrap(
            spacing: spacing + 4,
            runSpacing: spacing + 4,
            children: [
              _chip(
                context,
                label: statusLabel,
                bg:
                    statusLabel.toLowerCase().contains('active') ||
                        statusLabel.toLowerCase().contains('verify')
                    ? Colors.green.withValues(alpha: 0.2)
                    : colorScheme.error.withValues(alpha: 0.16),
                fg:
                    statusLabel.toLowerCase().contains('active') ||
                        statusLabel.toLowerCase().contains('verify')
                    ? Colors.green.shade800
                    : colorScheme.error,
                fontSize: badgeFontSize,
              ),
              _chip(
                context,
                label: emailVerified ? 'Email Verified' : 'Email Not Verified',
                bg: emailVerified
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.2),
                fg: emailVerified
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface.withValues(alpha: 0.8),
                fontSize: badgeFontSize,
              ),
              _chip(
                context,
                label: phoneVerified ? 'Phone Verified' : 'Phone Not Verified',
                bg: phoneVerified
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.2),
                fg: phoneVerified
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface.withValues(alpha: 0.8),
                fontSize: badgeFontSize,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required Color bg,
    required Color fg,
    required double fontSize,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: fontSize,
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
