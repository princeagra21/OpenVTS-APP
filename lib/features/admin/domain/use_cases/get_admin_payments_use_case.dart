import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_transaction_item.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_operations_repository.dart';

class GetAdminPaymentsUseCase {
  const GetAdminPaymentsUseCase(this._repository);
  final AdminOperationsRepository _repository;

  Future<Result<List<AdminTransactionItem>, AppError>> call({String? search, String? status, int? page, int? limit, String? from, String? to}) {
    return _repository.getPayments(search: search, status: status, page: page, limit: limit, from: from, to: to);
  }
}
