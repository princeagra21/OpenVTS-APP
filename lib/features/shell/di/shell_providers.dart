import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/providers/repository_providers.dart' as legacy_repositories;
import 'package:open_vts/features/admin/data/repositories/role_notifications_repository.dart';

final shellRoleNotificationsRepositoryProvider = Provider.autoDispose
    .family<RoleNotificationsRepository, String>((ref, pathPrefix) {
  return ref.read(
    legacy_repositories.roleNotificationsRepositoryProvider(pathPrefix),
  );
});
