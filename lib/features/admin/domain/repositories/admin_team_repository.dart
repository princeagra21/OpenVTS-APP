import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_team_form_input.dart';
import 'package:open_vts/features/admin/domain/entities/admin_team_list_item.dart';

abstract interface class AdminTeamRepository {
  Future<Result<List<AdminTeamListItem>, AppError>> getTeams({
    String? search,
    int? page,
    int? limit,
  });

  Future<Result<AdminTeamListItem, AppError>> getTeamDetail(String teamId);

  Future<Result<void, AppError>> updateTeamStatus(String teamId, bool isActive);

  Future<Result<void, AppError>> updateTeamPassword(String teamId, String password);

  Future<Result<void, AppError>> updateTeam({
    required String teamId,
    required String name,
    required String email,
    required String mobilePrefix,
    required String mobileNumber,
    required String username,
  });

  Future<Result<void, AppError>> createTeam(CreateAdminTeamInput input);
}
