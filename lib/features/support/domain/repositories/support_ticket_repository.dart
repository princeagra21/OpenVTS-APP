import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/support/domain/entities/support_models.dart';

abstract interface class SupportTicketRepository {
  Future<Result<List<SupportTicketSummary>, AppError>> getTickets();

  Future<Result<SupportTicketSummary, AppError>> createTicket({
    required String subject,
    required String message,
    String? category,
    String? priority,
  });
}
