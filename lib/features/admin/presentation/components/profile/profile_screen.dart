// components/profile/profile_screen.dart
import 'package:open_vts/shared/models/admin_profile.dart';
import 'package:open_vts/features/admin/presentation/controllers/admin_account_error_presenter.dart';
import 'package:open_vts/features/admin/presentation/components/profile/widget/profile_setting_box.dart';
import 'package:open_vts/features/admin/presentation/components/profile/widget/profile_verification_box.dart';
import 'package:open_vts/features/admin/presentation/layout/app_layout.dart';
import 'package:open_vts/shared/widgets/profile_info_boxes.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/admin/di/admin_account_providers.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  /// Endpoints used (API reference documentation + Postman):
  /// - GET /admin/profile
  ///   keys: data.data.name, username, email, mobilePrefix, mobileNumber,
  ///         isEmailVerified, createdAt, updatedAt, loginType/role, credits
  /// - PATCH /admin/profile
  ///   body keys: name, email, mobilePrefix, mobileNumber
  /// - POST /admin/updatepassword
  ///   body keys: currentPassword, newPassword (confirmPassword optional)
  /// - POST /admin/profile/verify/email/request
  /// - POST /admin/profile/verify/email/confirm     body: { otp }
  /// - POST /admin/profile/verify/whatsapp/request
  /// - POST /admin/profile/verify/whatsapp/confirm  body: { otp }
  AdminProfile? _profile;
  bool _loading = false;
  bool _errorShown = false;
  late final _repo = ref.read(adminAccountCommandControllerProvider);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadProfile() async {

    if (!mounted) return;
    updateLocalUiState(this, () => _loading = true);

    try {
      final res = await _repo.getMyProfile();
      if (!mounted) return;

      res.when(
        success: (profile) {
          if (kDebugMode) {
            AppLogger.debug(
              '[Admin Profile] GET /admin/profile status=2xx '
              'name=${profile.fullName} username=${profile.username}',
            );
          }
          if (!mounted) return;
          updateLocalUiState(this, () {
            _profile = profile;
            _loading = false;
            _errorShown = false;
          });
        },
        failure: (error) {
          if (kDebugMode) {
            final status = adminAccountStatusCode(error);
            AppLogger.debug(
              '[Admin Profile] GET /admin/profile status=${status ?? 'error'}',
            );
          }
          if (!mounted) return;
          updateLocalUiState(this, () {
            _profile = null;
            _loading = false;
          });
          if (_errorShown) return;
          _errorShown = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Couldn't load profile.")),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      updateLocalUiState(this, () {
        _profile = null;
        _loading = false;
      });
      if (_errorShown) return;
      _errorShown = true;
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
              loading: _loading,
              onUpdated: _loadProfile,
            ),
            const SizedBox(height: 24),
            ProfileInfoBoxes(profile: _profile, loading: _loading),
            if (_loading ||
                (_profile != null &&
                    (!_profile!.emailVerified ||
                        !_profile!.phoneVerified))) ...[
              const SizedBox(height: 24),
              ProfileVerificationBox(
                profile: _profile,
                loading: _loading,
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
