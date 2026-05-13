import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/reference_data/domain/entities/reference_options.dart';

abstract interface class ReferenceDataRepository {
  Future<Result<List<CountryOption>, AppError>> getCountries({Object? cancelToken});
  Future<Result<List<ReferenceOption>, AppError>> getStates(String countryCode, {Object? cancelToken});
  Future<Result<List<ReferenceOption>, AppError>> getCities(String countryCode, String stateCode, {Object? cancelToken});
  Future<Result<List<MobilePrefixOption>, AppError>> getMobilePrefixes({Object? cancelToken});
  Future<Result<List<ReferenceOption>, AppError>> getVehicleTypes({Object? cancelToken});
  Future<Result<List<ReferenceOption>, AppError>> getLanguages({Object? cancelToken});
  Future<Result<List<ReferenceOption>, AppError>> getDateFormats({Object? cancelToken});
  Future<Result<List<TimezoneOption>, AppError>> getTimezones({Object? cancelToken});
}
