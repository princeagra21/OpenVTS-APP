import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/features/admin/di/admin_account_providers.dart';
import 'package:open_vts/shared/models/admin_profile.dart';

import 'admin_account_controller_fakes.dart';

void main() {
  test('AdminProfileController loads and updates profile through use cases', () async {
    final fake = FakeAdminAccountRepository()
      ..profile = const AdminProfile(<String, dynamic>{'id': 'admin-1', 'name': 'Old Name'});
    final container = ProviderContainer(
      overrides: [adminAccountRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final controller = container.read(adminProfileControllerProvider.notifier);
    await controller.load();
    expect(container.read(adminProfileControllerProvider).profile?.fullName, 'Old Name');

    final updated = await controller.update(<String, Object?>{'name': 'New Name'});
    final state = container.read(adminProfileControllerProvider);
    expect(updated, isTrue);
    expect(state.isSubmitting, isFalse);
    expect(state.error, isNull);
    expect(state.profile?.fullName, 'New Name');
  });

  test('AdminProfileController updates password through use case', () async {
    final fake = FakeAdminAccountRepository();
    final container = ProviderContainer(
      overrides: [adminAccountRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final controller = container.read(adminProfileControllerProvider.notifier);
    final updated = await controller.updatePassword(
      currentPassword: 'old-password',
      newPassword: 'new-password',
    );

    final state = container.read(adminProfileControllerProvider);
    expect(updated, isTrue);
    expect(state.isSubmitting, isFalse);
    expect(state.error, isNull);
  });
}
