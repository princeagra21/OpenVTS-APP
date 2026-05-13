import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/providers/repository_providers.dart' as legacy_repositories;
import 'package:open_vts/features/settings/domain/config/settings_role_config.dart';
import 'package:open_vts/features/settings/presentation/controllers/settings_profile_loader.dart';

class SettingsActionRepositories {
  const SettingsActionRepositories({
    required this.admin,
    required this.user,
    required this.superadmin,
  });

  final dynamic admin;
  final dynamic user;
  final dynamic superadmin;
}

final settingsProfileLoaderProvider = Provider.autoDispose.family<SettingsProfileDataLoader, SettingsRole>((ref, role) {
  return SettingsProfileDataLoader(
    adminRepo: ref.read(legacy_repositories.adminProfileRepositoryProvider),
    userRepo: ref.read(legacy_repositories.userProfileRepositoryProvider),
    superadminRepo: ref.read(legacy_repositories.superadminRepositoryProvider),
  );
});

final settingsActionDepsProvider = Provider.autoDispose<SettingsActionRepositories>((ref) {
  return SettingsActionRepositories(
    admin: ref.read(legacy_repositories.adminProfileRepositoryProvider),
    user: ref.read(legacy_repositories.userProfileRepositoryProvider),
    superadmin: ref.read(legacy_repositories.superadminRepositoryProvider),
  );
});

final settingsPushServiceProvider = Provider.autoDispose((ref) {
  return ref.read(legacy_repositories.pushNotificationsServiceProvider);
});
