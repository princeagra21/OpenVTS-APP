import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/di/admin_operations_providers.dart';
import 'package:open_vts/features/admin/domain/entities/admin_notification_item.dart';

import 'admin_operations_controller_fakes.dart';

void main() {
  test('notifications controller loads and sends successfully', () async {
    final fake = FakeAdminOperationsRepository()
      ..notificationsResult = Result.success(<AdminNotificationItem>[
        AdminNotificationItem(const <String, Object?>{'id': 'n1', 'title': 'Test'}),
      ]);
    final container = ProviderContainer(overrides: [adminOperationsRepositoryProvider.overrideWithValue(fake)]);
    addTearDown(container.dispose);

    final controller = container.read(adminNotificationsControllerProvider.notifier);
    expect(await controller.load(), isTrue);
    expect(container.read(adminNotificationsControllerProvider).items, hasLength(1));

    expect(await controller.send(channel: 'EMAIL', userIds: const <String>['u1'], message: 'Hello'), isTrue);
    expect(container.read(adminNotificationsControllerProvider).actionError, isNull);
  });

  test('notifications controller exposes send failure', () async {
    final fake = FakeAdminOperationsRepository()..sendResult = const Result.failure(ServerError('send failed'));
    final container = ProviderContainer(overrides: [adminOperationsRepositoryProvider.overrideWithValue(fake)]);
    addTearDown(container.dispose);

    final ok = await container.read(adminNotificationsControllerProvider.notifier).send(
          channel: 'EMAIL',
          userIds: const <String>['u1'],
          message: 'Hello',
        );

    expect(ok, isFalse);
    expect(container.read(adminNotificationsControllerProvider).actionError?.message, 'send failed');
  });
}
