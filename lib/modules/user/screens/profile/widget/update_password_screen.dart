import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/user_profile_repository.dart';
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
  bool _errorShown = false;

  ApiClient? _api;
  UserProfileRepository? _repo;
  CancelToken? _saveToken;

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

  UserProfileRepository _repoOrCreate() {
    _api ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= UserProfileRepository(api: _api!);
    return _repo!;
  }

  Future<void> _savePassword() async {
    if (_saving) return;

    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All password fields are required.')),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password and confirm password must match.'),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _saving = true;
      _errorShown = false;
    });

    _saveToken?.cancel('Restart password update');
    final token = CancelToken();
    _saveToken = token;

    try {
      final res = await _repoOrCreate().updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        cancelToken: token,
      );
      if (!mounted || token.isCancelled) return;

      res.when(
        success: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated.')),
          );
          Navigator.pop(context, true);
        },
        failure: (error) {
          if (!mounted) return;
          setState(() => _saving = false);
          var msg = "Couldn't update password.";
          if (error is ApiException && error.message.trim().isNotEmpty) {
            msg = error.message;
          }
          if (_errorShown) return;
          _errorShown = true;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      if (_errorShown) return;
      _errorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't update password.")),
      );
    }
  }

  Widget _passwordField({
    required BuildContext context,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required String hint,
    required double width,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.inter(
        color: colorScheme.onSurface,
        fontSize: AdaptiveUtils.getTitleFontSize(width),
      ),
      decoration: _minimalInputDecoration(context).copyWith(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: colorScheme.onSurface.withOpacity(0.5),
          fontSize: AdaptiveUtils.getTitleFontSize(width),
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
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _saveToken?.cancel('Update password disposed');
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w) + 6;
    final double titleSize = AdaptiveUtils.getSubtitleFontSize(w);
    final double labelSize = AdaptiveUtils.getTitleFontSize(w);

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _passwordField(
                        context: context,
                        controller: _currentPasswordController,
                        obscure: _obscureCurrent,
                        onToggle: () =>
                            setState(() => _obscureCurrent = !_obscureCurrent),
                        hint: 'Current Password',
                        width: w,
                      ),
                      const SizedBox(height: 16),
                      _passwordField(
                        context: context,
                        controller: _newPasswordController,
                        obscure: _obscureNew,
                        onToggle: () =>
                            setState(() => _obscureNew = !_obscureNew),
                        hint: 'New Password',
                        width: w,
                      ),
                      const SizedBox(height: 16),
                      _passwordField(
                        context: context,
                        controller: _confirmPasswordController,
                        obscure: _obscureConfirm,
                        onToggle: () => setState(
                          () => _obscureConfirm = !_obscureConfirm,
                        ),
                        hint: 'Confirm Password',
                        width: w,
                      ),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: _saving ? null : _savePassword,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: _saving
                                ? const AppShimmer(
                                    width: 120,
                                    height: 16,
                                    radius: 8,
                                  )
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
            ],
          ),
        ),
      ),
    );
  }
}
