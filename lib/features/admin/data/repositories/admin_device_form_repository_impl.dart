import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/data/mappers/admin_workflow_mapper.dart';
import 'package:open_vts/features/admin/data/models/admin_workflow_dtos.dart';
import 'package:open_vts/features/admin/data/sources/admin_workflow_api_service.dart';
import 'package:open_vts/features/admin/domain/entities/admin_device_form_data.dart';
import 'package:open_vts/features/admin/domain/entities/admin_device_form_input.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_device_form_repository.dart';

class AdminDeviceFormRepositoryImpl implements AdminDeviceFormRepository {
  const AdminDeviceFormRepositoryImpl({
    required AdminWorkflowApiService api,
    required AdminWorkflowMapper mapper,
  })  : _api = api,
        _mapper = mapper;

  final AdminWorkflowApiService _api;
  final AdminWorkflowMapper _mapper;

  @override
  Future<Result<AdminDeviceFormData, AppError>> loadFormData() async {
    try {
      final types = await _api.getDeviceTypes();
      final typesFailure = _failureIfRejected(types);
      if (typesFailure != null) return Result.failure(typesFailure);
      final sims = await _api.getSims();
      final simsFailure = _failureIfRejected(sims);
      if (simsFailure != null) return Result.failure(simsFailure);
      return Result.success(
        _mapper.deviceFormData(
          deviceTypes: _mapper.deviceTypesFromResponse(types),
          sims: _mapper.simsFromResponse(sims),
        ),
      );
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void, AppError>> createDevice(CreateAdminDeviceInput input) async {
    try {
      final response = await _api.createDevice(CreateAdminDeviceRequestDto.fromInput(input));
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
