import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/di/admin_operations_providers.dart';
import 'package:open_vts/features/admin/domain/entities/admin_transaction_item.dart';

import 'admin_operations_controller_fakes.dart';

void main() {
  test('payments controller loads and creates successfully', () async {
    final fake = FakeAdminOperationsRepository()
      ..paymentsResult = Result.success(<AdminTransactionItem>[
        AdminTransactionItem.fromRaw(const <String, Object?>{'id': 'p1'}),
      ]);
    final container = ProviderContainer(overrides: [adminOperationsRepositoryProvider.overrideWithValue(fake)]);
    addTearDown(container.dispose);

    final controller = container.read(adminPaymentsControllerProvider.notifier);
    expect(await controller.loadPayments(), isTrue);
    expect(container.read(adminPaymentsControllerProvider).items, hasLength(1));

    expect(await controller.createPayment(userId: 'u1', vehicleIds: const <String>['1'], amount: '100', paymentMode: 'CASH'), isTrue);
    expect(container.read(adminPaymentsControllerProvider).actionError, isNull);
  });

  test('payments controller exposes create failure', () async {
    final fake = FakeAdminOperationsRepository()..createPaymentResult = const Result.failure(ServerError('create failed'));
    final container = ProviderContainer(overrides: [adminOperationsRepositoryProvider.overrideWithValue(fake)]);
    addTearDown(container.dispose);

    final ok = await container.read(adminPaymentsControllerProvider.notifier).createPayment(
          userId: 'u1',
          vehicleIds: const <String>['1'],
          amount: '100',
          paymentMode: 'CASH',
        );

    expect(ok, isFalse);
    expect(container.read(adminPaymentsControllerProvider).actionError?.message, 'create failed');
  });
}
