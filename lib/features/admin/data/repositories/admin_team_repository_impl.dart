import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/data/mappers/admin_team_mapper.dart';
import 'package:open_vts/features/admin/data/models/admin_team_dtos.dart';
import 'package:open_vts/features/admin/data/sources/admin_team_api_service.dart';
import 'package:open_vts/features/admin/domain/entities/admin_team_form_input.dart';
import 'package:open_vts/features/admin/domain/entities/admin_team_list_item.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_team_repository.dart';

class AdminTeamRepositoryImpl implements AdminTeamRepository {
  const AdminTeamRepositoryImpl({
    required AdminTeamApiService api,
    required AdminTeamMapper mapper,
  })  : _api = api,
        _mapper = mapper;

  final AdminTeamApiService _api;
  final AdminTeamMapper _mapper;

  @override
  Future<Result<List<AdminTeamListItem>, AppError>> getTeams({String? search, int? page, int? limit}) async {
    try {
      final response = await _api.getTeams(search: search, page: page, limit: limit);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.teamsFromResponse(response).map(_mapper.listItem).toList(growable: false));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<AdminTeamListItem, AppError>> getTeamDetail(String teamId) async {
    try {
      final response = await _api.getTeamDetail(teamId);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      final dto = _mapper.teamFromResponse(response);
      if (dto == null) return const Result.failure(ServerError('Team response is empty'));
      return Result.success(_mapper.listItem(dto));
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void, AppError>> updateTeamStatus(String teamId, bool isActive) async {
    try {
      final response = await _api.updateTeam(teamId, AdminTeamMutationRequestDto(UpdateAdminTeamStatusRequestDto(isActive: isActive).toJson()));
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
  Future<Result<void, AppError>> updateTeamPassword(String teamId, String password) async {
    try {
      final response = await _api.updateTeam(teamId, AdminTeamMutationRequestDto(UpdateAdminTeamPasswordRequestDto(password: password).toJson()));
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
  Future<Result<void, AppError>> updateTeam({required String teamId, required String name, required String email, required String mobilePrefix, required String mobileNumber, required String username}) async {
    try {
      final response = await _api.updateTeam(teamId, AdminTeamMutationRequestDto(UpdateAdminTeamRequestDto(name: name, email: email, mobilePrefix: mobilePrefix, mobileNumber: mobileNumber, username: username).toJson()));
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
  Future<Result<void, AppError>> createTeam(CreateAdminTeamInput input) async {
    try {
      final response = await _api.createTeam(CreateAdminTeamRequestDto(name: input.name, email: input.email, mobilePrefix: input.mobilePrefix, mobileNumber: input.mobileNumber, username: input.username, password: input.password));
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
