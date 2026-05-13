import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/data/mappers/admin_vehicle_mapper.dart';
import 'package:open_vts/features/admin/data/models/admin_vehicle_dtos.dart';
import 'package:open_vts/features/admin/data/sources/admin_vehicle_api_service.dart';
import 'package:open_vts/features/admin/domain/entities/admin_document_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_vehicle_details.dart';
import 'package:open_vts/features/admin/domain/entities/admin_vehicle_log_item.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_vehicle_repository.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_config.dart';

class AdminVehicleRepositoryImpl implements AdminVehicleRepository {
  const AdminVehicleRepositoryImpl({
    required AdminVehicleApiService api,
    required AdminVehicleMapper mapper,
  })  : _api = api,
        _mapper = mapper;

  final AdminVehicleApiService _api;
  final AdminVehicleMapper _mapper;

  @override
  Future<Result<AdminVehicleDetails, AppError>> getVehicleDetail(String vehicleId) async {
    try {
      final response = await _api.getVehicleDetail(vehicleId);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      final dto = _mapper.vehicleFromResponse(response);
      if (dto == null) return const Result.failure(ServerError('Vehicle response is empty'));
      return Result.success(_mapper.details(dto));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<List<AdminUserListItem>, AppError>> getLinkedUsers(String vehicleId) async {
    try {
      final response = await _api.getLinkedUsers(vehicleId);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.linkedUsersFromResponse(response));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<List<AdminDocumentItem>, AppError>> getVehicleDocuments(String vehicleId) async {
    try {
      final response = await _api.getVehicleDocuments(vehicleId);
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
  Future<Result<VehicleConfig, AppError>> getVehicleConfig(String vehicleId) async {
    try {
      final response = await _api.getVehicleConfig(vehicleId);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      final config = _mapper.configFromResponse(response);
      if (config == null) return const Result.failure(ServerError('Vehicle config response is empty'));
      return Result.success(config);
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void, AppError>> updateVehicleConfig(String vehicleId, VehicleConfigUpdate payload) async {
    try {
      final response = await _api.updateVehicleConfig(vehicleId, AdminVehicleConfigUpdateRequestDto(payload.toJson()));
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
  Future<Result<List<AdminVehicleLogItem>, AppError>> getVehicleLogsByImei(String imei, {Map<String, Object?>? query}) async {
    try {
      final response = await _api.getVehicleLogsByImei(imei, query: query);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.logsFromResponse(response));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void, AppError>> updateVehicleStatus(String vehicleId, bool isActive) async {
    try {
      final response = await _api.updateVehicle(vehicleId, UpdateAdminVehicleStatusRequestDto(isActive: isActive));
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
  Future<Result<void, AppError>> deleteVehicle(String vehicleId) async {
    try {
      final response = await _api.deleteVehicle(vehicleId);
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
  Future<Result<void, AppError>> assignDriver(String vehicleId, {required String driverId}) async {
    try {
      final response = await _api.assignDriver(vehicleId, AdminVehicleDriverAssignmentRequestDto(driverId: driverId));
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
  Future<Result<void, AppError>> unassignDriver(String vehicleId) async {
    try {
      final response = await _api.unassignDriver(vehicleId);
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
