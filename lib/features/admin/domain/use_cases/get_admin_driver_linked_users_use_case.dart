import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_list_item.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_driver_repository.dart';

class GetAdminDriverLinkedUsersUseCase {
  const GetAdminDriverLinkedUsersUseCase(this._repository);
  final AdminDriverRepository _repository;
  Future<Result<List<AdminUserListItem>, AppError>> call(String driverId) => _repository.getLinkedUsers(driverId);
}
