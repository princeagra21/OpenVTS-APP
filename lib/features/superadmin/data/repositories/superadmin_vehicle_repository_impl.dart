import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/superadmin/data/mappers/superadmin_vehicle_mapper.dart';
import 'package:open_vts/features/superadmin/data/models/superadmin_vehicle_dtos.dart';
import 'package:open_vts/features/superadmin/data/sources/superadmin_vehicle_api_service.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_vehicle.dart';
import 'package:open_vts/features/superadmin/domain/repositories/superadmin_vehicle_repository.dart';

class SuperadminVehicleRepositoryImpl implements SuperadminVehicleRepository {
  const SuperadminVehicleRepositoryImpl({required SuperadminVehicleApiService api, required SuperadminVehicleMapper mapper})
      : _api = api,
        _mapper = mapper;

  final SuperadminVehicleApiService _api;
  final SuperadminVehicleMapper _mapper;

  @override
  Future<Result<List<SuperadminVehicleListItem>, AppError>> getAdminVehicles(String adminId) async {
    try {
      final response = await _api.getAdminVehicles(adminId);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.vehiclesFromResponse(response).map(_mapper.listItem).toList(growable: false));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<List<SuperadminVehicleListItem>, AppError>> getVehicles({int? page, int? limit}) async {
    try {
      final response = await _api.getVehicles(page: page, limit: limit);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.vehiclesFromResponse(response).map(_mapper.listItem).toList(growable: false));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<SuperadminVehicleDetail, AppError>> getVehicleDetail(String vehicleId) async {
    try {
      final baseResponse = await _api.getVehicleDetail(vehicleId);
      final failure = _failureIfRejected(baseResponse);
      if (failure != null) return Result.failure(failure);
      final baseDto = _mapper.vehicleFromResponse(baseResponse);
      if (baseDto == null) return const Result.failure(ServerError('Vehicle response is empty'));
      var detail = _mapper.detail(baseDto);
      if (detail.imei.trim().isNotEmpty) {
        try {
          final imeiResponse = await _api.getVehicleByImeiDetail(detail.imei);
          final imeiDto = _mapper.vehicleFromResponse(imeiResponse);
          if (imeiDto != null) {
            final telemetry = ApiResponseNormalizer.mapPayloadOf(imeiResponse, preferredKeys: const ['telemetry']);
            detail = _mapper.detail(imeiDto, telemetry: telemetry);
          }
        } on DioException {
          // Preserve legacy behavior: base vehicle details are still useful if the enrichment endpoint fails.
        }
      }
      return Result.success(detail);
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<List<SuperadminCommandOption>, AppError>> getCommandOptions(String imei) async {
    try {
      final response = await _api.getCommandOptions();
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.commandOptionsFromResponse(response));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void, AppError>> sendCommand(String imei, String commandCode, Map<String, Object?>? payload, bool confirm) async {
    try {
      final response = await _api.sendCommand(SuperadminSendCommandRequestDto(
        imei: imei,
        commandCode: commandCode,
        payload: payload ?? const <String, Object?>{},
        confirm: confirm,
      ));
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
  Future<Result<List<SuperadminSentCommand>, AppError>> getRecentCommands(String imei) async {
    try {
      final response = await _api.getRecentCommands();
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.sentCommandsFromResponse(response));
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
