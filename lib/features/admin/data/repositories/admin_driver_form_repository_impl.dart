import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/data/mappers/admin_workflow_mapper.dart';
import 'package:open_vts/features/admin/data/models/admin_workflow_dtos.dart';
import 'package:open_vts/features/admin/data/sources/admin_workflow_api_service.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_form_input.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_list_item.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_driver_form_repository.dart';

class AdminDriverFormRepositoryImpl implements AdminDriverFormRepository {
  const AdminDriverFormRepositoryImpl({
    required AdminWorkflowApiService api,
    required AdminWorkflowMapper mapper,
  })  : _api = api,
        _mapper = mapper;

  final AdminWorkflowApiService _api;
  final AdminWorkflowMapper _mapper;

  @override
  Future<Result<List<AdminUserListItem>, AppError>> getAssignableUsers() async {
    try {
      final response = await _api.getUsers(limit: 200);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      final users = _mapper.usersFromResponse(response);
      return Result.success(users.map(_mapper.user).where((e) => e.id.isNotEmpty).toList());
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<AdminDriverListItem, AppError>> createDriver(CreateAdminDriverInput input) async {
    try {
      final response = await _api.createDriver(CreateAdminDriverRequestDto.fromInput(input));
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      final dto = _mapper.createdDriverFromResponse(response);
      if (dto == null) return const Result.failure(ServerError('Driver response is empty'));
      return Result.success(_mapper.driver(dto));
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
