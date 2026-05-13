import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/reference_data/domain/entities/reference_options.dart';
import 'package:open_vts/features/reference_data/domain/use_cases/get_cities_use_case.dart';
import 'package:open_vts/features/reference_data/domain/use_cases/get_countries_use_case.dart';
import 'package:open_vts/features/reference_data/domain/use_cases/get_states_use_case.dart';

class LoadSuperadminAdminFormReferenceDataUseCase {
  const LoadSuperadminAdminFormReferenceDataUseCase({
    required GetCountriesUseCase getCountries,
    required GetStatesUseCase getStates,
    required GetCitiesUseCase getCities,
  })  : _getCountries = getCountries,
        _getStates = getStates,
        _getCities = getCities;

  final GetCountriesUseCase _getCountries;
  final GetStatesUseCase _getStates;
  final GetCitiesUseCase _getCities;

  Future<Result<List<CountryOption>, AppError>> countries() {
    return _getCountries();
  }

  Future<Result<List<ReferenceOption>, AppError>> states(String countryCode) {
    return _getStates(countryCode);
  }

  Future<Result<List<ReferenceOption>, AppError>> cities(
    String countryCode,
    String stateCode,
  ) {
    return _getCities(countryCode, stateCode);
  }
}
