import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_form_input.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_list_item.dart';

abstract interface class AdminDriverFormRepository {
  Future<Result<List<AdminUserListItem>, AppError>> getAssignableUsers();
  Future<Result<AdminDriverListItem, AppError>> createDriver(CreateAdminDriverInput input);
}
