import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_team_list_item.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_team_repository.dart';

class GetAdminTeamsUseCase {
  const GetAdminTeamsUseCase(this._repository);
  final AdminTeamRepository _repository;
  Future<Result<List<AdminTeamListItem>, AppError>> call({String? search, int? page, int? limit}) {
    return _repository.getTeams(search: search, page: page, limit: limit);
  }
}
