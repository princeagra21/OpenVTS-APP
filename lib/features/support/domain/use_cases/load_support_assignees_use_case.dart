import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/support/domain/config/support_role_config.dart';
import 'package:open_vts/features/support/domain/entities/support_assignee_option.dart';
import 'package:open_vts/features/support/domain/repositories/support_new_ticket_repository.dart';

class LoadSupportAssigneesUseCase {
  const LoadSupportAssigneesUseCase(this._repository);

  final SupportNewTicketRepository _repository;

  Future<Result<List<SupportAssigneeOption>, AppError>> call(SupportRole role) {
    return _repository.loadAssignees(role);
  }
}
