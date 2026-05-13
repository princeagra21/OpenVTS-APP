import 'package:open_vts/core/theme/app_fonts.dart';
// components/admin/update_password_screen.dart
import 'package:open_vts/shared/widgets/app_shimmer.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/superadmin/di/superadmin_core_gateway_providers.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class UpdatePasswordScreen extends ConsumerStatefulWidget {
  final String adminId;

  const UpdatePasswordScreen({super.key, required this.adminId});

  @override
  ConsumerState<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends ConsumerState<UpdatePasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _submitting = false;
  bool _snackShown = false;

  // Shared InputDecoration - same as your ApiConfigSettingsScreen
  InputDecoration _minimalInputDecoration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      hintText: '',
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIcon: const SizedBox(width: 12), // spacing for icon alignment
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
        borderSide: BorderSide(
          color: colorScheme.primary,
          width: 1.5,
        ), // subtle focus
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.withOpacity(0.6)),
      ),
    );
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _snackOnce(String msg) {
    if (!mounted || _snackShown) return;
    _snackShown = true;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    if (_submitting) return;
    _snackShown = false;

    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.trim().isEmpty) {
      _snackOnce('Please enter a new password.');
      return;
    }
    if (confirmPassword.trim().isEmpty) {
      _snackOnce('Please confirm your password.');
      return;
    }
    if (newPassword != confirmPassword) {
      _snackOnce("Passwords don't match.");
      return;
    }

    updateLocalUiState(this, () => _submitting = true);

    try {
      final res = await ref.read(updateSuperadminPasswordGatewayUseCaseProvider)(adminId: widget.adminId, newPassword: newPassword, confirmPassword: confirmPassword);

      if (!mounted) return;

      if (res.isSuccess) {
        _snackOnce('Password updated');
        Navigator.pop(context, true);
        return;
      }
      _snackOnce("Couldn't update password.");
    } catch (_) {
      if (!mounted) return;
      _snackOnce("Couldn't update password.");
    } finally {
      if (mounted) updateLocalUiState(this, () => _submitting = false);
    }
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
              // Top Row: Title + Close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Update Password",
                    style: AppFonts.roboto(
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
                "Securely update your account password",
                style: AppFonts.roboto(
                  fontSize: labelSize - 2,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),

              const SizedBox(height: 32),

              // New Password Field
              TextField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                style: AppFonts.roboto(
                  color: colorScheme.onSurface,
                  fontSize: AdaptiveUtils.getTitleFontSize(
                    w,
                  ), // matches API screen
                ),
                decoration: _minimalInputDecoration(context).copyWith(
                  hintText: "New Password",
                  hintStyle: AppFonts.roboto(
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
                    onPressed: () => updateLocalUiState(this, () => _obscureNew = !_obscureNew),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Confirm Password Field
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                style: AppFonts.roboto(
                  color: colorScheme.onSurface,
                  fontSize: AdaptiveUtils.getTitleFontSize(w),
                ),
                decoration: _minimalInputDecoration(context).copyWith(
                  hintText: "Confirm Password",
                  hintStyle: AppFonts.roboto(
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
                        updateLocalUiState(this, () => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Update Button - matches your API screen style
              GestureDetector(
                onTap: _submitting ? null : _submit,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: _submitting
                        ? const AppShimmer(width: 18, height: 18, radius: 9)
                        : Text(
                            "Update Password",
                            style: AppFonts.roboto(
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
