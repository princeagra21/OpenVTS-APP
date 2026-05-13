import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_team_form_input.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_team_form_repository.dart';

class CreateAdminTeamUseCase {
  const CreateAdminTeamUseCase(this._repository);

  final AdminTeamFormRepository _repository;

  Future<Result<void, AppError>> call(CreateAdminTeamInput input) {
    return _repository.createTeam(input);
  }
}
