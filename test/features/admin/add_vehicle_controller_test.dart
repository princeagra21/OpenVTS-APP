import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/di/admin_form_providers.dart';
import 'package:open_vts/features/admin/domain/entities/add_vehicle_form_data.dart';
import 'package:open_vts/features/admin/domain/entities/admin_form_options.dart';
import 'package:open_vts/features/admin/domain/entities/create_admin_user_input.dart';
import 'package:open_vts/features/admin/domain/entities/create_admin_vehicle_input.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_form_repository.dart';
import 'package:open_vts/features/admin/presentation/controllers/add_vehicle_controller.dart';

void main() {
  test('loadInitialData populates vehicle form options', () async {
    final container = ProviderContainer(overrides: [
      adminFormRepositoryProvider.overrideWithValue(_FakeAdminFormRepository()),
    ]);
    addTearDown(container.dispose);

    await container.read(addVehicleControllerProvider.notifier).loadInitialData();

    final state = container.read(addVehicleControllerProvider);
    expect(state.users.single.fullName, 'A User');
    expect(state.quickDevices.single.imei, '123456789012345');
    expect(state.vehicleTypes.single.name, 'Truck');
    expect(state.plans.single.name, 'Growth');
  });

  test('submit prevents double submit', () async {
    final repo = _FakeAdminFormRepository(delay: const Duration(milliseconds: 50));
    final container = ProviderContainer(overrides: [
      adminFormRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    final controller = container.read(addVehicleControllerProvider.notifier);
    final first = controller.submit(
      name: 'Truck',
      vin: 'VIN123',
      plateNumber: 'DL01',
      deviceId: '123456789012345',
      vehicleTypeId: '1',
      primaryUserId: 'u1',
      planId: 'p1',
    );
    final second = await controller.submit(
      name: 'Truck',
      vin: 'VIN123',
      plateNumber: 'DL01',
      deviceId: '123456789012345',
      vehicleTypeId: '1',
      primaryUserId: 'u1',
      planId: 'p1',
    );

    expect(second, isFalse);
    expect(await first, isTrue);
    expect(repo.createVehicleCalls, 1);
  });

  test('submit validation failure becomes controller error', () async {
    final container = ProviderContainer(overrides: [
      adminFormRepositoryProvider.overrideWithValue(_FakeAdminFormRepository(
        createVehicleResult: const Result.failure(ValidationError('Invalid IMEI')),
      )),
    ]);
    addTearDown(container.dispose);

    final ok = await container.read(addVehicleControllerProvider.notifier).submit(
          name: 'Truck',
          vin: 'VIN123',
          plateNumber: 'DL01',
          deviceId: 'bad',
          vehicleTypeId: '1',
          primaryUserId: 'u1',
          planId: 'p1',
        );

    expect(ok, isFalse);
    expect(container.read(addVehicleControllerProvider).errorMessage, 'Invalid IMEI');
  });
}

class _FakeAdminFormRepository implements AdminFormRepository {
  _FakeAdminFormRepository({this.createVehicleResult, this.delay = Duration.zero});

  final Result<AdminCreatedVehicle, AppError>? createVehicleResult;
  final Duration delay;
  int createVehicleCalls = 0;

  @override
  Future<Result<AddVehicleFormData, AppError>> loadAddVehicleFormData() async {
    return const Result.success(
      AddVehicleFormData(
        users: [AdminFormUserOption(id: 'u1', fullName: 'A User')],
        quickDevices: [AdminFormQuickDeviceOption(id: 'd1', imei: '123456789012345')],
        vehicleTypes: [AdminFormVehicleTypeOption(id: '1', name: 'Truck')],
        plans: [AdminFormPlanOption(id: 'p1', name: 'Growth', price: 10, currency: 'USD')],
      ),
    );
  }

  @override
  Future<Result<AdminCreatedVehicle, AppError>> createVehicle(CreateAdminVehicleInput input) async {
    createVehicleCalls++;
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    return createVehicleResult ?? const Result.success(AdminCreatedVehicle(id: 'v1', name: 'Truck', plateNumber: 'DL01'));
  }

  @override
  Future<Result<AdminCreatedUser, AppError>> createUser(CreateAdminUserInput input) async {
    return const Result.success(AdminCreatedUser(id: 'u1', name: 'A User', email: 'a@example.com'));
  }
}
