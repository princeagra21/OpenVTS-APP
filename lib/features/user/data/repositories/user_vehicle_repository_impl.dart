import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/data/mappers/user_vehicle_mapper.dart';
import 'package:open_vts/features/user/data/sources/user_vehicle_api_service.dart';
import 'package:open_vts/features/user/domain/entities/user_vehicle_details.dart';
import 'package:open_vts/features/user/domain/repositories/user_vehicle_repository.dart';

class UserVehicleRepositoryImpl implements UserVehicleRepository {
  const UserVehicleRepositoryImpl({required UserVehicleApiService api, required UserVehicleMapper mapper}) : _api = api, _mapper = mapper;
  final UserVehicleApiService _api;
  final UserVehicleMapper _mapper;

  @override
  Future<Result<UserVehicleDetails, AppError>> getVehicleDetail(String id) async {
    try {
      final response = await _api.getVehicleDetail(id);
      if (!ApiResponseNormalizer.action(response)) {
        return Result.failure(ServerError(ApiResponseNormalizer.message(response, defaultValue: 'Request failed')));
      }
      final dto = _mapper.detailFromResponse(response);
      if (dto == null) return const Result.failure(ServerError('Vehicle response is empty'));
      return Result.success(_mapper.details(dto));
    } on DioException catch (error) { return Result.failure(AppErrorMapper.fromDio(error)); } catch (error) { return Result.failure(AppErrorMapper.fromObject(error)); }
  }
}
