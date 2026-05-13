import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/support/domain/config/support_role_config.dart';
import 'package:open_vts/features/support/domain/entities/support_assignee_option.dart';
import 'package:open_vts/features/support/domain/entities/support_models.dart';

abstract interface class SupportNewTicketRepository {
  Future<Result<List<SupportAssigneeOption>, AppError>> loadAssignees(
    SupportRole role,
  );

  Future<Result<void, AppError>> createTicket({
    required SupportRole role,
    required bool forMyTickets,
    required SupportCreateTicketDraft draft,
  });
}
