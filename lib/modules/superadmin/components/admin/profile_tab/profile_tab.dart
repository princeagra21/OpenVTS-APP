// components/admin/profile_tab.dart
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_profile.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/profile_tab/widget/company_box.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/profile_tab/widget/delete_account_box.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/profile_tab/widget/info_grids.dart';
import 'package:flutter/material.dart';

class ProfileTab extends StatefulWidget {
  final String adminId;

  const ProfileTab({super.key, required this.adminId});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  AdminProfile? _profile;
  bool _loading = false;
  bool _errorShown = false;
  CancelToken? _token;

  ApiClient? _api;
  SuperadminRepository? _repo;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _token?.cancel('ProfileTab disposed');
    super.dispose();
  }

  Future<void> _loadProfile() async {
    _token?.cancel('Reload admin profile');
    final token = CancelToken();
    _token = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);

      final res = await _repo!.getAdminProfile(
        widget.adminId,
        cancelToken: token,
      );
      if (!mounted) return;

      res.when(
        success: (profile) {
          if (!mounted) return;
          setState(() {
            _profile = profile;
            _loading = false;
            _errorShown = false;
          });
        },
        failure: (err) {
          if (!mounted) return;
          setState(() => _loading = false);
          if (_errorShown) return;
          _errorShown = true;

          final msg =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to view admin profile.'
              : "Couldn't load admin profile. Showing fallback info.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (_errorShown) return;
      _errorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't load admin profile. Showing fallback info."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AdminInfoBoxes(profile: _profile),
        const SizedBox(height: 24),
        CompanyBox(profile: _profile, loading: _loading),
        const SizedBox(height: 24),
        DeleteAccountBox(adminId: widget.adminId),
      ],
    ); // Added CompanyBox below AdminInfoBoxes
  }
}
