import 'package:open_vts/features/superadmin/data/models/superadmin_settings_dtos.dart';
import 'package:open_vts/features/superadmin/data/models/superadmin_role_dtos.dart';
import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/superadmin/data/mappers/superadmin_role_mapper.dart';
import 'package:open_vts/features/superadmin/data/mappers/superadmin_settings_mapper.dart';
import 'package:open_vts/features/superadmin/data/sources/superadmin_settings_api_service.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_settings.dart';
import 'package:open_vts/features/superadmin/domain/repositories/superadmin_settings_repository.dart';

class SuperadminSettingsRepositoryImpl implements SuperadminSettingsRepository {
  const SuperadminSettingsRepositoryImpl({
    required SuperadminSettingsApiService api,
    required SuperadminSettingsMapper settingsMapper,
    required SuperadminRoleMapper roleMapper,
  })  : _api = api,
        _settingsMapper = settingsMapper,
        _roleMapper = roleMapper;

  final SuperadminSettingsApiService _api;
  final SuperadminSettingsMapper _settingsMapper;
  final SuperadminRoleMapper _roleMapper;

  @override
  Future<Result<SuperadminSettingsData, AppError>> getSettings(String adminId) async {
    try {
      final response = await _api.getSettings(adminId);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_settingsMapper.settings(_settingsMapper.settingsFromResponse(response)));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<SuperadminSettingsData, AppError>> updateSettings(String adminId, SuperadminSettingsData settings) async {
    try {
      final response = await _api.updateSettings(adminId, SuperadminSettingsMutationDto(_settingsMapper.updatePayload(settings)));
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_settingsMapper.settings(_settingsMapper.settingsFromResponse(response)));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<List<SuperadminRole>, AppError>> getRoles() async {
    final loaders = <Future<ApiResponse<List<Map<String, dynamic>>>> Function()>[
      _api.getSuperadminRoles,
      _api.getSuperadminRoleList,
      _api.getAdminRoles,
      _api.getAdminRoleList,
    ];
    AppError? lastError;
    for (final loader in loaders) {
      try {
        final response = await loader();
        final failure = _failureIfRejected(response);
        if (failure != null) {
          lastError = failure;
          continue;
        }
        final roles = _roleMapper.roleList(response);
        if (roles.isNotEmpty) return Result.success(roles);
      } on DioException catch (error) {
        lastError = AppErrorMapper.fromDio(error);
      } catch (error) {
        lastError = AppErrorMapper.fromObject(error);
      }
    }
    return Result.failure(lastError ?? const NotFoundError('No roles endpoint returned data.'));
  }

  @override
  Future<Result<SuperadminRole, AppError>> updateRole(SuperadminRoleMutationInput input) async {
    try {
      final response = await _api.updateRole(input.key, SuperadminRoleMutationDto(_roleMapper.updatePayload(input)));
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      final roles = _roleMapper.roleList(response);
      if (roles.isNotEmpty) return Result.success(roles.first);
      return Result.success(SuperadminRole(
        key: input.key,
        title: input.title,
        currency: input.currency,
        amount: input.amount,
        permissions: input.permissions,
      ));
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
