import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/features/admin/di/admin_account_providers.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_list_item.dart';

import 'admin_account_controller_fakes.dart';

void main() {
  test('AdminUserListController loads users through use-case provider', () async {
    final fake = FakeAdminAccountRepository()
      ..users = <AdminUserListItem>[
        AdminUserListItem.fromRaw(<String, Object?>{'id': 'user-1', 'name': 'Fleet Admin'}),
      ];
    final container = ProviderContainer(
      overrides: [adminAccountRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final controller = container.read(adminUserListControllerProvider.notifier);
    await controller.load();

    final state = container.read(adminUserListControllerProvider);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
    expect(state.items, hasLength(1));
    expect(state.items.first.fullName, 'Fleet Admin');
  });

  test('AdminUserListController exposes action state for status update', () async {
    final fake = FakeAdminAccountRepository();
    final container = ProviderContainer(
      overrides: [adminAccountRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final controller = container.read(adminUserListControllerProvider.notifier);
    final ok = await controller.updateStatus(
      AdminUserListItem.fromRaw(<String, Object?>{'id': 'user-1'}),
      true,
    );

    final state = container.read(adminUserListControllerProvider);
    expect(ok, isTrue);
    expect(state.updatingIds, isEmpty);
    expect(state.error, isNull);
  });
}
