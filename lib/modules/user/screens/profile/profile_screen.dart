// components/profile/profile_screen.dart
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_profile.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/repositories/user_profile_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/user/layout/app_layout.dart';
import 'package:fleet_stack/modules/user/screens/profile/widget/profile_info_boxes.dart';
import 'package:fleet_stack/modules/user/screens/profile/widget/profile_setting_box.dart';
import 'package:fleet_stack/modules/user/screens/profile/widget/profile_verification_box.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AdminProfile? _profile;
  bool _loadingProfile = false;
  bool _profileErrorShown = false;
  CancelToken? _profileCancelToken;

  ApiClient? _api;
  UserProfileRepository? _userRepo;

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
      _userRepo ??= UserProfileRepository(api: _api!);

      final res = await _userRepo!.getMyProfile(cancelToken: token);
      if (!mounted || token.isCancelled) return;

      res.when(
        success: (profile) {
          if (!mounted) return;
          setState(() {
            _profile = profile;
            _loadingProfile = false;
            _profileErrorShown = false;
          });
        },
        failure: (error) {
          if (!mounted) return;
          setState(() {
            _profile = null;
            _loadingProfile = false;
          });
          if (_profileErrorShown) return;
          _profileErrorShown = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Couldn't load profile.")),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _profile = null;
        _loadingProfile = false;
      });
      if (_profileErrorShown) return;
      _profileErrorShown = true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't load profile.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;
    return AppLayout(
      title: 'Open VTS',
      subtitle: 'Profile',
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 8,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          children: [
            ProfileSettingBox(
              profile: _profile,
              loading: _loadingProfile,
              onUpdated: _loadProfile,
            ),
            const SizedBox(height: 24),
            ProfileInfoBoxes(profile: _profile, loading: _loadingProfile),
            if (_loadingProfile ||
                (_profile != null &&
                    (!_profile!.emailVerified || !_profile!.phoneVerified))) ...[
              const SizedBox(height: 24),
              ProfileVerificationBox(
                profile: _profile,
                loading: _loadingProfile,
                onVerified: _loadProfile,
              ),
            ],
            const SizedBox(height: 24),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
