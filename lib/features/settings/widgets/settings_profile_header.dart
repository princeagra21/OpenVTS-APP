import 'package:flutter/material.dart';
import 'package:open_vts/features/settings/settings_controller.dart';
import 'package:open_vts/features/settings/widgets/settings_account_section.dart';
import 'package:open_vts/features/settings/widgets/settings_profile_actions.dart';
import 'package:open_vts/features/settings/widgets/settings_profile_address.dart';
import 'package:open_vts/features/settings/widgets/settings_profile_company.dart';
import 'package:open_vts/features/settings/widgets/settings_profile_error.dart';
import 'package:open_vts/features/settings/widgets/settings_profile_identity.dart';
import 'package:open_vts/features/settings/widgets/settings_profile_loading.dart';
import 'package:open_vts/features/settings/widgets/settings_profile_verification_badges.dart';
import 'package:open_vts/features/settings/widgets/settings_security_section.dart';
import 'package:open_vts/features/settings/widgets/settings_section_card.dart';

class SettingsProfileHeader extends StatelessWidget {
  const SettingsProfileHeader({
    super.key,
    required this.profile,
    required this.loading,
    required this.onEdit,
    required this.onPassword,
    this.onEmailVerify,
    this.onPhoneVerify,
    this.emailActionVisibleWhenVerified = false,
    this.phoneActionVisibleWhenVerified = false,
    this.emailActionLoading = false,
    this.phoneActionLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  final SettingsProfileData profile;
  final bool loading;
  final VoidCallback onEdit;
  final VoidCallback onPassword;
  final Future<void> Function()? onEmailVerify;
  final Future<void> Function()? onPhoneVerify;
  final bool emailActionVisibleWhenVerified;
  final bool phoneActionVisibleWhenVerified;
  final bool emailActionLoading;
  final bool phoneActionLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SettingsSectionCard(child: SettingsProfileLoading());
    }

    final hasError =
        errorMessage != null &&
        errorMessage!.trim().isNotEmpty &&
        profile.profileId.isEmpty;
    if (hasError) {
      return SettingsSectionCard(
        child: SettingsProfileError(
          message: errorMessage!.trim(),
          onRetry: onRetry,
        ),
      );
    }

    final showWhatsapp =
        profile.whatsapp.trim().isNotEmpty &&
        profile.whatsapp.trim() != '-' &&
        profile.whatsapp.trim() != profile.phone.trim();

    return SettingsSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsProfileActions(onEdit: onEdit, onPassword: onPassword),
          const SizedBox(height: 16),
          SettingsAccountSection(
            child: SettingsProfileIdentityCard(
              name: profile.name,
              username: profile.username,
              verified: profile.verified,
              imageUrl: profile.imageUrl,
              loading: loading,
            ),
          ),
          const SizedBox(height: 12),
          SettingsAccountSection(
            child: SettingsProfileDatesGrid(
              loading: loading,
              createdDate: profile.createdParts.isNotEmpty
                  ? profile.createdParts[0]
                  : '—',
              createdTime: profile.createdParts.length > 1
                  ? profile.createdParts[1]
                  : '—',
              updatedDate: profile.updatedParts.isNotEmpty
                  ? profile.updatedParts[0]
                  : '—',
              updatedTime: profile.updatedParts.length > 1
                  ? profile.updatedParts[1]
                  : '—',
            ),
          ),
          const SizedBox(height: 12),
          SettingsSecuritySection(
            child: SettingsProfileEmailCard(
              email: profile.email,
              verified: profile.emailVerified,
              loading: loading,
              onVerify: onEmailVerify,
              showActionWhenVerified: emailActionVisibleWhenVerified,
              actionLoading: emailActionLoading,
            ),
          ),
          const SizedBox(height: 12),
          SettingsSecuritySection(
            child: SettingsProfilePhoneCard(
              phone: profile.phone,
              verified: profile.phoneVerified,
              loading: loading,
              onVerify: onPhoneVerify,
              showActionWhenVerified: phoneActionVisibleWhenVerified,
              actionLoading: phoneActionLoading,
            ),
          ),
          if (showWhatsapp) ...[
            const SizedBox(height: 12),
            SettingsAccountSection(
              child: SettingsProfileWhatsappCard(
                phone: profile.whatsapp,
                loading: loading,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SettingsAccountSection(
            child: SettingsProfileCompanyCard(
              companyName: profile.companyName,
              companyWebsite: profile.companyWebsite,
              companyId: profile.companyId,
              primaryColor: profile.primaryColor,
              customDomain: profile.customDomain,
              socialLabels: profile.socialLabels,
              socialLinks: profile.socialLinks,
              loading: loading,
              onEditCompany: onEdit,
            ),
          ),
          const SizedBox(height: 12),
          SettingsAccountSection(
            child: SettingsProfileAddressCard(
              address: profile.address,
              loading: loading,
            ),
          ),
        ],
      ),
    );
  }
}
