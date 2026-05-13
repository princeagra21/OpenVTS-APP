import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/data/mappers/user_route_mapper.dart';
import 'package:open_vts/features/user/data/sources/user_route_api_service.dart';
import 'package:open_vts/features/user/domain/entities/create_user_route_input.dart';
import 'package:open_vts/features/user/domain/entities/update_user_route_input.dart';
import 'package:open_vts/features/user/domain/entities/user_route_item.dart';
import 'package:open_vts/features/user/domain/repositories/user_route_repository.dart';

class UserRouteRepositoryImpl implements UserRouteRepository {
  const UserRouteRepositoryImpl({required UserRouteApiService api, required UserRouteMapper mapper}) : _api = api, _mapper = mapper;
  final UserRouteApiService _api;
  final UserRouteMapper _mapper;

  @override
  Future<Result<List<UserRouteItem>, AppError>> getRoutes() async {
    try {
      final response = await _api.getRoutes();
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
  Future<Result<UserRouteItem, AppError>> createRoute(CreateUserRouteInput input) async {
    if (!input.canPersist) return const Result.failure(ValidationError('Route must contain at least two points.'));
    try {
      final response = await _api.createRoute(_mapper.createMutation(input));
      return _routeFromResponse(response);
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<UserRouteItem, AppError>> assignRouteDriver(String routeId, String? driver) async {
    try {
      final response = await _api.updateRoute(routeId, _mapper.assignDriverMutation(driver));
      return _routeFromResponse(response);
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<UserRouteItem, AppError>> updateRoute(UpdateUserRouteInput input) async {
    if (!input.canPersist) return const Result.failure(ValidationError('Route must contain at least two points.'));
    try {
      final response = await _api.updateRoute(input.routeId, _mapper.updateMutation(input));
      return _routeFromResponse(response);
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void, AppError>> deleteRoute(String routeId) async {
    try {
      final response = await _api.deleteRoute(routeId);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return const Result.success(null);
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  Result<UserRouteItem, AppError> _routeFromResponse(Object? response) {
    final failure = _failureIfRejected(response);
    if (failure != null) return Result.failure(failure);
    final dto = _mapper.detailFromResponse(response);
    if (dto == null) return const Result.failure(ServerError('Route response is empty'));
    return Result.success(_mapper.toDomain(dto));
  }

  AppError? _failureIfRejected(Object? response) {
    if (ApiResponseNormalizer.action(response)) return null;
    return ServerError(ApiResponseNormalizer.message(response, defaultValue: 'Request failed'));
  }
}
