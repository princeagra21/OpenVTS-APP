import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/support/domain/config/support_role_config.dart';
import 'package:open_vts/features/support/domain/entities/support_models.dart';
import 'package:open_vts/features/support/domain/repositories/support_new_ticket_repository.dart';

class CreateNewSupportTicketUseCase {
  const CreateNewSupportTicketUseCase(this._repository);

  final SupportNewTicketRepository _repository;

  Future<Result<void, AppError>> call({
    required SupportRole role,
    required bool forMyTickets,
    required SupportCreateTicketDraft draft,
  }) {
    return _repository.createTicket(
      role: role,
      forMyTickets: forMyTickets,
      draft: draft,
    );
  }
}
