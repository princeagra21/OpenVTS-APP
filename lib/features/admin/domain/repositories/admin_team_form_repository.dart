import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_team_form_input.dart';

abstract interface class AdminTeamFormRepository {
  Future<Result<void, AppError>> createTeam(CreateAdminTeamInput input);
}
