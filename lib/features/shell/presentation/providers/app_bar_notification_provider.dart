import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/shell/di/shell_providers.dart';

final appBarUnreadCountProvider = FutureProvider.autoDispose
    .family<int, String>((ref, pathPrefix) async {
  final normalizedPath = pathPrefix.trim();
  if (normalizedPath.isEmpty) return 0;

  final repository = ref.read(
    shellRoleNotificationsRepositoryProvider(normalizedPath),
  );
  final result = await repository.getNotifications();
  return result.when(
    success: (items) => items.where((item) => !item.isRead).length,
    failure: (_) => 0,
  );
});

class AppBarNotificationBadgeController {
  const AppBarNotificationBadgeController(this._ref, this._pathPrefix);

  final Ref _ref;
  final String _pathPrefix;

  void reload() {
    final normalizedPath = _pathPrefix.trim();
    if (normalizedPath.isEmpty) return;
    _ref.invalidate(appBarUnreadCountProvider(normalizedPath));
  }
}

final appBarNotificationBadgeControllerProvider = Provider.autoDispose
    .family<AppBarNotificationBadgeController, String>((ref, pathPrefix) {
  return AppBarNotificationBadgeController(ref, pathPrefix);
});
