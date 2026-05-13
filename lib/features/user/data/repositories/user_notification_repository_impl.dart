import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/data/mappers/user_notification_mapper.dart';
import 'package:open_vts/features/user/data/sources/user_notification_api_service.dart';
import 'package:open_vts/features/user/domain/entities/user_notification_item.dart';
import 'package:open_vts/features/user/domain/entities/user_notification_preferences.dart';
import 'package:open_vts/features/user/domain/repositories/user_notification_repository.dart';

class UserNotificationRepositoryImpl implements UserNotificationRepository {
  const UserNotificationRepositoryImpl({required UserNotificationApiService api, required UserNotificationMapper mapper}) : _api = api, _mapper = mapper;
  final UserNotificationApiService _api;
  final UserNotificationMapper _mapper;

  @override
  Future<Result<List<UserNotificationItem>, AppError>> getNotifications() async {
    try {
      final response = await _api.getNotifications();
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.toNotifications(_mapper.notificationsFromResponse(response)));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void, AppError>> markNotificationRead(String id) => _void(() => _api.markNotificationRead(id));

  @override
  Future<Result<void, AppError>> markAllNotificationsRead() => _void(_api.markAllNotificationsRead);

  @override
  Future<Result<UserNotificationPreferences, AppError>> getPreferences() async {
    try {
      final response = await _api.getPreferences();
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.toPreferences(_mapper.preferencesFromResponse(response)));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void, AppError>> updatePreferences(Map<String, Object?> payload) => _void(() => _api.updatePreferences(_mapper.mutation(payload)));

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
