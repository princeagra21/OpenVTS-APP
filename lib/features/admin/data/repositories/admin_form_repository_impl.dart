import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/data/mappers/admin_form_mapper.dart';
import 'package:open_vts/features/admin/data/models/admin_form_dtos.dart';
import 'package:open_vts/features/admin/data/sources/admin_form_api_service.dart';
import 'package:open_vts/features/admin/domain/entities/add_vehicle_form_data.dart';
import 'package:open_vts/features/admin/domain/entities/admin_form_options.dart';
import 'package:open_vts/features/admin/domain/entities/create_admin_user_input.dart';
import 'package:open_vts/features/admin/domain/entities/create_admin_vehicle_input.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_form_repository.dart';

class AdminFormRepositoryImpl implements AdminFormRepository {
  const AdminFormRepositoryImpl({
    required AdminFormApiService api,
    required AdminFormMapper mapper,
  })  : _api = api,
        _mapper = mapper;

  final AdminFormApiService _api;
  final AdminFormMapper _mapper;

  @override
  Future<Result<AddVehicleFormData, AppError>> loadAddVehicleFormData() async {
    try {
      final usersResponse = await _api.getUsers(limit: 100);
      final usersFailure = _failureIfRejected(usersResponse);
      if (usersFailure != null) return Result.failure(usersFailure);

      final devicesResponse = await _api.getQuickDevices();
      final devicesFailure = _failureIfRejected(devicesResponse);
      if (devicesFailure != null) return Result.failure(devicesFailure);

      final typesResponse = await _api.getVehicleTypes();
      final typesFailure = _failureIfRejected(typesResponse);
      if (typesFailure != null) return Result.failure(typesFailure);

      final plansResponse = await _api.getPricingPlans();
      final plansFailure = _failureIfRejected(plansResponse);
      if (plansFailure != null) return Result.failure(plansFailure);

      return Result.success(
        AddVehicleFormData(
          users: _mapper.usersFromResponse(usersResponse).map(_mapper.user).where((e) => e.id.isNotEmpty).toList(),
          quickDevices: _mapper.quickDevicesFromResponse(devicesResponse).map(_mapper.quickDevice).where((e) => e.imei.isNotEmpty).toList(),
          vehicleTypes: _mapper.vehicleTypesFromResponse(typesResponse).map(_mapper.vehicleType).where((e) => e.id.isNotEmpty && e.name.isNotEmpty).toList(),
          plans: _mapper.pricingPlansFromResponse(plansResponse).map(_mapper.pricingPlan).where((e) => e.id.isNotEmpty && e.name.isNotEmpty).toList(),
        ),
      );
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<AdminCreatedVehicle, AppError>> createVehicle(CreateAdminVehicleInput input) async {
    try {
      final response = await _api.createVehicle(CreateAdminVehicleRequestDto.fromInput(input));
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      final dto = _mapper.createdVehicleFromResponse(response);
      if (dto == null) return const Result.failure(ServerError('Vehicle response is empty'));
      return Result.success(_mapper.createdVehicle(dto));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<AdminCreatedUser, AppError>> createUser(CreateAdminUserInput input) async {
    try {
      final response = await _api.createUser(CreateAdminUserRequestDto.fromInput(input));
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      final dto = _mapper.createdUserFromResponse(response);
      if (dto == null) return const Result.failure(ServerError('User response is empty'));
      return Result.success(_mapper.createdUser(dto));
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
