import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/data/mappers/admin_driver_mapper.dart';
import 'package:open_vts/features/admin/data/models/admin_driver_dtos.dart';
import 'package:open_vts/features/admin/data/sources/admin_driver_api_service.dart';
import 'package:open_vts/features/admin/domain/entities/admin_document_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_details.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_list_item.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_driver_repository.dart';

class AdminDriverRepositoryImpl implements AdminDriverRepository {
  const AdminDriverRepositoryImpl({
    required AdminDriverApiService api,
    required AdminDriverMapper mapper,
  })  : _api = api,
        _mapper = mapper;

  final AdminDriverApiService _api;
  final AdminDriverMapper _mapper;

  @override
  Future<Result<List<AdminDriverListItem>, AppError>> getDrivers({
    String? search,
    String? status,
    int? page,
    int? limit,
  }) async {
    try {
      final response = await _api.getDrivers(search: search, status: status, page: page, limit: limit);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.driversFromResponse(response).map(_mapper.listItem).toList(growable: false));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<AdminDriverDetails, AppError>> getDriverDetail(String driverId) async {
    try {
      final response = await _api.getDriverDetail(driverId);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      final dto = _mapper.driverFromResponse(response);
      if (dto == null) return const Result.failure(ServerError('Driver response is empty'));
      return Result.success(_mapper.details(dto));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void, AppError>> updateDriverStatus(String driverId, bool isActive) async {
    try {
      final response = await _api.updateDriver(driverId, AdminDriverUpdateRequestDto(isActive: isActive));
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
  Future<Result<List<AdminDocumentItem>, AppError>> getDriverDocuments(String driverId) async {
    try {
      final response = await _api.getDriverDocuments(driverId);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.documentsFromResponse(response));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<List<AdminUserListItem>, AppError>> getLinkedUsers(String driverId) async {
    try {
      final response = await _api.getLinkedUsers(driverId, rk: DateTime.now().millisecondsSinceEpoch);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.usersFromResponse(response));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<List<AdminUserListItem>, AppError>> getUnlinkedUsers(String driverId) async {
    try {
      final response = await _api.getUnlinkedUsers(driverId, rk: DateTime.now().millisecondsSinceEpoch);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.usersFromResponse(response));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void, AppError>> assignUserToDriver(String driverId, {required int userId}) async {
    try {
      final response = await _api.assignUserToDriver(driverId, AdminDriverUserLinkRequestDto(userId: userId));
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
  Future<Result<void, AppError>> unassignUserFromDriver(String driverId, {required int userId}) async {
    try {
      final response = await _api.unassignUserFromDriver(driverId, AdminDriverUserLinkRequestDto(userId: userId));
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
