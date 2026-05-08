import 'package:flutter/foundation.dart';
import 'package:open_vts/core/network/api_paths.dart';
import 'package:open_vts/features/localization/localization_models.dart';

@immutable
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
    loadEndpoint: AdminApiPaths.localization,
    saveEndpoint: AdminApiPaths.localization,
    title: 'Localization',
    subtitle: 'Localization',
    permissions: LocalizationPermissions(),
    saveSuccessMessage: 'Saved',
  );

  static const LocalizationRoleConfig superadmin = LocalizationRoleConfig(
    role: LocalizationRole.superadmin,
    loadEndpoint: SuperadminApiPaths.localization,
    saveEndpoint: SuperadminApiPaths.localization,
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
    loadEndpoint: UserApiPaths.localization,
    saveEndpoint: UserApiPaths.localization,
    title: 'Localization',
    subtitle: 'Localization',
    permissions: LocalizationPermissions(preferEnglishDefaultLanguage: true),
    saveSuccessMessage: 'Saved',
  );
}
