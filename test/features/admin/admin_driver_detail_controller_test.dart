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
import 'package:open_vts/features/admin/presentation/controllers/admin_driver_detail_controller.dart';

void main() {
  test('loadDetail success stores detail', () async {
    final container = ProviderContainer(overrides: [adminDriverRepositoryProvider.overrideWithValue(_FakeAdminDriverRepository())]);
    addTearDown(container.dispose);

    await container.read(adminDriverDetailControllerProvider('d1').notifier).loadDetail();

    expect(container.read(adminDriverDetailControllerProvider('d1')).detail?.id, 'd1');
  });

  test('assignUser blocks double submit and emits effect', () async {
    final repo = _FakeAdminDriverRepository(delay: const Duration(milliseconds: 50));
    final container = ProviderContainer(overrides: [adminDriverRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);

    final controller = container.read(adminDriverDetailControllerProvider('d1').notifier);
    final first = controller.assignUser(10);
    final second = await controller.assignUser(11);

    expect(second, isFalse);
    expect(await first, isTrue);
    expect(repo.assignCalls, 1);
    expect(container.read(adminDriverDetailControllerProvider('d1')).effect, isNotNull);
    controller.clearEffect();
    expect(container.read(adminDriverDetailControllerProvider('d1')).effect, isNull);
  });
}

class _FakeAdminDriverRepository implements AdminDriverRepository {
  _FakeAdminDriverRepository({this.delay = Duration.zero});
  final Duration delay;
  int assignCalls = 0;

  @override
  Future<Result<List<AdminDriverListItem>, AppError>> getDrivers({String? search, String? status, int? page, int? limit}) async => const Result.success([]);

  @override
  Future<Result<AdminDriverDetails, AppError>> getDriverDetail(String driverId) async => Result.success(AdminDriverDetails.fromRaw({'id': driverId, 'name': 'Driver'}));

  @override
  Future<Result<void, AppError>> updateDriverStatus(String driverId, bool isActive) async => const Result.success(null);

  @override
  Future<Result<List<AdminDocumentItem>, AppError>> getDriverDocuments(String driverId) async => const Result.success([]);

  @override
  Future<Result<List<AdminUserListItem>, AppError>> getLinkedUsers(String driverId) async => const Result.success([]);

  @override
  Future<Result<List<AdminUserListItem>, AppError>> getUnlinkedUsers(String driverId) async => const Result.success([]);

  @override
  Future<Result<void, AppError>> assignUserToDriver(String driverId, {required int userId}) async {
    assignCalls++;
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    return const Result.success(null);
  }

  @override
  Future<Result<void, AppError>> unassignUserFromDriver(String driverId, {required int userId}) async => const Result.success(null);
}
