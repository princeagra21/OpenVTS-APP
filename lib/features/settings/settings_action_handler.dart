import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_vts/core/models/admin_profile.dart';
import 'package:open_vts/core/network/api_exception.dart';
import 'package:open_vts/core/network/result.dart';
import 'package:open_vts/core/repositories/admin_profile_repository.dart';
import 'package:open_vts/core/repositories/superadmin_repository.dart';
import 'package:open_vts/core/repositories/user_profile_repository.dart';
import 'package:open_vts/core/services/push_notifications_service.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/design_system/components/open_vts_components.dart';
import 'package:open_vts/features/settings/settings_content_controller.dart';
import 'package:open_vts/features/settings/settings_content_state.dart';
import 'package:open_vts/features/settings/settings_role_config.dart';
import 'package:url_launcher/url_launcher.dart';

enum VerifyChannel { email, whatsapp }

class SettingsActionHandler {
  const SettingsActionHandler({
    required this.role,
    required this.controller,
    required this.adminRepo,
    required this.userRepo,
    required this.superadminRepo,
    required this.adminOrUserProfile,
  });

  final SettingsRole role;
  final SettingsContentController controller;
  final AdminProfileRepository? adminRepo;
  final UserProfileRepository? userRepo;
  final SuperadminRepository? superadminRepo;
  final AdminProfile? adminOrUserProfile;

  Future<void> sendAndVerifyAdminOtp(
    BuildContext context,
    VerifyChannel channel,
    SettingsViewState viewState,
    void Function(SettingsViewState) updateState,
  ) async {
    final profile = adminOrUserProfile;
    if (profile == null) return;

    final title = switch (channel) {
      VerifyChannel.email => 'Verify Email',
      VerifyChannel.whatsapp => 'Verify WhatsApp',
    };

    final verified = await OpenVtsModal.showFormSheet<bool>(
      context: context,
      child: _OtpVerifySheet(
        title: title,
        onVerify: (code, token) async {
          final repo = adminRepo!;
          final result = switch (channel) {
            VerifyChannel.email => await repo.verifyEmailOtp(
              code,
              cancelToken: token,
            ),
            VerifyChannel.whatsapp => await repo.verifyPhoneOtp(
              code,
              cancelToken: token,
            ),
          };
          return result.when(
            success: (_) => Result.ok(null),
            failure: (error) => Result.fail(error),
          );
        },
      ),
    );

    if (verified == true) {
      await controller.loadProfile();
    }
  }

  Future<void> sendAndVerifyUserOtp(
    BuildContext context,
    VerifyChannel channel,
    SettingsViewState viewState,
    void Function(SettingsViewState) updateState,
  ) async {
    final profile = adminOrUserProfile;
    if (profile == null) return;

    final title = switch (channel) {
      VerifyChannel.email => 'Verify Email',
      VerifyChannel.whatsapp => 'Verify WhatsApp',
    };

    final verified = await OpenVtsModal.showFormSheet<bool>(
      context: context,
      child: _OtpVerifySheet(
        title: title,
        onVerify: (code, token) async {
          final repo = userRepo!;
          final result = switch (channel) {
            VerifyChannel.email => await repo.verifyEmailOtp(
              code,
              cancelToken: token,
            ),
            VerifyChannel.whatsapp => await repo.verifyPhoneOtp(
              code,
              cancelToken: token,
            ),
          };
          return result.when(
            success: (_) => Result.ok(null),
            failure: (error) => Result.fail(error),
          );
        },
      ),
    );

    if (verified == true) {
      await controller.loadProfile();
    }
  }

  Future<void> requestEmailOtp(
    BuildContext context,
    SettingsViewState viewState,
    void Function(SettingsViewState) updateState,
  ) async {
    if (viewState.emailOtpLoading) return;

    updateState(viewState.copyWith(emailOtpLoading: true));
    final res = await superadminRepo!.requestEmailOtp();
    updateState(viewState.copyWith(emailOtpLoading: false));

    res.when(
      success: (_) {
        _showInfo(context, 'Email OTP request sent.');
      },
      failure: (err) {
        final msg = err is ApiException && err.message.trim().isNotEmpty
            ? err.message
            : 'Failed to request email OTP.';
        _showError(context, msg);
      },
    );
  }

  Future<void> requestWhatsappOtp(
    BuildContext context,
    SettingsViewState viewState,
    void Function(SettingsViewState) updateState,
  ) async {
    if (viewState.whatsappOtpLoading) return;

    updateState(viewState.copyWith(whatsappOtpLoading: true));
    final res = await superadminRepo!.requestWhatsappOtp();
    updateState(viewState.copyWith(whatsappOtpLoading: false));

    res.when(
      success: (_) {
        _showInfo(context, 'WhatsApp OTP request sent.');
      },
      failure: (err) {
        final msg = err is ApiException && err.message.trim().isNotEmpty
            ? err.message
            : 'Failed to request WhatsApp OTP.';
        _showError(context, msg);
      },
    );
  }

  Future<void> loadPushState() async {
    await PushNotificationsService.instance.getStatus();
  }

  Future<void> openNotificationSettings(BuildContext context) async {
    final uri = Uri.parse('app-settings:');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (ok) return;
    _showInfo(
      context,
      'Open your device settings and allow notifications for this app.',
    );
  }

  Future<void> handlePushRegister(
    BuildContext context,
    SettingsViewState viewState,
    void Function(SettingsViewState) updateState,
  ) async {
    if (viewState.pushActionLoading) return;

    updateState(viewState.copyWith(pushActionLoading: true));
    final res = await PushNotificationsService.instance.enable();

    res.when(
      success: (state) {
        updateState(
          viewState.copyWith(
            pushState: state.registered,
            pushActionLoading: false,
          ),
        );
        _showSuccess(context, 'Push enabled.');
      },
      failure: (err) async {
        updateState(viewState.copyWith(pushActionLoading: false));
        final msg = err is ApiException
            ? (err.message.isNotEmpty
                  ? err.message
                  : 'Push could not be enabled.')
            : 'Push could not be enabled.';
        _showError(context, msg);
        if (err is ApiException &&
            err.message.toLowerCase().contains('permission')) {
          await _showPushPermissionDialog(context);
        }
      },
    );
  }

  Future<void> handlePushUnregister(
    BuildContext context,
    SettingsViewState viewState,
    void Function(SettingsViewState) updateState,
  ) async {
    if (viewState.pushActionLoading) return;

    updateState(viewState.copyWith(pushActionLoading: true));
    final res = await PushNotificationsService.instance.disable();

    res.when(
      success: (_) async {
        await loadPushState();
        updateState(viewState.copyWith(pushActionLoading: false));
        _showInfo(context, 'Push disabled.');
      },
      failure: (err) {
        updateState(viewState.copyWith(pushActionLoading: false));
        final msg = err is ApiException
            ? (err.message.isNotEmpty
                  ? err.message
                  : 'Push could not be disabled.')
            : 'Push could not be disabled.';
        _showError(context, msg);
      },
    );
  }

  void _showInfo(BuildContext context, String message) {
    if (!context.mounted) return;
    OpenVtsFeedback.info(context, message);
  }

  void _showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    OpenVtsFeedback.success(context, message);
  }

  void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    OpenVtsFeedback.error(context, message);
  }

  Future<void> _showPushPermissionDialog(BuildContext context) async {
    if (!context.mounted) return;
    await OpenVtsDialog.show<void>(
      context: context,
      title: 'Notification Permission',
      message: 'Open device settings and allow notifications for this app.',
      icon: Icons.notifications_active_outlined,
      actions: [
        OpenVtsDialogAction(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        OpenVtsDialogAction(
          label: 'Open Settings',
          variant: OpenVtsButtonVariant.primary,
          onPressed: () {
            Navigator.of(context).pop();
            openNotificationSettings(context);
          },
        ),
      ],
    );
  }
}

class _OtpVerifySheet extends StatefulWidget {
  const _OtpVerifySheet({required this.title, required this.onVerify});

  final String title;
  final Future<Result<void>> Function(String code, CancelToken token) onVerify;

  @override
  State<_OtpVerifySheet> createState() => _OtpVerifySheetState();
}

class _OtpVerifySheetState extends State<_OtpVerifySheet> {
  final TextEditingController _otpController = TextEditingController();
  CancelToken? _token;
  bool _verifying = false;
  bool _verifyErrorShown = false;

  @override
  void dispose() {
    _token?.cancel('OTP verify dialog disposed');
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_verifying) return;

    final code = _otpController.text.trim();
    if (code.isEmpty) {
      if (!mounted) return;
      OpenVtsFeedback.warning(context, 'Please enter OTP.');
      return;
    }

    if (!mounted) return;
    setState(() {
      _verifying = true;
      _verifyErrorShown = false;
    });

    _token?.cancel('New OTP verify started');
    final token = CancelToken();
    _token = token;

    try {
      final result = await widget.onVerify(code, token);
      if (!mounted) return;

      result.when(
        success: (_) {
          if (!mounted) return;
          setState(() => _verifying = false);
          OpenVtsFeedback.success(context, 'Verified successfully');
          Navigator.of(context).pop(true);
        },
        failure: (error) {
          if (!mounted) return;
          setState(() => _verifying = false);
          if (_verifyErrorShown) return;
          _verifyErrorShown = true;

          var msg = 'Could not verify OTP.';
          if (error is ApiException) {
            if (error.statusCode == 401 || error.statusCode == 403) {
              msg = 'Not authorized to verify.';
            } else if (error.message.trim().isNotEmpty) {
              msg = error.message;
            }
          }
          OpenVtsFeedback.error(context, msg);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _verifying = false);
      if (_verifyErrorShown) return;
      _verifyErrorShown = true;
      OpenVtsFeedback.error(context, 'Could not verify OTP.');
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
                      color: colorScheme.surfaceContainerHighest.withOpacity(
                        0.5,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Enter the OTP sent to your ${widget.title.toLowerCase().split(' ').last}',
              style: AppFonts.inter(
                fontSize: labelSize - 2,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            OpenVtsTextField(
              controller: _otpController,
              hintText: 'Enter OTP',
              keyboardType: TextInputType.number,
              enabled: !_verifying,
              onSubmitted: (_) => _verify(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OpenVtsButton(
                    label: 'Verify',
                    onPressed: _verifying ? null : _verify,
                    loading: _verifying,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
