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
import 'package:open_vts/features/admin/presentation/controllers/add_user_controller.dart';
import 'package:open_vts/features/reference_data/di/reference_data_providers.dart';
import 'package:open_vts/features/reference_data/domain/entities/reference_options.dart';
import 'package:open_vts/features/reference_data/domain/repositories/reference_data_repository.dart';

void main() {
  test('loadReferenceData populates countries and prefixes', () async {
    final container = ProviderContainer(overrides: [
      referenceDataRepositoryProvider.overrideWithValue(_FakeReferenceDataRepository()),
      adminFormRepositoryProvider.overrideWithValue(_FakeAdminFormRepository()),
    ]);
    addTearDown(container.dispose);

    await container.read(addUserControllerProvider.notifier).loadReferenceData();

    final state = container.read(addUserControllerProvider);
    expect(state.countries.single.isoCode, 'IN');
    expect(state.prefixes.single.code, '+91');
  });

  test('submit emits success and prevents duplicate submit', () async {
    final formRepo = _FakeAdminFormRepository(delay: const Duration(milliseconds: 50));
    final container = ProviderContainer(overrides: [
      referenceDataRepositoryProvider.overrideWithValue(_FakeReferenceDataRepository()),
      adminFormRepositoryProvider.overrideWithValue(formRepo),
    ]);
    addTearDown(container.dispose);

    final controller = container.read(addUserControllerProvider.notifier);
    final first = controller.submit(
      name: 'A User',
      email: 'a@example.com',
      mobilePrefix: '+91',
      mobileNumber: '9876543210',
      username: 'auser',
      password: 'secret123',
      companyName: 'Acme',
      address: 'Street',
      countryCode: 'IN',
      stateCode: 'DL',
      city: 'Delhi',
      pincode: '110001',
    );
    final second = await controller.submit(
      name: 'A User',
      email: 'a@example.com',
      mobilePrefix: '+91',
      mobileNumber: '9876543210',
      username: 'auser',
      password: 'secret123',
      companyName: 'Acme',
      address: 'Street',
      countryCode: 'IN',
      stateCode: 'DL',
      city: 'Delhi',
      pincode: '110001',
    );

    expect(second, isFalse);
    expect(await first, isTrue);
    expect(formRepo.createUserCalls, 1);
  });

  test('submit failure is surfaced as controller error message', () async {
    final container = ProviderContainer(overrides: [
      referenceDataRepositoryProvider.overrideWithValue(_FakeReferenceDataRepository()),
      adminFormRepositoryProvider.overrideWithValue(_FakeAdminFormRepository(
        createUserResult: const Result.failure(ValidationError('Invalid email')),
      )),
    ]);
    addTearDown(container.dispose);

    final ok = await container.read(addUserControllerProvider.notifier).submit(
          name: 'A User',
          email: 'bad',
          mobilePrefix: '+91',
          mobileNumber: '9876543210',
          username: 'auser',
          password: 'secret123',
          companyName: 'Acme',
          address: 'Street',
          countryCode: 'IN',
          stateCode: 'DL',
          city: 'Delhi',
          pincode: '110001',
        );

    expect(ok, isFalse);
    expect(container.read(addUserControllerProvider).errorMessage, 'Invalid email');
  });
}

class _FakeReferenceDataRepository implements ReferenceDataRepository {
  @override
  Future<Result<List<CountryOption>, AppError>> getCountries() async {
    return const Result.success([CountryOption(name: 'India', isoCode: 'IN')]);
  }

  @override
  Future<Result<List<ReferenceOption>, AppError>> getStates(String countryCode) async {
    return const Result.success([ReferenceOption(value: 'DL', label: 'Delhi')]);
  }

  @override
  Future<Result<List<ReferenceOption>, AppError>> getCities(String countryCode, String stateCode) async {
    return const Result.success([ReferenceOption(value: 'DEL', label: 'Delhi')]);
  }

  @override
  Future<Result<List<MobilePrefixOption>, AppError>> getMobilePrefixes() async {
    return const Result.success([MobilePrefixOption(countryCode: 'IN', code: '+91')]);
  }
}

class _FakeAdminFormRepository implements AdminFormRepository {
  _FakeAdminFormRepository({this.createUserResult, this.delay = Duration.zero});

  final Result<AdminCreatedUser, AppError>? createUserResult;
  final Duration delay;
  int createUserCalls = 0;

  @override
  Future<Result<AdminCreatedUser, AppError>> createUser(CreateAdminUserInput input) async {
    createUserCalls++;
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    return createUserResult ?? const Result.success(AdminCreatedUser(id: 'u1', name: 'A User', email: 'a@example.com'));
  }

  @override
  Future<Result<AdminCreatedVehicle, AppError>> createVehicle(CreateAdminVehicleInput input) async {
    return const Result.success(AdminCreatedVehicle(id: 'v1', name: 'Truck', plateNumber: 'DL01'));
  }

  @override
  Future<Result<AddVehicleFormData, AppError>> loadAddVehicleFormData() async {
    return const Result.success(AddVehicleFormData(users: [], quickDevices: [], vehicleTypes: [], plans: []));
  }
}
