import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/reference_data/domain/entities/reference_options.dart';
import 'package:open_vts/features/user/data/mappers/user_vehicle_form_mapper.dart';
import 'package:open_vts/features/user/data/models/user_vehicle_form_dtos.dart';
import 'package:open_vts/features/user/data/sources/user_vehicle_form_api_service.dart';
import 'package:open_vts/features/user/domain/entities/create_user_vehicle_input.dart';
import 'package:open_vts/features/user/domain/repositories/user_vehicle_form_repository.dart';

class UserVehicleFormRepositoryImpl implements UserVehicleFormRepository {
  const UserVehicleFormRepositoryImpl({
    required UserVehicleFormApiService api,
    required UserVehicleFormMapper mapper,
  })  : _api = api,
        _mapper = mapper;

  final UserVehicleFormApiService _api;
  final UserVehicleFormMapper _mapper;

  @override
  Future<Result<List<ReferenceOption>, AppError>> getVehicleTypes() async {
    try {
      final response = await _api.getVehicleTypes();
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      if (ApiResponseNormalizer.hasExplicitNullPayload(response)) {
        return const Result.failure(ServerError('Vehicle types response is empty'));
      }
      final payload = _mapper.vehicleTypesFromResponse(response);
      return Result.success(payload.map(_mapper.vehicleType).where((e) => e.value.isNotEmpty && e.label.isNotEmpty).toList());
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void, AppError>> createVehicle(CreateUserVehicleInput input) async {
    try {
      final response = await _api.createVehicle(CreateUserVehicleRequestDto.fromInput(input));
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return const Result.success(null);
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
