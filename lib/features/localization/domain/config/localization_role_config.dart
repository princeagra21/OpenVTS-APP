import 'package:open_vts/features/localization/domain/entities/localization_models.dart';

class LocalizationRoleConfig {
  const LocalizationRoleConfig({
    required this.role,
    required this.loadEndpoint,
    required this.saveEndpoint,
    required this.title,
    required this.subtitle,
    required this.permissions,
    required this.saveSuccessMessage,
  });

  final LocalizationRole role;
  final String loadEndpoint;
  final String saveEndpoint;
  final String title;
  final String subtitle;
  final LocalizationPermissions permissions;
  final String saveSuccessMessage;
}

class LocalizationRoleConfigs {
  const LocalizationRoleConfigs._();

  static const LocalizationRoleConfig admin = LocalizationRoleConfig(
    role: LocalizationRole.admin,
    loadEndpoint: '/admin/localization',
    saveEndpoint: '/admin/localization',
    title: 'Localization',
    subtitle: 'Localization',
    permissions: LocalizationPermissions(),
    saveSuccessMessage: 'Saved',
  );

  static const LocalizationRoleConfig superadmin = LocalizationRoleConfig(
    role: LocalizationRole.superadmin,
    loadEndpoint: '/superadmin/localization',
    saveEndpoint: '/superadmin/localization',
    title: 'Localization',
    subtitle: 'Localization',
    permissions: LocalizationPermissions(
      requireDirtyBeforeSave: true,
      includeThemeInPayload: true,
    ),
    saveSuccessMessage: 'Localization settings saved successfully.',
  );

  static const LocalizationRoleConfig user = LocalizationRoleConfig(
    role: LocalizationRole.user,
    loadEndpoint: '/user/localization',
    saveEndpoint: '/user/localization',
    title: 'Localization',
    subtitle: 'Localization',
    permissions: LocalizationPermissions(preferEnglishDefaultLanguage: true),
    saveSuccessMessage: 'Saved',
  );
}
