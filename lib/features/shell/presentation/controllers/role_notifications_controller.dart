import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/admin/domain/entities/admin_notification_item.dart';
import 'package:open_vts/features/shell/di/shell_providers.dart';

class RoleNotificationsState {
  const RoleNotificationsState({
    this.items = const <AdminNotificationItem>[],
    this.isLoading = false,
    this.isMarking = false,
    this.errorMessage,
  });

  final List<AdminNotificationItem> items;
  final bool isLoading;
  final bool isMarking;
  final String? errorMessage;

  int get unreadCount => items.where((item) => !item.isRead).length;

  RoleNotificationsState copyWith({
    List<AdminNotificationItem>? items,
    bool? isLoading,
    bool? isMarking,
    Object? errorMessage = _unchanged,
  }) {
    return RoleNotificationsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isMarking: isMarking ?? this.isMarking,
      errorMessage: identical(errorMessage, _unchanged) ? this.errorMessage : errorMessage as String?,
    );
  }
}

const Object _unchanged = Object();

final roleNotificationsControllerProvider = StateNotifierProvider.autoDispose
    .family<RoleNotificationsController, RoleNotificationsState, String>((ref, pathPrefix) {
  return RoleNotificationsController(ref, pathPrefix);
});

class RoleNotificationsController extends StateNotifier<RoleNotificationsState> {
  RoleNotificationsController(this._ref, this._pathPrefix) : super(const RoleNotificationsState());

  final Ref _ref;
  final String _pathPrefix;
  bool _loadInFlight = false;

  Future<void> load() async {
    final normalizedPath = _pathPrefix.trim();
    if (normalizedPath.isEmpty || _loadInFlight) return;

    _loadInFlight = true;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final repository = _ref.read(shellRoleNotificationsRepositoryProvider(normalizedPath));
      final result = await repository.getNotifications();
      if (!mounted) return;
      result.when(
        success: (items) => state = state.copyWith(items: items, isLoading: false, errorMessage: null),
        failure: (_) => state = state.copyWith(isLoading: false, errorMessage: "Couldn't load notifications."),
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: "Couldn't load notifications.");
    } finally {
      _loadInFlight = false;
    }
  }

  Future<bool> markRead(String id) async {
    final normalizedPath = _pathPrefix.trim();
    if (normalizedPath.isEmpty || id.trim().isEmpty || state.isMarking) return false;
    state = state.copyWith(isMarking: true, errorMessage: null);
    final repository = _ref.read(shellRoleNotificationsRepositoryProvider(normalizedPath));
    final result = await repository.markRead(id.trim());
    if (!mounted) return false;
    return result.when(
      success: (_) {
        state = state.copyWith(
          isMarking: false,
          items: state.items.map((item) {
            if (item.id != id.trim()) return item;
            return AdminNotificationItem(<String, Object?>{...item.raw, 'isRead': true});
          }).toList(),
          errorMessage: null,
        );
        return true;
      },
      failure: (_) {
        state = state.copyWith(isMarking: false, errorMessage: "Couldn't mark notification as read.");
        return false;
      },
    );
  }

  Future<bool> markAllRead() async {
    final normalizedPath = _pathPrefix.trim();
    if (normalizedPath.isEmpty || state.isMarking) return false;
    state = state.copyWith(isMarking: true, errorMessage: null);
    final repository = _ref.read(shellRoleNotificationsRepositoryProvider(normalizedPath));
    final result = await repository.markAllRead();
    if (!mounted) return false;
    return result.when(
      success: (_) {
        state = state.copyWith(
          isMarking: false,
          items: state.items.map((item) => AdminNotificationItem(<String, Object?>{...item.raw, 'isRead': true})).toList(),
          errorMessage: null,
        );
        return true;
      },
      failure: (_) {
        state = state.copyWith(isMarking: false, errorMessage: "Couldn't mark notifications as read.");
        return false;
      },
    );
  }
}
