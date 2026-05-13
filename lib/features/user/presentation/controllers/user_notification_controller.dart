import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/user/di/user_notification_providers.dart';
import 'package:open_vts/features/user/domain/entities/user_notification_item.dart';

class UserNotificationState {
  const UserNotificationState({
    this.items = const <UserNotificationItem>[],
    this.isLoading = false,
    this.isMarkingRead = false,
    this.errorMessage,
    this.effect,
  });

  final List<UserNotificationItem> items;
  final bool isLoading;
  final bool isMarkingRead;
  final String? errorMessage;
  final UserNotificationEffect? effect;

  int get unreadCount => items.where((item) => !item.isRead).length;

  UserNotificationState copyWith({
    List<UserNotificationItem>? items,
    bool? isLoading,
    bool? isMarkingRead,
    Object? errorMessage = _unchanged,
    Object? effect = _unchanged,
  }) {
    return UserNotificationState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isMarkingRead: isMarkingRead ?? this.isMarkingRead,
      errorMessage: identical(errorMessage, _unchanged) ? this.errorMessage : errorMessage as String?,
      effect: identical(effect, _unchanged) ? this.effect : effect as UserNotificationEffect?,
    );
  }
}

class UserNotificationEffect {
  const UserNotificationEffect._(this.message, this.isError);
  final String message;
  final bool isError;

  const UserNotificationEffect.success(String message) : this._(message, false);
  const UserNotificationEffect.error(String message) : this._(message, true);
}

const Object _unchanged = Object();

final userNotificationControllerProvider = StateNotifierProvider.autoDispose<UserNotificationController, UserNotificationState>((ref) => UserNotificationController(ref));

class UserNotificationController extends StateNotifier<UserNotificationState> {
  UserNotificationController(this._ref) : super(const UserNotificationState());
  final Ref _ref;

  Future<void> loadNotifications() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, errorMessage: null, effect: null);
    final result = await _ref.read(getUserNotificationsUseCaseProvider)();
    if (!mounted) return;
    result.when(
      success: (items) => state = state.copyWith(items: items, isLoading: false),
      failure: (error) {
        final message = _message(error, "Couldn't load notifications.");
        state = state.copyWith(isLoading: false, errorMessage: message, effect: UserNotificationEffect.error(message));
      },
    );
  }

  Future<bool> markRead(String id) async {
    if (state.isMarkingRead) return false;
    final normalized = id.trim();
    if (normalized.isEmpty) return false;
    final index = state.items.indexWhere((item) => item.id == normalized);
    if (index < 0 || state.items[index].isRead) return false;
    final previous = state.items;
    final optimistic = previous.map((item) => item.id == normalized ? item.copyWith(isRead: true) : item).toList(growable: false);
    state = state.copyWith(items: optimistic, isMarkingRead: true, errorMessage: null, effect: null);
    final result = await _ref.read(markUserNotificationReadUseCaseProvider)(normalized);
    if (!mounted) return false;
    return result.when(
      success: (_) {
        state = state.copyWith(isMarkingRead: false);
        return true;
      },
      failure: (error) {
        final message = _message(error, "Couldn't mark notification read.");
        state = state.copyWith(items: previous, isMarkingRead: false, errorMessage: message, effect: UserNotificationEffect.error(message));
        return false;
      },
    );
  }

  Future<bool> markAllRead() async {
    if (state.isMarkingRead || state.items.isEmpty) return false;
    final previous = state.items;
    final optimistic = previous.map((item) => item.copyWith(isRead: true)).toList(growable: false);
    state = state.copyWith(items: optimistic, isMarkingRead: true, errorMessage: null, effect: null);
    final result = await _ref.read(markAllUserNotificationsReadUseCaseProvider)();
    if (!mounted) return false;
    return result.when(
      success: (_) {
        state = state.copyWith(isMarkingRead: false, effect: const UserNotificationEffect.success('All notifications marked as read'));
        return true;
      },
      failure: (error) {
        final message = _message(error, "Couldn't mark notifications read.");
        state = state.copyWith(items: previous, isMarkingRead: false, errorMessage: message, effect: UserNotificationEffect.error(message));
        return false;
      },
    );
  }

  void clearEffect() {
    state = state.copyWith(effect: null);
  }

  String _message(Object error, String fallback) => error is AppError && error.message.trim().isNotEmpty ? error.message : fallback;
}
