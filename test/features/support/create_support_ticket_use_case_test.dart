import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/support/domain/entities/support_models.dart';
import 'package:open_vts/features/support/domain/repositories/support_ticket_repository.dart';
import 'package:open_vts/features/support/domain/use_cases/create_support_ticket_use_case.dart';

class _FakeSupportTicketRepository implements SupportTicketRepository {
  _FakeSupportTicketRepository(this.result);
  final Result<SupportTicketSummary, AppError> result;

  @override
  Future<Result<SupportTicketSummary, AppError>> createTicket({
    required String subject,
    required String message,
    String? category,
    String? priority,
  }) async => result;

  @override
  Future<Result<List<SupportTicketSummary>, AppError>> getTickets() async => Result.success([result.valueOrNull!]);
}

void main() {
  test('CreateSupportTicketUseCase creates a ticket through repository', () async {
    const ticket = SupportTicketSummary(
      id: 't1',
      subject: 'Help',
      status: 'open',
      ownerName: 'User',
      description: 'Need help',
      category: 'general',
      priority: 'medium',
      ticketNumber: 'T-1',
      createdAt: 'now',
      updatedAt: 'now',
      raw: <String, dynamic>{},
    );
    final useCase = CreateSupportTicketUseCase(_FakeSupportTicketRepository(const Result.success(ticket)));

    final result = await useCase(const CreateSupportTicketParams(subject: 'Help', message: 'Need help'));

    expect(result.isSuccess, true);
    expect(result.valueOrNull?.id, 't1');
  });
}
