import 'package:open_vts/shared/models/admin_profile.dart';
import 'package:open_vts/features/admin/presentation/controllers/admin_account_error_presenter.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/shared/widgets/app_shimmer.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/admin/di/admin_account_providers.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

enum _VerificationChannel { email, phone }

class ProfileVerificationBox extends ConsumerStatefulWidget {
  const ProfileVerificationBox({
    super.key,
    required this.profile,
    required this.loading,
    required this.onVerified,
  });

  final AdminProfile? profile;
  final bool loading;
  final Future<void> Function() onVerified;

  @override
  ConsumerState<ProfileVerificationBox> createState() => _ProfileVerificationBoxState();
}

class _ProfileVerificationBoxState extends ConsumerState<ProfileVerificationBox> {
  late final _repo = ref.read(adminAccountCommandControllerProvider);

  bool _sendingEmail = false;
  bool _sendingPhone = false;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _sendOtp(_VerificationChannel channel) async {
    if (channel == _VerificationChannel.email && _sendingEmail) return;
    if (channel == _VerificationChannel.phone && _sendingPhone) return;

    if (!mounted) return;
    updateLocalUiState(this, () {
      if (channel == _VerificationChannel.email) {
        _sendingEmail = true;
      } else {
        _sendingPhone = true;
      }
    });


    try {
      final Result<void, AppError> result = channel == _VerificationChannel.email
          ? await _repo.sendEmailOtp()
          : await _repo.sendPhoneOtp();

      if (!mounted) return;
      result.when(
        success: (_) async {
          if (!mounted) return;
          updateLocalUiState(this, () {
            if (channel == _VerificationChannel.email) {
              _sendingEmail = false;
            } else {
              _sendingPhone = false;
            }
          });

          final verified = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (_) => _OtpVerifySheet(
              title: channel == _VerificationChannel.email
                  ? 'Verify Email'
                  : 'Verify WhatsApp',
              onVerify: (code) {
                if (channel == _VerificationChannel.email) {
                  return _repo.verifyEmailOtp(code);
                }
                return _repo.verifyPhoneOtp(code);
              },
            ),
          );

          if (verified == true) {
            await widget.onVerified();
          }
        },
        failure: (error) {
          if (!mounted) return;
          updateLocalUiState(this, () {
            if (channel == _VerificationChannel.email) {
              _sendingEmail = false;
            } else {
              _sendingPhone = false;
            }
          });

          String msg = 'Could not send OTP.';
          if (adminAccountIsKnownFailure(error)) {
            if (adminAccountStatusCode(error) == 401 || adminAccountStatusCode(error) == 403) {
              msg = 'Not authorized to request verification.';
            } else if (adminAccountErrorMessage(error).trim().isNotEmpty) {
              msg = adminAccountErrorMessage(error);
            }
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      updateLocalUiState(this, () {
        if (channel == _VerificationChannel.email) {
          _sendingEmail = false;
        } else {
          _sendingPhone = false;
        }
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not send OTP.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = AdaptiveUtils.getHorizontalPadding(width);
    final titleSize = AdaptiveUtils.getSubtitleFontSize(width) - 1;
    final labelSize = AdaptiveUtils.getTitleFontSize(width);

    final profile = widget.profile;
    final needsEmail = !widget.loading && (profile?.emailVerified == false);
    final needsPhone = !widget.loading && (profile?.phoneVerified == false);

    if (!widget.loading && !needsEmail && !needsPhone) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(horizontalPadding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: colorScheme.outline.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.loading
              ? const AppShimmer(width: 130, height: 16, radius: 8)
              : Text(
                  'Verification',
                  style: AppFonts.inter(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface.withOpacity(0.9),
                  ),
                ),
          SizedBox(height: horizontalPadding * 0.55),
          if (widget.loading) ...[
            _loadingRow(),
            const SizedBox(height: 10),
            _loadingRow(),
          ] else ...[
            if (needsEmail)
              _channelRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: profile?.email.trim().isNotEmpty == true
                    ? profile!.email.trim()
                    : '—',
                sending: _sendingEmail,
                onTap: () => _sendOtp(_VerificationChannel.email),
                labelSize: labelSize,
              ),
            if (needsEmail && needsPhone) const SizedBox(height: 10),
            if (needsPhone)
              _channelRow(
                icon: Icons.phone_iphone,
                label: 'WhatsApp',
                value: profile?.phoneDisplay ?? '—',
                sending: _sendingPhone,
                onTap: () => _sendOtp(_VerificationChannel.phone),
                labelSize: labelSize,
              ),
          ],
        ],
      ),
    );
  }

  Widget _loadingRow() {
    return Row(
      children: const [
        Expanded(
          child: AppShimmer(width: double.infinity, height: 34, radius: 12),
        ),
        SizedBox(width: 10),
        AppShimmer(width: 86, height: 32, radius: 16),
      ],
    );
  }

  Widget _channelRow({
    required IconData icon,
    required String label,
    required String value,
    required bool sending,
    required VoidCallback onTap,
    required double labelSize,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$label: $value',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.inter(
                      fontSize: labelSize,
                      color: colorScheme.onSurface.withOpacity(0.9),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'Not verified',
                        style: AppFonts.inter(
                          fontSize: labelSize - 2,
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    InkWell(
                      onTap: sending ? null : onTap,
                      child: sending
                          ? const AppShimmer(width: 52, height: 10, radius: 5)
                          : Text(
                              'Send OTP',
                              style: AppFonts.inter(
                                fontSize: labelSize - 2,
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OtpVerifySheet extends ConsumerStatefulWidget {
  const _OtpVerifySheet({required this.title, required this.onVerify});

  final String title;
  final Future<Result<void, AppError>> Function(String code) onVerify;

  @override
  ConsumerState<_OtpVerifySheet> createState() => _OtpVerifySheetState();
}

class _OtpVerifySheetState extends ConsumerState<_OtpVerifySheet> {
  final TextEditingController _otpController = TextEditingController();
  bool _verifying = false;
  bool _verifyErrorShown = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_verifying) return;
    final code = _otpController.text.trim();
    if (code.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter OTP.')));
      return;
    }

    if (!mounted) return;
    updateLocalUiState(this, () {
      _verifying = true;
      _verifyErrorShown = false;
    });


    try {
      final result = await widget.onVerify(code);
      if (!mounted) return;
      result.when(
        success: (_) {
          if (!mounted) return;
          updateLocalUiState(this, () => _verifying = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verified successfully')),
          );
          Navigator.of(context).pop(true);
        },
        failure: (error) {
          if (!mounted) return;
          updateLocalUiState(this, () => _verifying = false);
          if (_verifyErrorShown) return;
          _verifyErrorShown = true;

          String msg = 'Could not verify OTP.';
          if (adminAccountIsKnownFailure(error)) {
            if (adminAccountStatusCode(error) == 401 || adminAccountStatusCode(error) == 403) {
              msg = 'Not authorized to verify.';
            } else if (adminAccountErrorMessage(error).trim().isNotEmpty) {
              msg = adminAccountErrorMessage(error);
            }
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      updateLocalUiState(this, () => _verifying = false);
      if (_verifyErrorShown) return;
      _verifyErrorShown = true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not verify OTP.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 420).clamp(0.9, 1.0);
    final titleSize = AdaptiveUtils.getSubtitleFontSize(width);
    final labelSize = AdaptiveUtils.getTitleFontSize(width);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: AppFonts.inter(
                      fontSize: titleSize + 1,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _verifying
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: Container(
                    height: 34,
                    width: 34,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.close,
                      size: 18 * scale,
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 8,
              decoration: InputDecoration(
                hintText: 'Enter OTP',
                counterText: '',
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _verifying ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _verifying
                    ? const AppShimmer(width: 42, height: 12, radius: 6)
                    : Text(
                        'Verify OTP',
                        style: AppFonts.inter(
                          fontSize: labelSize,
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
