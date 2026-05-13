import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/reference_data/di/reference_data_providers.dart';
import 'package:open_vts/features/reference_data/domain/entities/reference_options.dart';
import 'package:open_vts/features/reference_data/domain/repositories/reference_data_repository.dart';
import 'package:open_vts/features/reference_data/domain/use_cases/get_cities_use_case.dart';
import 'package:open_vts/features/reference_data/domain/use_cases/get_countries_use_case.dart';
import 'package:open_vts/features/reference_data/domain/use_cases/get_states_use_case.dart';
import 'package:open_vts/features/superadmin/di/superadmin_admin_providers.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_admin.dart';
import 'package:open_vts/features/superadmin/domain/repositories/superadmin_admin_repository.dart';
import 'package:open_vts/features/superadmin/presentation/controllers/superadmin_admin_form_controller.dart';

void main() {
  test('load reference data success', () async {
    final container = _container(
      referenceRepository: _FakeReferenceDataRepository(),
      adminRepository: _FakeSuperadminAdminRepository(),
    );
    addTearDown(container.dispose);

    await container.read(superadminAdminFormControllerProvider.notifier).loadReferenceData();

    final state = container.read(superadminAdminFormControllerProvider);
    expect(state.countries, isNotEmpty);
    expect(state.selectedCountry?.isoCode, 'IN');
    expect(state.isLoadingReferenceData, isFalse);
  });

  test('load reference data failure emits error effect', () async {
    final container = _container(
      referenceRepository: _FakeReferenceDataRepository(failCountries: true),
      adminRepository: _FakeSuperadminAdminRepository(),
    );
    addTearDown(container.dispose);

    await container.read(superadminAdminFormControllerProvider.notifier).loadReferenceData();

    final state = container.read(superadminAdminFormControllerProvider);
    expect(state.errorMessage, isNotNull);
    expect(state.effect?.isSuccess, isFalse);
  });

  test('create admin success emits effect', () async {
    final container = _container(
      referenceRepository: _FakeReferenceDataRepository(),
      adminRepository: _FakeSuperadminAdminRepository(),
    );
    addTearDown(container.dispose);

    final ok = await container.read(superadminAdminFormControllerProvider.notifier).submitCreateAdmin(
          name: 'Admin',
          email: 'admin@example.com',
          phone: '9999999999',
          username: 'admin',
          password: 'secret123',
          company: 'OpenVTS',
        );

    final state = container.read(superadminAdminFormControllerProvider);
    expect(ok, isTrue);
    expect(state.isSubmitting, isFalse);
    expect(state.effect?.isSuccess, isTrue);
  });

  test('create admin failure emits error', () async {
    final container = _container(
      referenceRepository: _FakeReferenceDataRepository(),
      adminRepository: _FakeSuperadminAdminRepository(failCreate: true),
    );
    addTearDown(container.dispose);

    final ok = await container.read(superadminAdminFormControllerProvider.notifier).submitCreateAdmin(
          name: 'Admin',
          email: 'admin@example.com',
          phone: '9999999999',
          username: 'admin',
          password: 'secret123',
          company: 'OpenVTS',
        );

    final state = container.read(superadminAdminFormControllerProvider);
    expect(ok, isFalse);
    expect(state.errorMessage, isNotNull);
    expect(state.effect?.isSuccess, isFalse);
  });

  test('double submit is blocked', () async {
    final repo = _FakeSuperadminAdminRepository(delayCreate: true);
    final container = _container(
      referenceRepository: _FakeReferenceDataRepository(),
      adminRepository: repo,
    );
    addTearDown(container.dispose);

    final controller = container.read(superadminAdminFormControllerProvider.notifier);
    final first = controller.submitCreateAdmin(
      name: 'Admin',
      email: 'admin@example.com',
      phone: '9999999999',
      username: 'admin',
      password: 'secret123',
      company: 'OpenVTS',
    );
    final second = await controller.submitCreateAdmin(
      name: 'Admin',
      email: 'admin@example.com',
      phone: '9999999999',
      username: 'admin',
      password: 'secret123',
      company: 'OpenVTS',
    );
    await first;

    expect(second, isFalse);
    expect(repo.createCalls, 1);
  });

  test('clearEffect works', () async {
    final container = _container(
      referenceRepository: _FakeReferenceDataRepository(),
      adminRepository: _FakeSuperadminAdminRepository(),
    );
    addTearDown(container.dispose);

    final controller = container.read(superadminAdminFormControllerProvider.notifier);
    await controller.submitCreateAdmin(
      name: 'Admin',
      email: 'admin@example.com',
      phone: '9999999999',
      username: 'admin',
      password: 'secret123',
      company: 'OpenVTS',
    );
    controller.clearEffect();

    expect(container.read(superadminAdminFormControllerProvider).effect, isNull);
  });
}

ProviderContainer _container({
  required ReferenceDataRepository referenceRepository,
  required SuperadminAdminRepository adminRepository,
}) {
  return ProviderContainer(
    overrides: [
      getCountriesUseCaseProvider.overrideWithValue(GetCountriesUseCase(referenceRepository)),
      getStatesUseCaseProvider.overrideWithValue(GetStatesUseCase(referenceRepository)),
      getCitiesUseCaseProvider.overrideWithValue(GetCitiesUseCase(referenceRepository)),
      superadminAdminRepositoryProvider.overrideWithValue(adminRepository),
    ],
  );
}

class _FakeReferenceDataRepository implements ReferenceDataRepository {
  _FakeReferenceDataRepository({this.failCountries = false});

  final bool failCountries;

  @override
  Future<Result<List<CountryOption>, AppError>> getCountries({Object? cancelToken}) async {
    if (failCountries) return const Result.failure(ServerError('No countries'));
    return const Result.success([CountryOption(name: 'India', isoCode: 'IN')]);
  }

  @override
  Future<Result<List<ReferenceOption>, AppError>> getStates(String countryCode, {Object? cancelToken}) async {
    return const Result.success([ReferenceOption(value: 'UP', label: 'Uttar Pradesh')]);
  }

  @override
  Future<Result<List<ReferenceOption>, AppError>> getCities(String countryCode, String stateCode, {Object? cancelToken}) async {
    return const Result.success([ReferenceOption(value: 'Noida', label: 'Noida')]);
  }

  @override
  Future<Result<List<ReferenceOption>, AppError>> getDateFormats({Object? cancelToken}) async => const Result.success([]);
  @override
  Future<Result<List<ReferenceOption>, AppError>> getLanguages({Object? cancelToken}) async => const Result.success([]);
  @override
  Future<Result<List<MobilePrefixOption>, AppError>> getMobilePrefixes({Object? cancelToken}) async => const Result.success([]);
  @override
  Future<Result<List<TimezoneOption>, AppError>> getTimezones({Object? cancelToken}) async => const Result.success([]);
  @override
  Future<Result<List<ReferenceOption>, AppError>> getVehicleTypes({Object? cancelToken}) async => const Result.success([]);
}

class _FakeSuperadminAdminRepository implements SuperadminAdminRepository {
  _FakeSuperadminAdminRepository({this.failCreate = false, this.delayCreate = false});

  final bool failCreate;
  final bool delayCreate;
  int createCalls = 0;

  @override
  Future<Result<void, AppError>> createAdmin(SuperadminAdminMutationInput input) async {
    createCalls++;
    if (delayCreate) await Future<void>.delayed(const Duration(milliseconds: 10));
    if (failCreate) return const Result.failure(ServerError('Create failed'));
    return const Result.success(null);
  }

  @override
  Future<Result<SuperadminAdminDetail, AppError>> getAdminDetail(String adminId) async => Result.success(_detail(adminId));
  @override
  Future<Result<List<SuperadminAdminListItem>, AppError>> getAdmins({int? page, int? limit, String? status}) async => const Result.success([]);
  @override
  Future<Result<String, AppError>> loginAsAdmin(String adminId) async => const Result.success('token');
  @override
  Future<Result<SuperadminAdminDetail, AppError>> updateAdmin(String adminId, SuperadminAdminMutationInput input) async => Result.success(_detail(adminId));
  @override
  Future<Result<void, AppError>> updateAdminStatus(String adminId, bool isActive) async => const Result.success(null);
  @override
  Future<Result<void, AppError>> updateCompanyConfig(String companyId, SuperadminAdminMutationInput input) async => const Result.success(null);
  @override
  Future<Result<void, AppError>> updateCompanyDetails(SuperadminAdminMutationInput input) async => const Result.success(null);

  SuperadminAdminDetail _detail(String id) => SuperadminAdminDetail(
        id: id,
        name: 'Admin',
        username: 'admin',
        email: 'admin@example.com',
        mobilePrefix: '+91',
        mobileNumber: '9999999999',
        companyName: 'OpenVTS',
        website: '',
        isActive: true,
        isVerified: true,
        addressLine: '',
        city: '',
        state: '',
        country: '',
        postalCode: '',
      );
}
