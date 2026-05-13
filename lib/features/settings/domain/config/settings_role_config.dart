import 'package:open_vts/features/settings/domain/entities/settings_section_model.dart';

enum SettingsRole { admin, user, superadmin }

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
    iconKey: 'person',
  );

  static const _localization = SettingsSectionModel(
    id: SettingsSectionId.localization,
    label: 'Localization',
    iconKey: 'language',
  );

  static const _settings = SettingsSectionModel(
    id: SettingsSectionId.settings,
    label: 'Settings',
    iconKey: 'settings',
  );

  static const admin = SettingsRoleConfig(
    role: SettingsRole.admin,
    title: 'Settings',
    subtitle: 'Manage admin configuration',
    availableSections: [_profile, _localization, _settings],
    permissions: SettingsRolePermissions(
      hasSettingsSection: true,
      supportsInlineOtpVerify: true,
      supportsPushDiagnostics: false,
    ),
    routeMapping: {
      SettingsSectionId.profile: '/admin/settings/profile',
      SettingsSectionId.localization: '/admin/settings/localization',
      SettingsSectionId.settings: '/admin/settings/application',
    },
  );

  static const user = SettingsRoleConfig(
    role: SettingsRole.user,
    title: 'Settings',
    subtitle: 'Manage admin configuration',
    availableSections: [_profile, _localization],
    permissions: SettingsRolePermissions(
      hasSettingsSection: false,
      supportsInlineOtpVerify: true,
      supportsPushDiagnostics: false,
    ),
    routeMapping: {
      SettingsSectionId.profile: '/user/settings/profile',
      SettingsSectionId.localization: '/user/settings/localization',
    },
  );

  static const superadmin = SettingsRoleConfig(
    role: SettingsRole.superadmin,
    title: 'Settings',
    subtitle: 'Manage platform configuration',
    availableSections: [_profile, _localization, _settings],
    permissions: SettingsRolePermissions(
      hasSettingsSection: true,
      supportsInlineOtpVerify: false,
      supportsPushDiagnostics: true,
    ),
    routeMapping: {
      SettingsSectionId.profile: '/superadmin/settings/profile',
      SettingsSectionId.localization: '/superadmin/settings/localization',
      SettingsSectionId.settings: '/superadmin/settings/application',
    },
  );
}
