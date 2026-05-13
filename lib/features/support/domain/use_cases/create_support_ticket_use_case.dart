import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/support/domain/entities/support_models.dart';
import 'package:open_vts/features/support/domain/repositories/support_ticket_repository.dart';

class CreateSupportTicketParams {
  const CreateSupportTicketParams({
    required this.subject,
    required this.message,
    this.category,
    this.priority,
  });

  final String subject;
  final String message;
  final String? category;
  final String? priority;
}

class CreateSupportTicketUseCase {
  const CreateSupportTicketUseCase(this.repository);
  final SupportTicketRepository repository;

  Future<Result<SupportTicketSummary, AppError>> call(
    CreateSupportTicketParams params,
  ) {
    return repository.createTicket(
      subject: params.subject,
      message: params.message,
      category: params.category,
      priority: params.priority,
    );
  }
}
