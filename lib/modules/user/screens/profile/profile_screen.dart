// components/profile/profile_screen.dart
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/core/debug/auth_profile_smoke_test.dart';
import 'package:fleet_stack/core/models/profile.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/user_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/user/screens/profile/widget/profile_info_boxes.dart';
import 'package:fleet_stack/modules/user/screens/profile/widget/profile_setting_box.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Profile? _profile;
  bool _loadingProfile = false;
  bool _profileErrorShown = false;
  CancelToken? _profileCancelToken;

  ApiClient? _api;
  UserRepository? _userRepo;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _profileCancelToken?.cancel('ProfileScreen disposed');
    super.dispose();
  }

  Future<void> _loadProfile() async {
    _profileCancelToken?.cancel('Reload profile');
    final token = CancelToken();
    _profileCancelToken = token;

    if (!mounted) return;
    setState(() => _loadingProfile = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _userRepo ??= UserRepository(api: _api!);

      final res = await _userRepo!.getProfile(cancelToken: token);
      if (!mounted) return;

      res.when(
        success: (profile) {
          if (!mounted) return;
          setState(() {
            _profile = profile;
            _loadingProfile = false;
            _profileErrorShown = false;
          });
        },
        failure: (err) {
          if (!mounted) return;
          setState(() => _loadingProfile = false);

          if (_profileErrorShown) return;

          _profileErrorShown = true;
          final msg = _friendlyProfileError(err);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingProfile = false);
      if (_profileErrorShown) return;
      _profileErrorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't load profile. Showing saved info."),
        ),
      );
    }
  }

  String _friendlyProfileError(Object err) {
    if (err is ApiException) {
      final sc = err.statusCode;
      if (sc == 401 || sc == 403) return 'Please log in again';
      return "Couldn't load profile. Showing saved info.";
    }
    return "Couldn't load profile. Showing saved info.";
  }

  String _computeInitials(String nameFallback) {
    final name = nameFallback.trim();
    if (name.isEmpty) return 'FS';
    final parts = name
        .split(RegExp(r'\\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    final take = name.length >= 2 ? 2 : name.length;
    return name.substring(0, take).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;

    const fallbackName = 'Muhammad Sani';
    const fallbackRole = 'Admin';
    const fallbackUsername = '@danmasana';

    final displayName = (_profile?.name.isNotEmpty == true)
        ? _profile!.name
        : fallbackName;
    final roleLabel = (_profile?.role.isNotEmpty == true)
        ? _profile!.role
        : fallbackRole;
    final username = (_profile?.username.isNotEmpty == true)
        ? _profile!.username.startsWith('@')
              ? _profile!.username
              : '@${_profile!.username}'
        : fallbackUsername;
    final initials = _computeInitials(displayName);

    return AppLayout(
      title: "USER",
      subtitle: "Profile",
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 8,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          children: [
            ProfileSettingBox(
              displayName: displayName,
              username: username,
              roleLabel: roleLabel,
              initials: initials,
              loading: _loadingProfile,
            ),
            SizedBox(height: 24),
            ProfileInfoBoxes(),
            SizedBox(height: 24),
            //ProfileCompanyBox(),
            // SizedBox(height: 24,),
            //  ProfileRecentActivityBox(),
            //  SizedBox(height: 24,),
            //  ProfileDeleteBox(onDelete: () { },),
            SizedBox(height: 24),
            if (kDebugMode) ...[
              const DebugAuthProfileSmokeTestButton(),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}
