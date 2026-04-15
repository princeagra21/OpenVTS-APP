// components/admin/update_password_screen.dart
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_profile_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _saving = false;
  bool _submitErrorShown = false;
  DateTime? _lastSubmitAt;
  CancelToken? _submitToken;
  ApiClient? _api;
  AdminProfileRepository? _repo;

  @override
  void dispose() {
    _submitToken?.cancel('Update password disposed');
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitPassword() async {
    if (_saving) return;
    final now = DateTime.now();
    if (_lastSubmitAt != null &&
        now.difference(_lastSubmitAt!).inMilliseconds < 800) {
      return;
    }
    _lastSubmitAt = now;

    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (currentPassword.trim().isEmpty ||
        newPassword.trim().isEmpty ||
        confirmPassword.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all password fields.')),
      );
      return;
    }
    if (newPassword != confirmPassword) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match.')));
      return;
    }

    if (!mounted) return;
    setState(() {
      _saving = true;
      _submitErrorShown = false;
    });

    _submitToken?.cancel('New update password submit started');
    final token = CancelToken();
    _submitToken = token;

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= AdminProfileRepository(api: _api!);

      final result = await _repo!.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        cancelToken: token,
      );
      if (!mounted) return;

      result.when(
        success: (_) {
          if (!mounted) return;
          setState(() => _saving = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Password updated')));
          Navigator.pop(context, true);
        },
        failure: (error) {
          if (!mounted) return;
          setState(() => _saving = false);
          if (_submitErrorShown) return;
          _submitErrorShown = true;

          String msg = 'Could not update password.';
          if (error is ApiException) {
            if (error.statusCode == 401 || error.statusCode == 403) {
              msg = 'Not authorized to update password.';
            } else if (error.message.trim().isNotEmpty) {
              msg = error.message;
            }
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      if (_submitErrorShown) return;
      _submitErrorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update password.')),
      );
    }
  }

  InputDecoration _minimalInputDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      hintText: '',
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIcon: const SizedBox(width: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.withOpacity(0.6)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w) + 6;
    final double titleSize = AdaptiveUtils.getSubtitleFontSize(w);
    final double labelSize = AdaptiveUtils.getTitleFontSize(w);

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Update Password',
                    style: GoogleFonts.inter(
                      fontSize: titleSize + 2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      size: 28,
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Securely update your account password',
                style: GoogleFonts.inter(
                  fontSize: labelSize - 2,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                style: GoogleFonts.inter(
                  color: colorScheme.onSurface,
                  fontSize: AdaptiveUtils.getTitleFontSize(w),
                ),
                decoration: _minimalInputDecoration(context).copyWith(
                  hintText: 'Current Password',
                  hintStyle: GoogleFonts.inter(
                    color: colorScheme.onSurface.withOpacity(0.5),
                    fontSize: AdaptiveUtils.getTitleFontSize(w),
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 12),
                    child: Icon(
                      Icons.lock_outline,
                      color: colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () => setState(
                      () => _obscureCurrent = !_obscureCurrent,
                    ),
                    icon: Icon(
                      _obscureCurrent
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                style: GoogleFonts.inter(
                  color: colorScheme.onSurface,
                  fontSize: AdaptiveUtils.getTitleFontSize(w),
                ),
                decoration: _minimalInputDecoration(context).copyWith(
                  hintText: 'New Password',
                  hintStyle: GoogleFonts.inter(
                    color: colorScheme.onSurface.withOpacity(0.5),
                    fontSize: AdaptiveUtils.getTitleFontSize(w),
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 12),
                    child: Icon(
                      Icons.lock_outline,
                      color: colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                style: GoogleFonts.inter(
                  color: colorScheme.onSurface,
                  fontSize: AdaptiveUtils.getTitleFontSize(w),
                ),
                decoration: _minimalInputDecoration(context).copyWith(
                  hintText: 'Confirm Password',
                  hintStyle: GoogleFonts.inter(
                    color: colorScheme.onSurface.withOpacity(0.5),
                    fontSize: AdaptiveUtils.getTitleFontSize(w),
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 12),
                    child: Icon(
                      Icons.lock_outline,
                      color: colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _submitPassword,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: _saving
                        ? const AppShimmer(width: 120, height: 18, radius: 8)
                        : Text(
                            'Update Password',
                            style: GoogleFonts.inter(
                              fontSize: labelSize,
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
