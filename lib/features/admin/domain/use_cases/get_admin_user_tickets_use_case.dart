import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_ticket_list_item.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_account_repository.dart';

class GetAdminUserTicketsUseCase {
  const GetAdminUserTicketsUseCase(this._repository);

  final AdminAccountRepository _repository;

  Future<Result<List<AdminTicketListItem>, AppError>> call(String userId, {int? limit, int? rk}) {
    return _repository.getUserTickets(userId, limit: limit, rk: rk);
  }
}
