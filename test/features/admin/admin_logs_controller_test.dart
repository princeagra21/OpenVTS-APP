import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/di/admin_operations_providers.dart';

import 'admin_operations_controller_fakes.dart';

void main() {
  test('logs controller handles empty and error states', () async {
    final fake = FakeAdminOperationsRepository();
    final container = ProviderContainer(overrides: [adminOperationsRepositoryProvider.overrideWithValue(fake)]);
    addTearDown(container.dispose);

    final controller = container.read(adminLogsControllerProvider.notifier);
    expect(await controller.load(), isTrue);
    expect(container.read(adminLogsControllerProvider).items, isEmpty);
    expect(container.read(adminLogsControllerProvider).error, isNull);

    fake.logsResult = const Result.failure(ServerError('logs failed'));
    expect(await controller.load(), isFalse);
    expect(container.read(adminLogsControllerProvider).items, isEmpty);
    expect(container.read(adminLogsControllerProvider).error?.message, 'logs failed');
  });
}
