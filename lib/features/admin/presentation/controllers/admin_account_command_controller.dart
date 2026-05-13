import 'dart:typed_data';

import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/session/session_service.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_document_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_linked_vehicle.dart';
import 'package:open_vts/features/admin/domain/entities/admin_ticket_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_transaction_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_details.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_vehicle_list_item.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_account_repository.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_document_type.dart';
import 'package:open_vts/shared/models/admin_profile.dart';

class AdminAccountCommandController {
  const AdminAccountCommandController({
    required AdminAccountRepository repository,
    required SessionService sessionService,
  })  : _repository = repository,
        _sessionService = sessionService;

  final AdminAccountRepository _repository;
  final SessionService _sessionService;

  Future<Result<List<AdminUserListItem>, AppError>> getUsers({String? search, String? status, int? page, int? limit, Object? cancelToken}) {
    return _repository.getUsers(search: search, status: status, page: page, limit: limit);
  }

  Future<Result<AdminUserDetails, AppError>> getUserDetails(String userId, {Object? cancelToken}) => _repository.getUserDetails(userId);

  Future<Result<String, AppError>> loginAsUser(String userId, {Object? cancelToken}) => _repository.loginAsUser(userId);

  Future<Result<void, AppError>> startImpersonation(String token) async {
    await _sessionService.startImpersonation(token);
    return const Result.success(null);
  }

  Future<String?> readAccessToken() => _sessionService.readAccessToken();

  Future<Result<void, AppError>> updateUserStatus(String userId, bool isActive, {Object? cancelToken}) {
    return _repository.updateUserStatus(userId, isActive);
  }

  Future<Result<List<AdminVehicleListItem>, AppError>> getUserLinkedVehicles(String userId, {Object? cancelToken}) {
    return _repository.getUserLinkedVehicles(userId);
  }

  Future<Result<List<AdminVehicleListItem>, AppError>> getUnlinkedVehicles({String? userId, Object? cancelToken}) {
    return _repository.getUnlinkedVehicles(userId: userId);
  }

  Future<Result<void, AppError>> assignVehicleToUser({required String userId, required String vehicleId, Object? cancelToken}) {
    return _repository.assignVehicleToUser(userId: userId, vehicleId: vehicleId);
  }

  Future<Result<List<AdminDriverListItem>, AppError>> getUserLinkedDrivers(String userId, {Object? cancelToken}) {
    return _repository.getUserLinkedDrivers(userId);
  }

  Future<Result<List<AdminDocumentItem>, AppError>> getUserDocuments(String userId, {Object? cancelToken}) {
    return _repository.getUserDocuments(userId);
  }

  Future<Result<List<SuperadminDocumentType>, AppError>> getDocumentTypes({Object? cancelToken}) {
    return _repository.getDocumentTypes();
  }

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
    bool isVisible = true,
    String? contentType,
    Object? cancelToken,
  }) {
    return _repository.uploadDocument(
      associateType: associateType,
      associateId: associateId,
      docTypeId: docTypeId,
      title: title,
      fileBytes: fileBytes,
      filename: filename,
      description: description,
      tags: tags,
      expiryAt: expiryAt,
      isVisible: isVisible,
      contentType: contentType,
    );
  }

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
    Object? cancelToken,
  }) {
    return _repository.updateDocument(
      documentId: documentId,
      docTypeId: docTypeId,
      title: title,
      description: description,
      tags: tags,
      expiryAt: expiryAt,
      isVisible: isVisible,
      fileBytes: fileBytes,
      filename: filename,
      contentType: contentType,
    );
  }

  Future<Result<void, AppError>> deleteDocumentFile(String documentId, {Object? cancelToken}) => _repository.deleteDocumentFile(documentId);

  Future<Result<List<AdminTicketListItem>, AppError>> getUserTickets(String userId, {int? limit, int? rk, Object? cancelToken}) {
    return _repository.getUserTickets(userId, limit: limit, rk: rk);
  }

  Future<Result<List<Map<String, dynamic>>, AppError>> getUserActivityLogs(String userId, {int? limit, Object? cancelToken}) async {
    final result = await _repository.getUserActivityLogs(userId, limit: limit);
    return result.when(
      success: (items) => Result.success(
        items.map((item) => Map<String, dynamic>.from(item)).toList(growable: false),
      ),
      failure: (error) => Result.failure(error),
    );
  }

  Future<Result<List<AdminTransactionItem>, AppError>> getUserPayments(String userId, {Object? cancelToken}) {
    return _repository.getUserPayments(userId);
  }

  Future<Result<void, AppError>> updateUserPassword(String userId, String newPassword, {Object? cancelToken}) {
    return _repository.updateUserPassword(userId, newPassword);
  }

  Future<Result<AdminProfile, AppError>> getMyProfile({Object? cancelToken}) => _repository.getMyProfile();

  Future<Result<AdminProfile, AppError>> updateMyProfile(Map<String, Object?> payload, {Object? cancelToken}) {
    return _repository.updateMyProfile(payload);
  }

  Future<Result<void, AppError>> updatePassword({required String currentPassword, required String newPassword, Object? cancelToken}) {
    return _repository.updatePassword(currentPassword: currentPassword, newPassword: newPassword);
  }

  Future<Result<void, AppError>> sendEmailOtp({Object? cancelToken}) => _repository.sendEmailOtp();
  Future<Result<void, AppError>> verifyEmailOtp(String code, {Object? cancelToken}) => _repository.verifyEmailOtp(code);
  Future<Result<void, AppError>> sendPhoneOtp({Object? cancelToken}) => _repository.sendPhoneOtp();
  Future<Result<void, AppError>> verifyPhoneOtp(String code, {Object? cancelToken}) => _repository.verifyPhoneOtp(code);

  Future<Result<Map<String, dynamic>, AppError>> updateCompanyDetails(String companyId, Map<String, Object?> payload, {Object? cancelToken}) async {
    final result = await _repository.updateCompanyDetails(companyId, payload);
    return result.when(
      success: (value) => Result.success(Map<String, dynamic>.from(value)),
      failure: (error) => Result.failure(error),
    );
  }

  Future<Result<String, AppError>> uploadAdminFile({
    required String type,
    required Uint8List bytes,
    required String filename,
    String? contentType,
    Object? cancelToken,
  }) {
    return _repository.uploadAdminFile(type: type, bytes: bytes, filename: filename, contentType: contentType);
  }

  Future<Result<List<AdminLinkedVehicle>, AppError>> getLinkedVehicles({required String userId, Object? cancelToken}) {
    return _repository.getLinkedVehicles(userId: userId);
  }

  Future<Result<void, AppError>> renewVehicles({
    required String userId,
    required List<int> vehicleIds,
    required String paymentMode,
    required double amount,
    Object? cancelToken,
  }) {
    return _repository.renewVehicles(userId: userId, vehicleIds: vehicleIds, paymentMode: paymentMode, amount: amount);
  }
}
