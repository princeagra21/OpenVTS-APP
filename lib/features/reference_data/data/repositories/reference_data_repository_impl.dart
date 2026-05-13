import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/reference_data/data/mappers/reference_data_mapper.dart';
import 'package:open_vts/features/reference_data/data/sources/reference_data_api_service.dart';
import 'package:open_vts/features/reference_data/domain/entities/reference_options.dart';
import 'package:open_vts/features/reference_data/domain/repositories/reference_data_repository.dart';

class ReferenceDataRepositoryImpl implements ReferenceDataRepository {
  const ReferenceDataRepositoryImpl({
    required ReferenceDataApiService api,
    required ReferenceDataMapper mapper,
  })  : _api = api,
        _mapper = mapper;

  final ReferenceDataApiService _api;
  final ReferenceDataMapper _mapper;

  @override
  Future<Result<List<CountryOption>, AppError>> getCountries({Object? cancelToken}) async {
    try {
      final response = await _api.getCountries();
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      if (response.payload == null) {
        return const Result.failure(ServerError('Countries response is empty'));
      }
      final data = _mapper.countriesFromResponse(response);
      final countries = data.map(_mapper.country).where((e) => e.name.isNotEmpty && e.isoCode.isNotEmpty).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return Result.success(countries);
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<List<ReferenceOption>, AppError>> getStates(String countryCode, {Object? cancelToken}) async {
    if (countryCode.trim().isEmpty) return const Result.success([]);
    try {
      final response = await _api.getStates(countryCode.trim());
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      if (response.payload == null) {
        return const Result.failure(ServerError('States response is empty'));
      }
      final data = _mapper.statesFromResponse(response);
      return Result.success(data.map(_mapper.state).where((e) => e.value.isNotEmpty && e.label.isNotEmpty).toList());
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<List<ReferenceOption>, AppError>> getCities(String countryCode, String stateCode, {Object? cancelToken}) async {
    if (countryCode.trim().isEmpty || stateCode.trim().isEmpty) return const Result.success([]);
    try {
      final response = await _api.getCities(countryCode.trim(), stateCode.trim());
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      if (response.payload == null) {
        return const Result.failure(ServerError('Cities response is empty'));
      }
      final data = _mapper.citiesFromResponse(response);
      return Result.success(data.map(_mapper.city).where((e) => e.value.isNotEmpty && e.label.isNotEmpty).toList());
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<List<MobilePrefixOption>, AppError>> getMobilePrefixes({Object? cancelToken}) async {
    try {
      final response = await _api.getMobilePrefixes();
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      if (response.payload == null) {
        return const Result.failure(ServerError('Mobile prefixes response is empty'));
      }
      final data = _mapper.mobilePrefixesFromResponse(response);
      final prefixes = data.map(_mapper.mobilePrefix).where((e) => e.countryCode.isNotEmpty && e.code.isNotEmpty).toList()
        ..sort((a, b) => a.countryCode.compareTo(b.countryCode));
      return Result.success(prefixes);
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<List<ReferenceOption>, AppError>> getVehicleTypes({Object? cancelToken}) async {
    return _getGenericList(
      call: _api.getVehicleTypes,
      preferredKeys: const <String>['types', 'vehicleTypes'],
      emptyMessage: 'Vehicle types response is empty',
    );
  }

  @override
  Future<Result<List<ReferenceOption>, AppError>> getLanguages({Object? cancelToken}) async {
    return _getGenericList(
      call: _api.getLanguages,
      preferredKeys: const <String>['languages'],
      emptyMessage: 'Languages response is empty',
    );
  }

  @override
  Future<Result<List<ReferenceOption>, AppError>> getDateFormats({Object? cancelToken}) async {
    return _getGenericList(
      call: _api.getDateFormats,
      preferredKeys: const <String>['dateFormats'],
      emptyMessage: 'Date formats response is empty',
    );
  }

  @override
  Future<Result<List<TimezoneOption>, AppError>> getTimezones({Object? cancelToken}) async {
    try {
      final response = await _api.getTimezones();
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      if (response.payload == null) {
        return const Result.failure(ServerError('Timezones response is empty'));
      }
      final data = _mapper.timezonesFromResponse(response);
      return Result.success(data.map(_mapper.timezone).where((e) => e.value.isNotEmpty).toList());
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  Future<Result<List<ReferenceOption>, AppError>> _getGenericList({
    required Future<ApiResponse<List<Map<String, Object?>>>> Function() call,
    required Iterable<String> preferredKeys,
    required String emptyMessage,
  }) async {
    try {
      final response = await call();
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      if (response.payload == null) {
        return Result.failure(ServerError(emptyMessage));
      }
      final data = _mapper.genericReferencesFromResponse(response, preferredKeys: preferredKeys);
      return Result.success(data.map(_mapper.genericReference).where((e) => e.value.isNotEmpty && e.label.isNotEmpty).toList());
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  AppError? _failureIfRejected<T>(ApiResponse<T> response) {
    if (response.action) return null;
    return ServerError(response.message.trim().isEmpty ? 'Request failed' : response.message);
  }
}
