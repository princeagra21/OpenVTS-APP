import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/data/models/admin_workflow_dtos.dart';
import 'package:open_vts/features/admin/data/sources/admin_workflow_api_service.dart';
import 'package:open_vts/features/admin/domain/entities/admin_team_form_input.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_team_form_repository.dart';

class AdminTeamFormRepositoryImpl implements AdminTeamFormRepository {
  const AdminTeamFormRepositoryImpl({required AdminWorkflowApiService api}) : _api = api;

  final AdminWorkflowApiService _api;

  @override
  Future<Result<void, AppError>> createTeam(CreateAdminTeamInput input) async {
    try {
      final response = await _api.createTeam(CreateAdminTeamRequestDto.fromInput(input));
      if (!ApiResponseNormalizer.action(response)) {
        return Result.failure(
          ServerError(ApiResponseNormalizer.message(response, defaultValue: 'Request failed')),
        );
      }
      return const Result.success(null);
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }
}
