import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/di/user_notification_providers.dart';
import 'package:open_vts/features/user/domain/entities/user_notification_item.dart';
import 'package:open_vts/features/user/domain/entities/user_notification_preferences.dart';
import 'package:open_vts/features/user/domain/repositories/user_notification_repository.dart';
import 'package:open_vts/features/user/presentation/controllers/user_notification_controller.dart';

void main() {
  test('load success puts notifications into state', () async {
    final container = _container(_FakeUserNotificationRepository());
    addTearDown(container.dispose);

    await container.read(userNotificationControllerProvider.notifier).loadNotifications();

    final state = container.read(userNotificationControllerProvider);
    expect(state.items.single.title, 'Overspeed');
    expect(state.unreadCount, 1);
  });

  test('load failure emits error effect', () async {
    final container = _container(_FakeUserNotificationRepository(loadFailure: true));
    addTearDown(container.dispose);

    await container.read(userNotificationControllerProvider.notifier).loadNotifications();

    final state = container.read(userNotificationControllerProvider);
    expect(state.effect?.isError, isTrue);
  });

  test('mark one notification read uses typed copyWith', () async {
    final container = _container(_FakeUserNotificationRepository());
    addTearDown(container.dispose);
    final controller = container.read(userNotificationControllerProvider.notifier);
    await controller.loadNotifications();

    final ok = await controller.markRead('n-1');

    expect(ok, isTrue);
    expect(container.read(userNotificationControllerProvider).items.single.isRead, isTrue);
  });

  test('mark all notifications read', () async {
    final container = _container(_FakeUserNotificationRepository());
    addTearDown(container.dispose);
    final controller = container.read(userNotificationControllerProvider.notifier);
    await controller.loadNotifications();

    final ok = await controller.markAllRead();

    expect(ok, isTrue);
    expect(container.read(userNotificationControllerProvider).unreadCount, 0);
  });

  test('double action protection blocks concurrent mark read', () async {
    final container = _container(_FakeUserNotificationRepository(delayMark: true));
    addTearDown(container.dispose);
    final controller = container.read(userNotificationControllerProvider.notifier);
    await controller.loadNotifications();

    final first = controller.markRead('n-1');
    final second = await controller.markRead('n-1');
    expect(second, isFalse);
    await first;
  });

  test('clearEffect clears effect', () async {
    final container = _container(_FakeUserNotificationRepository(loadFailure: true));
    addTearDown(container.dispose);
    final controller = container.read(userNotificationControllerProvider.notifier);
    await controller.loadNotifications();
    expect(container.read(userNotificationControllerProvider).effect, isNotNull);
    controller.clearEffect();
    expect(container.read(userNotificationControllerProvider).effect, isNull);
  });
}

ProviderContainer _container(UserNotificationRepository repo) {
  return ProviderContainer(overrides: [userNotificationRepositoryProvider.overrideWithValue(repo)]);
}

class _FakeUserNotificationRepository implements UserNotificationRepository {
  _FakeUserNotificationRepository({this.loadFailure = false, this.delayMark = false});

  final bool loadFailure;
  final bool delayMark;

  @override
  Future<Result<List<UserNotificationItem>, AppError>> getNotifications() async {
    if (loadFailure) return const Result.failure(ServerError('boom'));
    return const Result.success(<UserNotificationItem>[
      UserNotificationItem(id: 'n-1', title: 'Overspeed', body: 'Vehicle is overspeeding', createdAt: '', type: 'alert', isRead: false),
    ]);
  }

  @override
  Future<Result<void, AppError>> markNotificationRead(String id) async {
    if (delayMark) await Future<void>.delayed(const Duration(milliseconds: 10));
    return const Result.success(null);
  }

  @override
  Future<Result<void, AppError>> markAllNotificationsRead() async => const Result.success(null);

  @override
  Future<Result<UserNotificationPreferences, AppError>> getPreferences() async => Result.success(UserNotificationPreferences(<String, Object?>{'channels': <String, Object?>{}}));

  @override
  Future<Result<void, AppError>> updatePreferences(Map<String, Object?> payload) async => const Result.success(null);
}
