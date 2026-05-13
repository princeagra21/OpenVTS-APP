import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_transaction_item.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_account_repository.dart';

class GetAdminUserPaymentsUseCase {
  const GetAdminUserPaymentsUseCase(this._repository);

  final AdminAccountRepository _repository;

  Future<Result<List<AdminTransactionItem>, AppError>> call(String userId) {
    return _repository.getUserPayments(userId);
  }
}
