// components/profile/profile_box.dart
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/profile_tab/edit_admin_profile_screen.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/profile_tab/update_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/adaptive_utils.dart';

class ProfileBox extends StatefulWidget {
  final String adminId;
  final VoidCallback? onProfileUpdated;

  const ProfileBox({super.key, required this.adminId, this.onProfileUpdated});

  @override
  State<ProfileBox> createState() => _ProfileBoxState();
}

class _ProfileBoxState extends State<ProfileBox> {
  bool _active = true; // fallback-first
  bool _submittingStatus = false;
  bool _snackShown = false;

  CancelToken? _loadToken;
  CancelToken? _statusToken;

  ApiClient? _api;
  SuperadminRepository? _repo;

  @override
  void initState() {
    super.initState();
    _loadInitialStatus();
  }

  @override
  void dispose() {
    _statusToken?.cancel('dispose');
    _loadToken?.cancel('dispose');
    super.dispose();
  }

  void _ensureRepo() {
    if (_api != null) return;
    _api = ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo = SuperadminRepository(api: _api!);
  }

  void _snackOnce(String msg) {
    if (!mounted || _snackShown) return;
    _snackShown = true;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _loadInitialStatus() async {
    _ensureRepo();
    _loadToken?.cancel('reload');
    final token = CancelToken();
    _loadToken = token;

    try {
      final res = await _repo!.getAdminProfile(
        widget.adminId,
        cancelToken: token,
      );
      if (!mounted) return;
      if (res.isSuccess) {
        final p = res.data!;
        setState(() => _active = p.isActive);
      }
    } catch (_) {
      // Silent fallback.
    }
  }

  Future<void> _toggleStatus(bool value) async {
    if (_submittingStatus) return;
    _snackShown = false;

    final prev = _active;
    setState(() {
      _active = value; // optimistic
      _submittingStatus = true;
    });

    _ensureRepo();
    _statusToken?.cancel('new toggle');
    final token = CancelToken();
    _statusToken = token;

    try {
      final res = await _repo!.updateAdminStatus(
        widget.adminId,
        value,
        cancelToken: token,
      );
      if (!mounted) return;

      res.when(
        success: (_) {
          if (!mounted) return;
          setState(() => _submittingStatus = false);
        },
        failure: (err) {
          if (!mounted) return;
          setState(() {
            _active = prev; // revert
            _submittingStatus = false;
          });
          final msg =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized.'
              : "Couldn't update status.";
          _snackOnce(msg);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _active = prev; // revert
        _submittingStatus = false;
      });
      _snackOnce("Couldn't update status.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;

    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double avatarRadius = AdaptiveUtils.getAvatarSize(screenWidth) / 2;
    final double avatarFontSize = AdaptiveUtils.getFsAvatarFontSize(screenWidth);
    final double nameFontSize =
        AdaptiveUtils.getSubtitleFontSize(screenWidth) - 4;
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
          // Top row: Avatar + Name + Status
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: colorScheme.primary,
                child: Text(
                  "MS",
                  style: GoogleFonts.inter(
                    color: colorScheme.onPrimary,
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

              // Status switch
              Column(
                children: [
                  Transform.scale(
                    scale: 0.75,
                    child: Switch(
                      value: _active,
                      onChanged: _submittingStatus ? null : _toggleStatus,
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
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Email Verified",
                  style: GoogleFonts.inter(
                    color: colorScheme.onPrimary,
                    fontSize: badgeFontSize,
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
                child: GestureDetector(
                  onTap: () {
                    Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EditAdminProfileScreen(adminId: widget.adminId),
                      ),
                    ).then((updated) {
                      if (updated == true) widget.onProfileUpdated?.call();
                    });
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

