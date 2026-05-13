import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/support/domain/entities/support_models.dart';
import 'package:open_vts/features/support/domain/repositories/support_ticket_repository.dart';

class GetSupportTicketsUseCase {
  const GetSupportTicketsUseCase(this.repository);

  final SupportTicketRepository repository;

  Future<Result<List<SupportTicketSummary>, AppError>> call() => repository.getTickets();
}
