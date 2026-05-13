import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_list_item.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_driver_form_repository.dart';

class GetAdminDriverUsersUseCase {
  const GetAdminDriverUsersUseCase(this._repository);

  final AdminDriverFormRepository _repository;

  Future<Result<List<AdminUserListItem>, AppError>> call() {
    return _repository.getAssignableUsers();
  }
}
