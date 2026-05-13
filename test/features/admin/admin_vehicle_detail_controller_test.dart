import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/di/admin_vehicle_providers.dart';
import 'package:open_vts/features/admin/domain/entities/admin_document_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_vehicle_details.dart';
import 'package:open_vts/features/admin/domain/entities/admin_vehicle_log_item.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_vehicle_repository.dart';
import 'package:open_vts/features/admin/presentation/controllers/admin_vehicle_detail_controller.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_config.dart';

void main() {
  test('loadVehicle success stores vehicle detail', () async {
    final container = ProviderContainer(overrides: [
      adminVehicleRepositoryProvider.overrideWithValue(_FakeAdminVehicleRepository()),
    ]);
    addTearDown(container.dispose);

    await container.read(adminVehicleDetailControllerProvider('v1').notifier).loadVehicle('v1');

    final state = container.read(adminVehicleDetailControllerProvider('v1'));
    expect(state.vehicle?.imei, '111222333444555');
    expect(state.isLoading, isFalse);
  });

  test('loadVehicle failure emits error effect', () async {
    final container = ProviderContainer(overrides: [
      adminVehicleRepositoryProvider.overrideWithValue(_FakeAdminVehicleRepository(detailResult: const Result.failure(ServerError('Denied')))),
    ]);
    addTearDown(container.dispose);

    await container.read(adminVehicleDetailControllerProvider('v1').notifier).loadVehicle('v1');

    final state = container.read(adminVehicleDetailControllerProvider('v1'));
    expect(state.errorMessage, 'Denied');
    expect(state.effect?.isError, isTrue);
  });

  test('updateConfig blocks duplicate submit', () async {
    final repo = _FakeAdminVehicleRepository(delay: const Duration(milliseconds: 50));
    final container = ProviderContainer(overrides: [adminVehicleRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);

    final controller = container.read(adminVehicleDetailControllerProvider('v1').notifier);
    final input = VehicleConfigUpdate(speedMultiplier: 1, distanceMultiplier: 1, odometer: 0, engineHours: 0, ignitionSource: 'Motion-Based');
    final first = controller.updateConfig(input);
    final second = await controller.updateConfig(input);

    expect(second, isFalse);
    expect(await first, isTrue);
    expect(repo.updateConfigCalls, 1);
  });

  test('deleteVehicle success emits effect and clearEffect resets it', () async {
    final container = ProviderContainer(overrides: [
      adminVehicleRepositoryProvider.overrideWithValue(_FakeAdminVehicleRepository()),
    ]);
    addTearDown(container.dispose);

    final controller = container.read(adminVehicleDetailControllerProvider('v1').notifier);
    final ok = await controller.deleteVehicle();
    expect(ok, isTrue);
    expect(container.read(adminVehicleDetailControllerProvider('v1')).effect, isNotNull);

    controller.clearEffect();
    expect(container.read(adminVehicleDetailControllerProvider('v1')).effect, isNull);
  });
}

class _FakeAdminVehicleRepository implements AdminVehicleRepository {
  _FakeAdminVehicleRepository({
    this.delay = Duration.zero,
    this.detailResult,
  });

  final Duration delay;
  final Result<AdminVehicleDetails, AppError>? detailResult;
  int updateConfigCalls = 0;

  @override
  Future<Result<AdminVehicleDetails, AppError>> getVehicleDetail(String vehicleId) async {
    return detailResult ?? Result.success(AdminVehicleDetails.fromRaw({'id': vehicleId, 'imei': '111222333444555', 'name': 'Truck'}));
  }

  @override
  Future<Result<List<AdminUserListItem>, AppError>> getLinkedUsers(String vehicleId) async => const Result.success([]);

  @override
  Future<Result<List<AdminDocumentItem>, AppError>> getVehicleDocuments(String vehicleId) async => const Result.success([]);

  @override
  Future<Result<VehicleConfig, AppError>> getVehicleConfig(String vehicleId) async => Result.success(VehicleConfig(const <String, dynamic>{}));

  @override
  Future<Result<void, AppError>> updateVehicleConfig(String vehicleId, VehicleConfigUpdate payload) async {
    updateConfigCalls++;
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    return const Result.success(null);
  }

  @override
  Future<Result<List<AdminVehicleLogItem>, AppError>> getVehicleLogsByImei(String imei, {Map<String, Object?>? query}) async => const Result.success([]);

  @override
  Future<Result<void, AppError>> updateVehicleStatus(String vehicleId, bool isActive) async => const Result.success(null);

  @override
  Future<Result<void, AppError>> deleteVehicle(String vehicleId) async => const Result.success(null);

  @override
  Future<Result<void, AppError>> assignDriver(String vehicleId, {required String driverId}) async => const Result.success(null);

  @override
  Future<Result<void, AppError>> unassignDriver(String vehicleId) async => const Result.success(null);
}
