import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_list_item.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_account_repository.dart';

class GetAdminUsersUseCase {
  const GetAdminUsersUseCase(this._repository);

  final AdminAccountRepository _repository;

  Future<Result<List<AdminUserListItem>, AppError>> call({
    String? search,
    String? status,
    int? page,
    int? limit,
  }) {
    return _repository.getUsers(search: search, status: status, page: page, limit: limit);
  }
}
