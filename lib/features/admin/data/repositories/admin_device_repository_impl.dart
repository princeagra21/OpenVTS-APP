import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/data/mappers/admin_device_mapper.dart';
import 'package:open_vts/features/admin/data/models/admin_device_dtos.dart';
import 'package:open_vts/features/admin/data/sources/admin_device_api_service.dart';
import 'package:open_vts/features/admin/domain/entities/admin_device_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_device_mutation_input.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_device_repository.dart';
import 'package:open_vts/features/vehicles/domain/entities/device_type_option.dart';
import 'package:open_vts/features/vehicles/domain/entities/sim_option.dart';
import 'package:open_vts/features/vehicles/domain/entities/sim_provider_option.dart';

class AdminDeviceRepositoryImpl implements AdminDeviceRepository {
  const AdminDeviceRepositoryImpl({
    required AdminDeviceApiService api,
    required AdminDeviceMapper mapper,
  })  : _api = api,
        _mapper = mapper;

  final AdminDeviceApiService _api;
  final AdminDeviceMapper _mapper;

  @override
  Future<Result<List<AdminDeviceListItem>, AppError>> getDevices({String? search, String? status, int? page, int? limit}) async {
    try {
      final response = await _api.getDevices(search: search, status: status, page: page, limit: limit);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.devicesFromResponse(response).map(_mapper.listItem).toList(growable: false));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<AdminDeviceListItem, AppError>> getDeviceDetail(String deviceId) async {
    try {
      final response = await _api.getDeviceDetail(deviceId);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      final dto = _mapper.deviceFromResponse(response);
      if (dto == null) return const Result.failure(ServerError('Device response is empty'));
      return Result.success(_mapper.listItem(dto));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<List<DeviceTypeOption>, AppError>> getDeviceTypes() async {
    try {
      final response = await _api.getDeviceTypes();
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.deviceTypesFromResponse(response));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<List<SimOption>, AppError>> getSims() async {
    try {
      final response = await _api.getSims();
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.simsFromResponse(response));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<List<SimProviderOption>, AppError>> getSimProviders() async {
    try {
      final response = await _api.getSimProviders();
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.simProvidersFromResponse(response));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<List<SimOption>, AppError>> getQuickSimCards() async {
    try {
      final response = await _api.getQuickSimCards();
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.simsFromResponse(response));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void, AppError>> createSimCard(CreateAdminSimCardMutationInput input) async {
    try {
      final response = await _api.createSimCard(CreateAdminSimCardRequestDto(
        simNumber: input.simNumber,
        providerId: input.providerId,
        imsi: input.imsi,
        iccid: input.iccid,
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
  Future<Result<void, AppError>> createDevice(CreateAdminDeviceMutationInput input) async {
    try {
      final response = await _api.createDevice(CreateAdminDeviceRequestDto(
        imei: input.imei,
        deviceTypeId: input.deviceTypeId,
        simId: input.simId,
        simNumber: input.simNumber,
        providerId: input.providerId,
        imsi: input.imsi,
        iccid: input.iccid,
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
  Future<Result<void, AppError>> createDeviceAndSim(CreateAdminDeviceAndSimMutationInput input) async {
    try {
      final response = await _api.createDeviceAndSim(CreateAdminDeviceAndSimRequestDto(
        imei: input.imei,
        deviceTypeId: input.deviceTypeId,
        simNumber: input.simNumber,
        providerId: input.providerId,
        imsi: input.imsi,
        iccid: input.iccid,
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
  Future<Result<void, AppError>> updateDevice(String deviceId, UpdateAdminDeviceMutationInput input) async {
    try {
      final response = await _api.updateDevice(deviceId, UpdateAdminDeviceRequestDto(
        imei: input.imei,
        deviceTypeId: input.deviceTypeId,
        simId: input.simId,
        simNumber: input.simNumber,
        providerId: input.providerId,
        imsi: input.imsi,
        iccid: input.iccid,
        isActive: input.isActive,
        status: input.status,
        clearSim: input.clearSim,
        extra: input.extra,
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
  Future<Result<void, AppError>> updateDeviceStatus(String deviceId, bool isActive) {
    return updateDevice(deviceId, UpdateAdminDeviceMutationInput(isActive: isActive));
  }

  AppError? _failureIfRejected<T>(ApiResponse<T> response) {
    if (response.action) return null;
    return ServerError(response.message.trim().isEmpty ? 'Request failed' : response.message);
  }
}
