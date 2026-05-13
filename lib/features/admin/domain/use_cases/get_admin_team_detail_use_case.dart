import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_team_list_item.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_team_repository.dart';

class GetAdminTeamDetailUseCase {
  const GetAdminTeamDetailUseCase(this._repository);
  final AdminTeamRepository _repository;
  Future<Result<AdminTeamListItem, AppError>> call(String teamId) => _repository.getTeamDetail(teamId);
}
