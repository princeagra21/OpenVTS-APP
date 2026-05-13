import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/di/admin_device_providers.dart';
import 'package:open_vts/features/admin/domain/entities/admin_device_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_device_mutation_input.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_device_repository.dart';
import 'package:open_vts/features/admin/presentation/controllers/admin_device_list_controller.dart';
import 'package:open_vts/features/vehicles/domain/entities/device_type_option.dart';
import 'package:open_vts/features/vehicles/domain/entities/sim_option.dart';
import 'package:open_vts/features/vehicles/domain/entities/sim_provider_option.dart';

void main() {
  test('loadDevices populates list state', () async {
    final container = ProviderContainer(overrides: [
      adminDeviceRepositoryProvider.overrideWithValue(_FakeAdminDeviceRepository()),
    ]);
    addTearDown(container.dispose);

    await container.read(adminDeviceListControllerProvider.notifier).loadDevices();

    final state = container.read(adminDeviceListControllerProvider);
    expect(state.items.single.imei, '123456789012345');
    expect(state.isLoading, isFalse);
  });

  test('updateStatus blocks duplicate in-flight update path by id', () async {
    final repo = _FakeAdminDeviceRepository(delay: const Duration(milliseconds: 50));
    final container = ProviderContainer(overrides: [adminDeviceRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);

    await container.read(adminDeviceListControllerProvider.notifier).loadDevices();
    final item = container.read(adminDeviceListControllerProvider).items.single;
    final first = container.read(adminDeviceListControllerProvider.notifier).updateStatus(item, false);
    final second = await container.read(adminDeviceListControllerProvider.notifier).updateStatus(item, true);

    expect(second, isFalse);
    expect(await first, isTrue);
    expect(repo.updateCalls, 1);
  });
}

class _FakeAdminDeviceRepository implements AdminDeviceRepository {
  _FakeAdminDeviceRepository({this.delay = Duration.zero});
  final Duration delay;
  int updateCalls = 0;

  @override
  Future<Result<List<AdminDeviceListItem>, AppError>> getDevices({String? search, String? status, int? page, int? limit}) async {
    return Result.success([AdminDeviceListItem.fromRaw({'id': 'dev1', 'imei': '123456789012345', 'isActive': true})]);
  }

  @override
  Future<Result<AdminDeviceListItem, AppError>> getDeviceDetail(String deviceId) async => Result.success(AdminDeviceListItem.fromRaw({'id': deviceId}));

  @override
  Future<Result<void, AppError>> updateDeviceStatus(String deviceId, bool isActive) async {
    updateCalls++;
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    return const Result.success(null);
  }

  @override
  Future<Result<List<DeviceTypeOption>, AppError>> getDeviceTypes() async => const Result.success([]);

  @override
  Future<Result<List<SimOption>, AppError>> getSims() async => const Result.success([]);

  @override
  Future<Result<List<SimProviderOption>, AppError>> getSimProviders() async => const Result.success([]);

  @override
  Future<Result<List<SimOption>, AppError>> getQuickSimCards() async => const Result.success([]);

  @override
  Future<Result<void, AppError>> createSimCard(CreateAdminSimCardMutationInput input) async => const Result.success(null);

  @override
  Future<Result<void, AppError>> createDevice(CreateAdminDeviceMutationInput input) async => const Result.success(null);

  @override
  Future<Result<void, AppError>> createDeviceAndSim(CreateAdminDeviceAndSimMutationInput input) async => const Result.success(null);

  @override
  Future<Result<void, AppError>> updateDevice(String deviceId, UpdateAdminDeviceMutationInput input) async => const Result.success(null);
}
