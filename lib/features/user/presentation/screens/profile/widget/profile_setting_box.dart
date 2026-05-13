import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_components.dart';
import 'package:open_vts/core/theme/open_vts_theme.dart';
// components/profile/profile_box.dart
import 'package:open_vts/shared/models/admin_profile.dart';
import 'package:open_vts/shared/widgets/app_shimmer.dart';
import 'package:open_vts/features/user/presentation/screens/profile/widget/edit_admin_profile_screen.dart';
import 'package:open_vts/features/user/presentation/screens/profile/widget/update_password_screen.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';

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

    return OpenVtsCard(
      padding: EdgeInsets.all(padding + 8),
      borderRadius: BorderRadius.circular(25),
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
                        style: AppFonts.inter(
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
                                  style: AppFonts.inter(
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
                                  style: AppFonts.inter(
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
                            style: AppFonts.inter(
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
              loading
                  ? const AppShimmer(width: 64, height: 24, radius: 12)
                  : OpenVtsStatusChip(
                      label: isActive ? 'Active' : 'Inactive',
                      tone: isActive
                          ? OpenVtsStatusTone.success
                          : OpenVtsStatusTone.neutral,
                      compact: true,
                    ),
              SizedBox(width: spacing),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: OpenVtsColors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.verified_rounded,
                      size: badgeFontSize + 4,
                      color: emailVerified
                          ? OpenVtsColors.brandInkSoft
                          : colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(width: 2),
                  loading
                      ? const AppShimmer(width: 88, height: 12, radius: 6)
                      : Text(
                          emailVerified ? 'Email Verified' : '—',
                          style: AppFonts.inter(
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
                child: OpenVtsButton(
                  label: 'Edit Profile',
                  variant: OpenVtsButtonVariant.secondary,
                  size: OpenVtsButtonSize.small,
                  onPressed: () async {
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
                ),
              ),
              SizedBox(width: spacing + 4),
              Expanded(
                child: OpenVtsButton(
                  label: 'Update Password',
                  size: OpenVtsButtonSize.small,
                  onPressed: () async {
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
