import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UpdateUserPasswordScreen extends StatefulWidget {
  final String userId;

  const UpdateUserPasswordScreen({super.key, required this.userId});

  @override
  State<UpdateUserPasswordScreen> createState() => _UpdateUserPasswordScreenState();
}

class _UpdateUserPasswordScreenState extends State<UpdateUserPasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _saving = false;
  bool _submitErrorShown = false;
  DateTime? _lastSubmitAt;
  CancelToken? _submitToken;
  ApiClient? _api;

  @override
  void dispose() {
    _submitToken?.cancel('Update user password disposed');
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

    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.trim().isEmpty || confirmPassword.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill both password fields.')),
      );
      return;
    }
    if (newPassword != confirmPassword) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _saving = true;
      _submitErrorShown = false;
    });

    _submitToken?.cancel('New update user password submit started');
    final token = CancelToken();
    _submitToken = token;

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );

      final res = await _api!.post(
        '/admin/updateuserpassword/${widget.userId}',
        data: <String, dynamic>{'newPassword': newPassword},
        cancelToken: token,
      );
      if (!mounted) return;

      res.when(
        success: (_) {
          if (!mounted) return;
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated')),
          );
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg)),
          );
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
                'Set a new password for this user',
                style: GoogleFonts.inter(
                  fontSize: labelSize - 2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'New Password',
                style: GoogleFonts.inter(
                  fontSize: labelSize - 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                decoration: _minimalInputDecoration(context).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Confirm Password',
                style: GoogleFonts.inter(
                  fontSize: labelSize - 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: _minimalInputDecoration(context).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              const Spacer(),
              if (_saving)
                const AppShimmer(
                  width: double.infinity,
                  height: 48,
                  radius: 16,
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _submitPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Update Password',
                      style: GoogleFonts.inter(
                        fontSize: labelSize - 1,
                        fontWeight: FontWeight.w700,
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
