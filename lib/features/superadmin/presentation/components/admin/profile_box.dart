import 'package:open_vts/shared/models/admin_profile.dart';
import 'package:open_vts/shared/widgets/app_shimmer.dart';
import 'package:open_vts/features/superadmin/presentation/components/admin/profile_tab/edit_admin_profile_screen.dart';
import 'package:open_vts/features/superadmin/presentation/components/admin/profile_tab/update_password_screen.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/superadmin/di/superadmin_core_gateway_providers.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class ProfileBox extends ConsumerStatefulWidget {
  final String adminId;
  final VoidCallback? onProfileUpdated;

  const ProfileBox({super.key, required this.adminId, this.onProfileUpdated});

  @override
  ConsumerState<ProfileBox> createState() => _ProfileBoxState();
}

class _ProfileBoxState extends ConsumerState<ProfileBox> {
  AdminProfile? _profile;
  bool _active = true;
  bool _loading = false;
  bool _submittingStatus = false;
  bool _snackShown = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _snackOnce(String msg) {
    if (!mounted || _snackShown) return;
    _snackShown = true;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool _hasExplicitStatus(AdminProfile p) {
    final d = p.data;
    return d.containsKey('isActive') ||
        d.containsKey('active') ||
        d.containsKey('is_active') ||
        d.containsKey('status') ||
        d.containsKey('state');
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    updateLocalUiState(this, () => _loading = true);

    try {
      final res = await ref.read(getSuperadminAdminGatewayUseCaseProvider).getAdminProfile(widget.adminId);
      if (!mounted) return;

      res.when(
        success: (profile) {
          if (!mounted || profile is! AdminProfile) return;
          updateLocalUiState(this, () {
            _profile = profile;
            if (_hasExplicitStatus(profile)) {
              _active = profile.isActive;
            }
            _loading = false;
          });
        },
        failure: (err) {
          if (!mounted) return;
          updateLocalUiState(this, () => _loading = false);
          final msg = "Couldn't load admin profile.";
          _snackOnce(msg);
        },
      );
    } catch (_) {
      if (!mounted) return;
      updateLocalUiState(this, () => _loading = false);
      _snackOnce("Couldn't load admin profile.");
    }
  }

  Future<void> _toggleStatus(bool value) async {
    if (_submittingStatus) return;
    _snackShown = false;

    final prev = _active;
    updateLocalUiState(this, () {
      _active = value;
      _submittingStatus = true;
    });

    try {
      final res = await ref.read(getSuperadminAdminGatewayUseCaseProvider).updateAdminStatus(widget.adminId, value);
      if (!mounted) return;

      res.when(
        success: (_) {
          if (!mounted) return;
          updateLocalUiState(this, () => _submittingStatus = false);
        },
        failure: (err) {
          if (!mounted) return;
          updateLocalUiState(this, () {
            _active = prev;
            _submittingStatus = false;
          });
          final msg = "Couldn't update status.";
          _snackOnce(msg);
        },
      );
    } catch (_) {
      if (!mounted) return;
      updateLocalUiState(this, () {
        _active = prev;
        _submittingStatus = false;
      });
      _snackOnce("Couldn't update status.");
    }
  }

  String _display(String? value, {String fallback = '-'}) {
    if (value == null) return fallback;
    final text = value.trim();
    return text.isEmpty ? fallback : text;
  }

  String _initials(String name, String username) {
    final source = name == '-' ? username : name;
    if (source == '-') return '--';
    final clean = source.replaceAll('@', ' ').trim();
    final parts = clean
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '--';
    final out = parts.take(2).map((e) => e[0]).join();
    return out.toUpperCase();
  }

  String _usernameLabel(String username) {
    if (username == '-') return '-';
    return username.startsWith('@') ? username : '@$username';
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

    final displayName = _display(
      _profile?.fullName,
      fallback: _display(_profile?.username),
    );
    final displayUsername = _usernameLabel(_display(_profile?.username));
    final roleLabel = _display(_profile?.roleName);
    final isVerified = _profile?.isVerified == true;
    final statusLabel = _active ? 'Active' : 'Inactive';

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
                child: _loading && _profile == null
                    ? AppShimmer(
                        width: avatarRadius * 1.2,
                        height: avatarRadius * 0.6,
                        radius: 8,
                      )
                    : Text(
                        _initials(displayName, displayUsername),
                        style: AppFonts.roboto(
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
                          child: _loading && _profile == null
                              ? AppShimmer(
                                  width: double.infinity,
                                  height: 18,
                                  radius: 8,
                                )
                              : Text(
                                  displayName,
                                  style: AppFonts.roboto(
                                    fontSize: nameFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
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
                          child: _loading && _profile == null
                              ? AppShimmer(
                                  width: 40,
                                  height: badgeFontSize + 4,
                                  radius: 8,
                                )
                              : Text(
                                  roleLabel,
                                  style: AppFonts.roboto(
                                    color: colorScheme.onPrimary,
                                    fontSize: badgeFontSize,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing / 2),
                    _loading && _profile == null
                        ? const AppShimmer(width: 120, height: 14, radius: 8)
                        : Text(
                            displayUsername,
                            style: AppFonts.roboto(
                              fontSize: usernameFontSize,
                              color: colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ],
                ),
              ),
              SizedBox(width: largeSpacing),
              Column(
                children: [
                  Transform.scale(
                    scale: 0.75,
                    child: Switch(
                      value: _active,
                      onChanged: (_submittingStatus || _loading)
                          ? null
                          : _toggleStatus,
                      activeThumbColor: colorScheme.onPrimary,
                      activeTrackColor: colorScheme.primary,
                      inactiveThumbColor: colorScheme.onPrimary,
                      inactiveTrackColor: colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  Text(
                    "Status",
                    style: AppFonts.roboto(
                      fontSize: badgeFontSize,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
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
                  color: _active
                      ? Colors.green.withOpacity(0.2)
                      : colorScheme.error.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: AppFonts.roboto(
                    fontSize: badgeFontSize,
                    color: _active ? Colors.green[800] : colorScheme.error,
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
                  color: isVerified
                      ? colorScheme.primary
                      : colorScheme.outline.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isVerified ? "Email Verified" : "Email Not Verified",
                  style: AppFonts.roboto(
                    color: isVerified
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface.withOpacity(0.8),
                    fontSize: badgeFontSize,
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
                  onTap: () {
                    Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EditAdminProfileScreen(adminId: widget.adminId),
                      ),
                    ).then((updated) {
                      if (updated == true) {
                        widget.onProfileUpdated?.call();
                        _loadProfile();
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
                        style: AppFonts.roboto(
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
                        builder: (_) =>
                            UpdatePasswordScreen(adminId: widget.adminId),
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
                        style: AppFonts.roboto(
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
