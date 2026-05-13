import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_list_item.dart';
import 'package:open_vts/features/user/di/user_driver_providers.dart';
import 'package:open_vts/features/user/domain/entities/user_driver_details.dart';
import 'package:open_vts/features/user/domain/repositories/user_driver_repository.dart';
import 'package:open_vts/features/user/presentation/controllers/user_driver_list_controller.dart';

void main() {
  test('loads drivers into controller state', () async {
    final container = ProviderContainer(overrides: [userDriverRepositoryProvider.overrideWithValue(_FakeUserDriverRepository())]);
    addTearDown(container.dispose);

    await container.read(userDriverListControllerProvider.notifier).load();

    expect(container.read(userDriverListControllerProvider).items.single.email, 'driver@example.com');
  });
}

class _FakeUserDriverRepository implements UserDriverRepository {
  @override
  Future<Result<List<AdminDriverListItem>, AppError>> getDrivers() async => const Result.success(<AdminDriverListItem>[AdminDriverListItem(<String, dynamic>{'id': 'driver-1', 'email': 'driver@example.com'})]);
  @override
  Future<Result<UserDriverDetails, AppError>> getDriverDetail(String id) async => Result.success(UserDriverDetails(<String, dynamic>{'id': id}));
  @override
  Future<Result<AdminDriverListItem, AppError>> createDriver(Map<String, Object?> payload) async => Result.success(AdminDriverListItem(<String, dynamic>{'id': 'new'}));
  @override
  Future<Result<void, AppError>> updateDriver(String id, Map<String, Object?> payload) async => const Result.success(null);
  @override
  Future<Result<void, AppError>> deleteDriver(String id) async => const Result.success(null);
}
