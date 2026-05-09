import 'package:flutter/material.dart';
import 'package:open_vts/features/settings/settings_action_handler.dart';
import 'package:open_vts/features/settings/settings_content_state.dart';
import 'package:open_vts/features/settings/settings_role_config.dart';
import 'package:open_vts/features/settings/settings_section_model.dart';
import 'package:open_vts/features/settings/widgets/settings_profile_header.dart';

class SettingsProfileSection extends StatelessWidget {
  const SettingsProfileSection({
    super.key,
    required this.role,
    required this.profile,
    required this.loading,
    required this.viewState,
    required this.actionHandler,
    required this.onEditProfile,
    required this.onUpdatePassword,
  });

  final SettingsRole role;
  final SettingsProfileData profile;
  final bool loading;
  final SettingsViewState viewState;
  final SettingsActionHandler actionHandler;
  final VoidCallback onEditProfile;
  final VoidCallback onUpdatePassword;

  @override
  Widget build(BuildContext context) {
    final onEmailVerify = switch (role) {
      SettingsRole.admin => () => actionHandler.sendAndVerifyAdminOtp(
            context,
            VerifyChannel.email,
            viewState,
            (state) {}, // This would be handled by state management
          ),
      SettingsRole.user => () => actionHandler.sendAndVerifyUserOtp(
            context,
            VerifyChannel.email,
            viewState,
            (state) {},
          ),
      SettingsRole.superadmin => () => actionHandler.requestEmailOtp(
            context,
            viewState,
            (state) {},
          ),
    };

    final onPhoneVerify = switch (role) {
      SettingsRole.admin => () => actionHandler.sendAndVerifyAdminOtp(
            context,
            VerifyChannel.whatsapp,
            viewState,
            (state) {},
          ),
      SettingsRole.user => () => actionHandler.sendAndVerifyUserOtp(
            context,
            VerifyChannel.whatsapp,
            viewState,
            (state) {},
          ),
      SettingsRole.superadmin => () => actionHandler.requestWhatsappOtp(
            context,
            viewState,
            (state) {},
          ),
    };

    final showSuperadminRequestActions = role == SettingsRole.superadmin;

    return Column(
      children: [
        SettingsProfileHeader(
          profile: profile,
          loading: loading,
          onEdit: onEditProfile,
          onPassword: onUpdatePassword,
          onEmailVerify: onEmailVerify,
          onPhoneVerify: onPhoneVerify,
          emailActionVisibleWhenVerified: showSuperadminRequestActions,
          phoneActionVisibleWhenVerified: showSuperadminRequestActions,
          emailActionLoading: viewState.emailOtpLoading,
          phoneActionLoading: viewState.whatsappOtpLoading,
          errorMessage: null, // This would come from controller
          onRetry: () {}, // This would trigger controller.loadProfile
        ),
        if (role == SettingsRole.superadmin) ...[
          const SizedBox(height: 16),
          // _PushDiagnosticsCard would go here
        ],
      ],
    );
  }
}