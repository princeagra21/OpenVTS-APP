import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_list_item.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_account_repository.dart';

class GetAdminUserLinkedDriversUseCase {
  const GetAdminUserLinkedDriversUseCase(this._repository);

  final AdminAccountRepository _repository;

  Future<Result<List<AdminDriverListItem>, AppError>> call(String userId) {
    return _repository.getUserLinkedDrivers(userId);
  }
}
