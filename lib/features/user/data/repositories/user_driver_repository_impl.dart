import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_list_item.dart';
import 'package:open_vts/features/user/data/mappers/user_driver_mapper.dart';
import 'package:open_vts/features/user/data/sources/user_driver_api_service.dart';
import 'package:open_vts/features/user/domain/entities/user_driver_details.dart';
import 'package:open_vts/features/user/domain/repositories/user_driver_repository.dart';
import 'package:open_vts/features/user/data/models/user_driver_dtos.dart';

class UserDriverRepositoryImpl implements UserDriverRepository {
  const UserDriverRepositoryImpl({required UserDriverApiService api, required UserDriverMapper mapper}) : _api = api, _mapper = mapper;
  final UserDriverApiService _api;
  final UserDriverMapper _mapper;

  @override
  Future<Result<List<AdminDriverListItem>, AppError>> getDrivers() async {
    try {
      final response = await _api.getDrivers();
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.listFromResponse(response).map(_mapper.listItem).toList(growable: false));
    } on DioException catch (error) { return Result.failure(AppErrorMapper.fromDio(error)); } catch (error) { return Result.failure(AppErrorMapper.fromObject(error)); }
  }

  @override
  Future<Result<UserDriverDetails, AppError>> getDriverDetail(String id) async {
    try {
      final response = await _api.getDriverDetail(id);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      final dto = _mapper.detailFromResponse(response);
      if (dto == null) return const Result.failure(ServerError('Driver response is empty'));
      return Result.success(_mapper.details(dto));
    } on DioException catch (error) { return Result.failure(AppErrorMapper.fromDio(error)); } catch (error) { return Result.failure(AppErrorMapper.fromObject(error)); }
  }

  @override
  Future<Result<AdminDriverListItem, AppError>> createDriver(Map<String, Object?> payload) async {
    try {
      final response = await _api.createDriver(_mapper.mutation(payload));
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      final dto = _mapper.detailFromResponse(response);
      if (dto == null) return const Result.failure(ServerError('Driver create response is empty'));
      return Result.success(_mapper.listItem(dto));
    } on DioException catch (error) { return Result.failure(AppErrorMapper.fromDio(error)); } catch (error) { return Result.failure(AppErrorMapper.fromObject(error)); }
  }

  @override
  Future<Result<void, AppError>> updateDriver(String id, Map<String, Object?> payload) async {
    try {
      final response = await _api.updateDriver(id, _mapper.mutation(payload));
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return const Result.success(null);
    } on DioException catch (error) { return Result.failure(AppErrorMapper.fromDio(error)); } catch (error) { return Result.failure(AppErrorMapper.fromObject(error)); }
  }

  @override
  Future<Result<void, AppError>> deleteDriver(String id) async {
    try {
      final response = await _api.deleteDriver(id, UserDriverMutationDto(<String, Object?>{'driverId': id}));
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return const Result.success(null);
    } on DioException catch (error) { return Result.failure(AppErrorMapper.fromDio(error)); } catch (error) { return Result.failure(AppErrorMapper.fromObject(error)); }
  }

  AppError? _failureIfRejected(Object? response) {
    if (ApiResponseNormalizer.action(response)) return null;
    return ServerError(ApiResponseNormalizer.message(response, defaultValue: 'Request failed'));
  }
}
