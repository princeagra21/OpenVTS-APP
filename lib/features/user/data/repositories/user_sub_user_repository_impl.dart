import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/data/mappers/user_sub_user_mapper.dart';
import 'package:open_vts/features/user/data/sources/user_sub_user_api_service.dart';
import 'package:open_vts/features/user/domain/entities/user_subuser_item.dart';
import 'package:open_vts/features/user/domain/repositories/user_sub_user_repository.dart';
import 'package:open_vts/features/user/data/models/user_sub_user_dtos.dart';

class UserSubUserRepositoryImpl implements UserSubUserRepository {
  const UserSubUserRepositoryImpl({required UserSubUserApiService api, required UserSubUserMapper mapper}) : _api = api, _mapper = mapper;

  final UserSubUserApiService _api;
  final UserSubUserMapper _mapper;

  @override
  Future<Result<List<UserSubUserItem>, AppError>> getSubUsers({int page = 1, int limit = 10}) async {
    try {
      final response = await _api.getSubUsers(page: page, limit: limit);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.listFromResponse(response).map(_mapper.toDomain).toList(growable: false));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<UserSubUserItem, AppError>> getSubUserDetail(String id) async {
    try {
      final response = await _api.getSubUserDetail(id);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      final dto = _mapper.detailFromResponse(response);
      if (dto == null) return const Result.failure(ServerError('Sub-user response is empty'));
      return Result.success(_mapper.toDomain(dto));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<UserSubUserItem, AppError>> createSubUser(Map<String, Object?> payload) async {
    try {
      final response = await _api.createSubUser(_mapper.mutation(payload));
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      final dto = _mapper.detailFromResponse(response);
      if (dto == null) return const Result.failure(ServerError('Sub-user create response is empty'));
      return Result.success(_mapper.toDomain(dto));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<UserSubUserItem, AppError>> updateSubUser(String id, Map<String, Object?> payload) async {
    try {
      final response = await _api.updateSubUser(id, _mapper.mutation(payload));
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      final dto = _mapper.detailFromResponse(response);
      return Result.success(dto == null ? UserSubUserItem(<String, dynamic>{'id': id, ...payload}) : _mapper.toDomain(dto));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void, AppError>> deleteSubUser(String id) async {
    try {
      final response = await _api.deleteSubUser(id);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return const Result.success(null);
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<List<Map<String, Object?>>, AppError>> getSubUserVehicles(String id) async {
    try {
      final response = await _api.getSubUserVehicles(id);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.vehiclesFromResponse(response));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void, AppError>> assignVehicle(String id, List<int> vehicleIds) async {
    try {
      final response = await _api.assignVehicle(id, UserSubUserMutationDto(<String, Object?>{'vehicleIds': vehicleIds}));
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return const Result.success(null);
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void, AppError>> unassignVehicle(String id, List<int> vehicleIds) async {
    try {
      final response = await _api.unassignVehicle(id, UserSubUserMutationDto(<String, Object?>{'vehicleIds': vehicleIds}));
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return const Result.success(null);
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  AppError? _failureIfRejected(Object? response) {
    if (ApiResponseNormalizer.action(response)) return null;
    return ServerError(ApiResponseNormalizer.message(response, defaultValue: 'Request failed'));
  }
}
