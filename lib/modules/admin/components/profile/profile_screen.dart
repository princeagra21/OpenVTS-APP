// components/profile/profile_screen.dart
import 'package:dio/dio.dart';
import 'package:open_vts/app/app_container.dart';
import 'package:open_vts/core/config/app_config.dart';
import 'package:open_vts/core/models/admin_profile.dart';
import 'package:open_vts/core/network/api_exception.dart';
import 'package:open_vts/core/repositories/admin_profile_repository.dart';
import 'package:open_vts/core/storage/token_storage.dart';
import 'package:open_vts/modules/admin/components/profile/widget/profile_setting_box.dart';
import 'package:open_vts/modules/admin/components/profile/widget/profile_verification_box.dart';
import 'package:open_vts/modules/admin/layout/app_layout.dart';
import 'package:open_vts/shared/profile/widgets/profile_info_boxes.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
  CancelToken? _loadToken;
  AdminProfileRepository? _repo;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _loadToken?.cancel('Admin profile disposed');
    super.dispose();
  }

  Future<void> _loadProfile() async {
    _loadToken?.cancel('Reload profile');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      _repo ??= AppContainer.instance.adminProfileRepository;

      final res = await _repo!.getMyProfile(cancelToken: token);
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
          setState(() {
            _profile = profile;
            _loading = false;
            _errorShown = false;
          });
        },
        failure: (error) {
          if (kDebugMode) {
            final status = error is ApiException ? error.statusCode : null;
            AppLogger.debug(
              '[Admin Profile] GET /admin/profile status=${status ?? 'error'}',
            );
          }
          if (!mounted) return;
          setState(() {
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
      setState(() {
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
