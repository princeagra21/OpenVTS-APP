import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/auth/data/repositories/auth_repository.dart' as legacy_auth;
import 'package:open_vts/features/superadmin/data/mappers/superadmin_admin_mapper.dart';
import 'package:open_vts/features/superadmin/data/models/superadmin_admin_dtos.dart';
import 'package:open_vts/features/superadmin/data/sources/superadmin_admin_api_service.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_admin.dart';
import 'package:open_vts/features/superadmin/domain/repositories/superadmin_admin_repository.dart';

class SuperadminAdminRepositoryImpl implements SuperadminAdminRepository {
  const SuperadminAdminRepositoryImpl({required SuperadminAdminApiService api, required SuperadminAdminMapper mapper})
      : _api = api,
        _mapper = mapper;

  final SuperadminAdminApiService _api;
  final SuperadminAdminMapper _mapper;

  @override
  Future<Result<List<SuperadminAdminListItem>, AppError>> getAdmins({int? page, int? limit, String? status}) async {
    try {
      final response = await _api.getAdmins(page: page, limit: limit, status: status);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.listFromResponse(response).map(_mapper.listItem).toList(growable: false));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<SuperadminAdminDetail, AppError>> getAdminDetail(String adminId) async {
    try {
      final response = await _api.getAdminDetail(adminId);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      final dto = _mapper.detailFromResponse(response);
      if (dto == null) return const Result.failure(ServerError('Admin response is empty'));
      return Result.success(_mapper.detail(dto));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void, AppError>> createAdmin(SuperadminAdminMutationInput input) async {
    try {
      final response = await _api.createAdmin(SuperadminAdminMutationDto(_mapper.mutationToJson(input)));
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
  Future<Result<SuperadminAdminDetail, AppError>> updateAdmin(String adminId, SuperadminAdminMutationInput input) async {
    try {
      final response = await _api.updateAdmin(adminId, SuperadminAdminMutationDto(_mapper.mutationToJson(input)));
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      final dto = _mapper.detailFromResponse(response) ?? SuperadminAdminDto.fromJson(_mapper.mutationToJson(input));
      return Result.success(_mapper.detail(dto));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void, AppError>> updateAdminStatus(String adminId, bool isActive) async {
    try {
      final dto = SuperadminAdminStatusDto(isActive: isActive);
      try {
        final primary = await _api.activateAdmin(adminId, dto);
        final primaryFailure = _failureIfRejected(primary);
        if (primaryFailure == null) return const Result.success(null);
      } on DioException catch (error) {
        if (error.response?.statusCode != 404) rethrow;
      }
      final fallback = await _api.updateAdminStatusFallback(SuperadminAdminMutationDto(dto.toFallbackJson(adminId)));
      final failure = _failureIfRejected(fallback);
      if (failure != null) return Result.failure(failure);
      return const Result.success(null);
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void, AppError>> updateCompanyDetails(SuperadminAdminMutationInput input) async {
    try {
      final response = await _api.updateCompanyDetails(SuperadminCompanyMutationDto(_mapper.mutationToJson(input)));
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
  Future<Result<void, AppError>> updateCompanyConfig(String companyId, SuperadminAdminMutationInput input) async {
    try {
      final response = await _api.updateCompanyConfig(companyId, SuperadminCompanyMutationDto(_mapper.mutationToJson(input)));
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
  Future<Result<String, AppError>> loginAsAdmin(String adminId) async {
    try {
      final response = await _api.loginAsAdmin(adminId);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      final token = legacy_auth.AuthRepository.extractToken(response)?.trim() ?? '';
      if (token.isEmpty) return const Result.failure(AuthError('Token not found in admin login response.'));
      return Result.success(token);
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
