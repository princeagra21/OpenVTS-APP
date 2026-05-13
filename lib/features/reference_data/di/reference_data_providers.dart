import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/network/dio_provider.dart';
import 'package:open_vts/features/reference_data/data/mappers/reference_data_mapper.dart';
import 'package:open_vts/features/reference_data/data/repositories/reference_data_repository_impl.dart';
import 'package:open_vts/features/reference_data/data/sources/reference_data_api_service.dart';
import 'package:open_vts/features/reference_data/domain/repositories/reference_data_repository.dart';
import 'package:open_vts/features/reference_data/domain/use_cases/get_cities_use_case.dart';
import 'package:open_vts/features/reference_data/domain/use_cases/get_countries_use_case.dart';
import 'package:open_vts/features/reference_data/domain/use_cases/get_mobile_prefixes_use_case.dart';
import 'package:open_vts/features/reference_data/domain/use_cases/get_states_use_case.dart';

export 'package:open_vts/features/reference_data/domain/entities/reference_options.dart';

final referenceDataApiServiceProvider = Provider<ReferenceDataApiService>((ref) {
  return ReferenceDataApiService(ref.watch(appDioProvider));
});

final referenceDataMapperProvider = Provider<ReferenceDataMapper>((ref) {
  return const ReferenceDataMapper();
});

final referenceDataRepositoryProvider = Provider<ReferenceDataRepository>((ref) {
  return ReferenceDataRepositoryImpl(
    api: ref.watch(referenceDataApiServiceProvider),
    mapper: ref.watch(referenceDataMapperProvider),
  );
});

final getCountriesUseCaseProvider = Provider<GetCountriesUseCase>((ref) {
  return GetCountriesUseCase(ref.watch(referenceDataRepositoryProvider));
});

final getStatesUseCaseProvider = Provider<GetStatesUseCase>((ref) {
  return GetStatesUseCase(ref.watch(referenceDataRepositoryProvider));
});

final getCitiesUseCaseProvider = Provider<GetCitiesUseCase>((ref) {
  return GetCitiesUseCase(ref.watch(referenceDataRepositoryProvider));
});

final getMobilePrefixesUseCaseProvider = Provider<GetMobilePrefixesUseCase>((ref) {
  return GetMobilePrefixesUseCase(ref.watch(referenceDataRepositoryProvider));
});
