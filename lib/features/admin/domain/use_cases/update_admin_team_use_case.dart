import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_team_form_input.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_team_repository.dart';

class UpdateAdminTeamUseCase {
  const UpdateAdminTeamUseCase(this._repository);
  final AdminTeamRepository _repository;
  Future<Result<void, AppError>> updateStatus(String teamId, bool isActive) => _repository.updateTeamStatus(teamId, isActive);
  Future<Result<void, AppError>> updatePassword(String teamId, String password) => _repository.updateTeamPassword(teamId, password);
  Future<Result<void, AppError>> updateTeam({required String teamId, required String name, required String email, required String mobilePrefix, required String mobileNumber, required String username}) {
    return _repository.updateTeam(teamId: teamId, name: name, email: email, mobilePrefix: mobilePrefix, mobileNumber: mobileNumber, username: username);
  }
  Future<Result<void, AppError>> create(CreateAdminTeamInput input) => _repository.createTeam(input);
}
