// components/profile/profile_screen.dart
import 'package:open_vts/core/utils/app_cancellation.dart';
import 'package:open_vts/shared/models/admin_profile.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/shared/widgets/profile_info_boxes.dart';
import 'package:open_vts/features/user/presentation/layout/app_layout.dart';
import 'package:open_vts/features/user/presentation/screens/profile/widget/profile_setting_box.dart';
import 'package:open_vts/features/user/presentation/screens/profile/widget/profile_verification_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/user/di/user_profile_access_providers.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  AdminProfile? _profile;
  bool _loadingProfile = false;
  bool _profileErrorShown = false;
  AppCancellationHandle? _profileCancellationHandle;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _profileCancellationHandle?.cancel('ProfileScreen disposed');
    super.dispose();
  }

  Future<void> _loadProfile() async {
    _profileCancellationHandle?.cancel('Reload profile');
    final token = AppCancellationHandle();
    _profileCancellationHandle = token;

    if (!mounted) return;
    updateLocalUiState(this, () => _loadingProfile = true);

    try {
      final res = await ref.read(userProfileAccessProvider).getMyProfile(cancelToken: token);
      if (!mounted || token.isCancelled) return;

      res.when(
        success: (profile) {
          if (!mounted) return;
          updateLocalUiState(this, () {
            _profile = profile;
            _loadingProfile = false;
            _profileErrorShown = false;
          });
        },
        failure: (error) {
          if (!mounted) return;
          updateLocalUiState(this, () {
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
      updateLocalUiState(this, () {
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
                    (!_profile!.emailVerified ||
                        !_profile!.phoneVerified))) ...[
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
