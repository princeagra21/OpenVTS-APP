import 'package:flutter/material.dart';
import 'package:open_vts/features/settings/settings_section_model.dart';

enum SettingsRole { admin, user, superadmin }

@immutable
class SettingsRolePermissions {
  const SettingsRolePermissions({
    this.hasSettingsSection = false,
    this.supportsInlineOtpVerify = true,
    this.supportsPushDiagnostics = false,
  });

  final bool hasSettingsSection;
  final bool supportsInlineOtpVerify;
  final bool supportsPushDiagnostics;
}

@immutable
class SettingsRoleConfig {
  const SettingsRoleConfig({
    required this.role,
    required this.title,
    required this.subtitle,
    required this.availableSections,
    required this.permissions,
    required this.routeMapping,
  });

  final SettingsRole role;
  final String title;
  final String subtitle;
  final List<SettingsSectionModel> availableSections;
  final SettingsRolePermissions permissions;
  final Map<SettingsSectionId, String> routeMapping;
}

class SettingsRoleConfigs {
  const SettingsRoleConfigs._();

  static const _profile = SettingsSectionModel(
    id: SettingsSectionId.profile,
    label: 'Profile',
    icon: Icons.person_outline,
  );

  static const _localization = SettingsSectionModel(
    id: SettingsSectionId.localization,
    label: 'Localization',
    icon: Icons.language,
  );

  static const _settings = SettingsSectionModel(
    id: SettingsSectionId.settings,
    label: 'Settings',
    icon: Icons.tune,
  );

  static const _security = SettingsSectionModel(
    id: SettingsSectionId.security,
    label: 'Security',
    icon: Icons.security,
  );

  static const _account = SettingsSectionModel(
    id: SettingsSectionId.account,
    label: 'Account',
    icon: Icons.account_circle,
  );

  static const _theme = SettingsSectionModel(
    id: SettingsSectionId.theme,
    label: 'Theme',
    icon: Icons.palette,
  );

  static const admin = SettingsRoleConfig(
    role: SettingsRole.admin,
    title: 'Settings',
    subtitle: 'Manage admin configuration',
    availableSections: [_profile, _localization, _settings, _security, _account, _theme],
    permissions: SettingsRolePermissions(
      hasSettingsSection: true,
      supportsInlineOtpVerify: true,
      supportsPushDiagnostics: false,
    ),
    routeMapping: {
      SettingsSectionId.profile: '/admin/settings/profile',
      SettingsSectionId.localization: '/admin/settings/localization',
      SettingsSectionId.settings: '/admin/settings/application',
      SettingsSectionId.security: '/admin/settings/security',
      SettingsSectionId.account: '/admin/settings/account',
      SettingsSectionId.theme: '/admin/settings/theme',
    },
  );

  static const user = SettingsRoleConfig(
    role: SettingsRole.user,
    title: 'Settings',
    subtitle: 'Manage admin configuration',
    availableSections: [_profile, _localization, _account, _theme],
    permissions: SettingsRolePermissions(
      hasSettingsSection: false,
      supportsInlineOtpVerify: true,
      supportsPushDiagnostics: false,
    ),
    routeMapping: {
      SettingsSectionId.profile: '/user/settings/profile',
      SettingsSectionId.localization: '/user/settings/localization',
      SettingsSectionId.account: '/user/settings/account',
      SettingsSectionId.theme: '/user/settings/theme',
    },
  );

  static const superadmin = SettingsRoleConfig(
    role: SettingsRole.superadmin,
    title: 'Settings',
    subtitle: 'Manage platform configuration',
    availableSections: [_profile, _localization, _settings, _security, _account, _theme],
    permissions: SettingsRolePermissions(
      hasSettingsSection: true,
      supportsInlineOtpVerify: false,
      supportsPushDiagnostics: true,
    ),
    routeMapping: {
      SettingsSectionId.profile: '/superadmin/settings/profile',
      SettingsSectionId.localization: '/superadmin/settings/localization',
      SettingsSectionId.settings: '/superadmin/settings/application',
      SettingsSectionId.security: '/superadmin/settings/security',
      SettingsSectionId.account: '/superadmin/settings/account',
      SettingsSectionId.theme: '/superadmin/settings/theme',
    },
  );
}
