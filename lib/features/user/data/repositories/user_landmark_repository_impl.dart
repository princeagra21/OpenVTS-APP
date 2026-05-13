import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/data/mappers/user_landmark_mapper.dart';
import 'package:open_vts/features/user/data/sources/user_landmark_api_service.dart';
import 'package:open_vts/features/user/domain/entities/create_user_landmark_input.dart';
import 'package:open_vts/features/user/domain/entities/update_user_landmark_input.dart';
import 'package:open_vts/features/user/domain/entities/user_landmark_item.dart';
import 'package:open_vts/features/user/domain/repositories/user_landmark_repository.dart';

class UserLandmarkRepositoryImpl implements UserLandmarkRepository {
  const UserLandmarkRepositoryImpl({required UserLandmarkApiService api, required UserLandmarkMapper mapper}) : _api = api, _mapper = mapper;
  final UserLandmarkApiService _api;
  final UserLandmarkMapper _mapper;

  @override
  Future<Result<List<UserLandmarkItem>, AppError>> getGeofences() => _list(_api.getGeofences, _mapper.geofencesFromResponse);

  @override
  Future<Result<List<UserLandmarkItem>, AppError>> getRoutes() => _list(_api.getRoutes, _mapper.routesFromResponse);

  @override
  Future<Result<List<UserLandmarkItem>, AppError>> getPois() => _list(_api.getPois, _mapper.poisFromResponse);

  @override
  Future<Result<UserLandmarkItem, AppError>> createLandmark(CreateUserLandmarkInput input) async {
    try {
      final body = _mapper.createPayload(input);
      final response = switch (_mapper.collectionForShape(input.shape)) {
        'poi' => await _api.createPoi(_mapper.mutation(body)),
        'route' => await _api.createRoute(_mapper.mutation(body)),
        _ => await _api.createGeofence(_mapper.mutation(body)),
      };
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.fromMutationResponse(response, input));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<UserLandmarkItem, AppError>> updateLandmark(UpdateUserLandmarkInput input) async {
    try {
      final body = _mapper.updatePayload(input);
      final response = switch (_mapper.collectionForShape(input.shape)) {
        'poi' => await _api.updatePoi(input.id, _mapper.mutation(body)),
        'route' => await _api.updateRoute(input.id, _mapper.mutation(body)),
        _ => await _api.updateGeofence(input.id, _mapper.mutation(body)),
      };
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.fromUpdateResponse(response, input));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void, AppError>> deleteLandmark(String id) => _void(() => _api.deleteGeofence(id));

  Future<Result<List<UserLandmarkItem>, AppError>> _list(Future<ApiResponse<List<Map<String, Object?>>>> Function() request, List<UserLandmarkItem> Function(Object?) mapper) async {
    try {
      final response = await request();
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(mapper(response));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  Future<Result<void, AppError>> _void(Future<ApiResponse<void>> Function() request) async {
    try {
      final response = await request();
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return const Result.success(null);
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
