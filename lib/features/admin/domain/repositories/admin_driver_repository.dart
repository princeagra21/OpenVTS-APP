import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_document_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_details.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_list_item.dart';

abstract interface class AdminDriverRepository {
  Future<Result<List<AdminDriverListItem>, AppError>> getDrivers({
    String? search,
    String? status,
    int? page,
    int? limit,
  });

  Future<Result<AdminDriverDetails, AppError>> getDriverDetail(String driverId);

  Future<Result<void, AppError>> updateDriverStatus(String driverId, bool isActive);

  Future<Result<List<AdminDocumentItem>, AppError>> getDriverDocuments(String driverId);

  Future<Result<List<AdminUserListItem>, AppError>> getLinkedUsers(String driverId);

  Future<Result<List<AdminUserListItem>, AppError>> getUnlinkedUsers(String driverId);

  Future<Result<void, AppError>> assignUserToDriver(String driverId, {required int userId});

  Future<Result<void, AppError>> unassignUserFromDriver(String driverId, {required int userId});
}
