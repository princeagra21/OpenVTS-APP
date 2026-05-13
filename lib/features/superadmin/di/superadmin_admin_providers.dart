import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/network/dio_provider.dart';
import 'package:open_vts/core/providers/repository_providers.dart' show sessionServiceProvider;
import 'package:open_vts/features/superadmin/data/mappers/superadmin_admin_mapper.dart';
import 'package:open_vts/features/superadmin/data/repositories/superadmin_admin_repository_impl.dart';
import 'package:open_vts/features/superadmin/data/sources/superadmin_admin_api_service.dart';
import 'package:open_vts/features/superadmin/domain/repositories/superadmin_admin_repository.dart';
import 'package:open_vts/features/superadmin/domain/use_cases/create_superadmin_admin_use_case.dart';
import 'package:open_vts/features/superadmin/domain/use_cases/get_superadmin_admin_detail_use_case.dart';
import 'package:open_vts/features/superadmin/domain/use_cases/get_superadmin_admins_use_case.dart';
import 'package:open_vts/features/superadmin/domain/use_cases/update_superadmin_admin_use_case.dart';
import 'package:open_vts/features/superadmin/domain/use_cases/load_superadmin_admin_form_reference_data_use_case.dart';
import 'package:open_vts/features/superadmin/domain/use_cases/login_as_superadmin_admin_use_case.dart';
import 'package:open_vts/features/superadmin/domain/use_cases/update_superadmin_company_use_case.dart';
import 'package:open_vts/features/reference_data/di/reference_data_providers.dart' show getCountriesUseCaseProvider, getStatesUseCaseProvider, getCitiesUseCaseProvider;

final superadminAdminApiServiceProvider = Provider<SuperadminAdminApiService>((ref) {
  return SuperadminAdminApiService(ref.watch(appDioProvider));
});

final superadminAdminMapperProvider = Provider<SuperadminAdminMapper>((ref) => const SuperadminAdminMapper());

final superadminAdminRepositoryProvider = Provider<SuperadminAdminRepository>((ref) {
  return SuperadminAdminRepositoryImpl(
    api: ref.watch(superadminAdminApiServiceProvider),
    mapper: ref.watch(superadminAdminMapperProvider),
  );
});

final getSuperadminAdminsUseCaseProvider = Provider<GetSuperadminAdminsUseCase>((ref) {
  return GetSuperadminAdminsUseCase(ref.watch(superadminAdminRepositoryProvider));
});

final getSuperadminAdminDetailUseCaseProvider = Provider<GetSuperadminAdminDetailUseCase>((ref) {
  return GetSuperadminAdminDetailUseCase(ref.watch(superadminAdminRepositoryProvider));
});

final createSuperadminAdminUseCaseProvider = Provider<CreateSuperadminAdminUseCase>((ref) {
  return CreateSuperadminAdminUseCase(ref.watch(superadminAdminRepositoryProvider));
});

final updateSuperadminAdminUseCaseProvider = Provider<UpdateSuperadminAdminUseCase>((ref) {
  return UpdateSuperadminAdminUseCase(ref.watch(superadminAdminRepositoryProvider));
});

final superadminSessionServiceProvider = sessionServiceProvider;


final loadSuperadminAdminFormReferenceDataUseCaseProvider =
    Provider<LoadSuperadminAdminFormReferenceDataUseCase>((ref) {
  return LoadSuperadminAdminFormReferenceDataUseCase(
    getCountries: ref.watch(getCountriesUseCaseProvider),
    getStates: ref.watch(getStatesUseCaseProvider),
    getCities: ref.watch(getCitiesUseCaseProvider),
  );
});

final updateSuperadminCompanyUseCaseProvider = Provider<UpdateSuperadminCompanyUseCase>((ref) {
  return UpdateSuperadminCompanyUseCase(ref.watch(superadminAdminRepositoryProvider));
});

final loginAsSuperadminAdminUseCaseProvider = Provider<LoginAsSuperadminAdminUseCase>((ref) {
  return LoginAsSuperadminAdminUseCase(ref.watch(superadminAdminRepositoryProvider));
});
