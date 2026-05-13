import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/di/admin_driver_providers.dart';
import 'package:open_vts/features/admin/domain/entities/admin_document_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_details.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_list_item.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_driver_repository.dart';
import 'package:open_vts/features/admin/presentation/controllers/admin_driver_list_controller.dart';

void main() {
  test('loadDrivers populates list state', () async {
    final container = ProviderContainer(overrides: [
      adminDriverRepositoryProvider.overrideWithValue(_FakeAdminDriverRepository()),
    ]);
    addTearDown(container.dispose);

    await container.read(adminDriverListControllerProvider.notifier).loadDrivers();

    final state = container.read(adminDriverListControllerProvider);
    expect(state.items.single.fullName, 'A Driver');
    expect(state.isLoading, isFalse);
  });

  test('updateStatus rolls back and surfaces error on failure', () async {
    final repo = _FakeAdminDriverRepository(updateResult: const Result.failure(ServerError('Denied')));
    final container = ProviderContainer(overrides: [adminDriverRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);

    await container.read(adminDriverListControllerProvider.notifier).loadDrivers();
    final item = container.read(adminDriverListControllerProvider).items.single;
    final ok = await container.read(adminDriverListControllerProvider.notifier).updateStatus(item, false);

    final state = container.read(adminDriverListControllerProvider);
    expect(ok, isFalse);
    expect(state.items.single.isActive, isTrue);
    expect(state.errorMessage, 'Denied');
  });
}

class _FakeAdminDriverRepository implements AdminDriverRepository {
  _FakeAdminDriverRepository({this.updateResult = const Result.success(null)});
  final Result<void, AppError> updateResult;

  @override
  Future<Result<List<AdminDriverListItem>, AppError>> getDrivers({String? search, String? status, int? page, int? limit}) async {
    return Result.success([AdminDriverListItem.fromRaw({'id': 'd1', 'name': 'A Driver', 'isActive': true})]);
  }

  @override
  Future<Result<AdminDriverDetails, AppError>> getDriverDetail(String driverId) async => Result.success(AdminDriverDetails.fromRaw({'id': driverId}));

  @override
  Future<Result<void, AppError>> updateDriverStatus(String driverId, bool isActive) async => updateResult;

  @override
  Future<Result<List<AdminDocumentItem>, AppError>> getDriverDocuments(String driverId) async => const Result.success([]);

  @override
  Future<Result<List<AdminUserListItem>, AppError>> getLinkedUsers(String driverId) async => const Result.success([]);

  @override
  Future<Result<List<AdminUserListItem>, AppError>> getUnlinkedUsers(String driverId) async => const Result.success([]);

  @override
  Future<Result<void, AppError>> assignUserToDriver(String driverId, {required int userId}) async => const Result.success(null);

  @override
  Future<Result<void, AppError>> unassignUserFromDriver(String driverId, {required int userId}) async => const Result.success(null);
}
