import 'dart:typed_data';

import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_document_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_linked_vehicle.dart';
import 'package:open_vts/features/admin/domain/entities/admin_ticket_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_transaction_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_details.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_vehicle_list_item.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_document_type.dart';
import 'package:open_vts/shared/models/admin_profile.dart';

abstract interface class AdminAccountRepository {
  Future<Result<List<AdminUserListItem>, AppError>> getUsers({
    String? search,
    String? status,
    int? page,
    int? limit,
  });

  Future<Result<AdminUserDetails, AppError>> getUserDetails(String userId);
  Future<Result<void, AppError>> updateUserStatus(String userId, bool isActive);
  Future<Result<String, AppError>> loginAsUser(String userId);
  Future<Result<List<AdminVehicleListItem>, AppError>> getUserLinkedVehicles(String userId);
  Future<Result<List<AdminVehicleListItem>, AppError>> getUnlinkedVehicles({String? userId});
  Future<Result<void, AppError>> assignVehicleToUser({required String userId, required String vehicleId});
  Future<Result<List<AdminDriverListItem>, AppError>> getUserLinkedDrivers(String userId);
  Future<Result<List<AdminDocumentItem>, AppError>> getUserDocuments(String userId);
  Future<Result<List<SuperadminDocumentType>, AppError>> getDocumentTypes();
  Future<Result<void, AppError>> uploadDocument({
    required String associateType,
    required String associateId,
    required int docTypeId,
    required String title,
    required Uint8List fileBytes,
    required String filename,
    String? description,
    String? tags,
    String? expiryAt,
    bool isVisible,
    String? contentType,
  });
  Future<Result<void, AppError>> updateDocument({
    required String documentId,
    int? docTypeId,
    String? title,
    String? description,
    String? tags,
    String? expiryAt,
    bool? isVisible,
    Uint8List? fileBytes,
    String? filename,
    String? contentType,
  });
  Future<Result<void, AppError>> deleteDocumentFile(String documentId);
  Future<Result<List<AdminTicketListItem>, AppError>> getUserTickets(String userId, {int? limit, int? rk});
  Future<Result<List<Map<String, Object?>>, AppError>> getUserActivityLogs(String userId, {int? limit});
  Future<Result<List<AdminTransactionItem>, AppError>> getUserPayments(String userId);
  Future<Result<void, AppError>> updateUserPassword(String userId, String newPassword);
  Future<Result<AdminProfile, AppError>> getMyProfile();
  Future<Result<AdminProfile, AppError>> updateMyProfile(Map<String, Object?> payload);
  Future<Result<void, AppError>> updatePassword({required String currentPassword, required String newPassword});
  Future<Result<void, AppError>> sendEmailOtp();
  Future<Result<void, AppError>> verifyEmailOtp(String code);
  Future<Result<void, AppError>> sendPhoneOtp();
  Future<Result<void, AppError>> verifyPhoneOtp(String code);
  Future<Result<Map<String, Object?>, AppError>> updateCompanyDetails(String companyId, Map<String, Object?> payload);
  Future<Result<String, AppError>> uploadAdminFile({
    required String type,
    required Uint8List bytes,
    required String filename,
    String? contentType,
  });
  Future<Result<List<AdminLinkedVehicle>, AppError>> getLinkedVehicles({required String userId});
  Future<Result<void, AppError>> renewVehicles({
    required String userId,
    required List<int> vehicleIds,
    required String paymentMode,
    required double amount,
  });
}
