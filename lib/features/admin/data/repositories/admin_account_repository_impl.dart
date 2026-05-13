import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/data/mappers/admin_account_mapper.dart';
import 'package:open_vts/features/admin/data/models/admin_account_dtos.dart';
import 'package:open_vts/features/admin/data/sources/admin_account_api_service.dart';
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

class AdminAccountRepositoryImpl implements AdminAccountRepository {
  const AdminAccountRepositoryImpl({
    required AdminAccountApiService api,
    required AdminAccountMapper mapper,
  })  : _api = api,
        _mapper = mapper;

  final AdminAccountApiService _api;
  final AdminAccountMapper _mapper;

  @override
  Future<Result<List<AdminUserListItem>, AppError>> getUsers({
    String? search,
    String? status,
    int? page,
    int? limit,
  }) async {
    return _guard(() async {
      final query = <String, Object?>{
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
        'rk': DateTime.now().millisecondsSinceEpoch,
      };
      final response = await _api.getUsers(query: query);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.users(response));
    });
  }

  @override
  Future<Result<AdminUserDetails, AppError>> getUserDetails(String userId) async {
    return _guard(() async {
      final response = await _api.getUserDetails(userId);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.userDetails(response));
    });
  }

  @override
  Future<Result<String, AppError>> loginAsUser(String userId) async {
    return _guard(() async {
      final response = await _api.loginAsUser(userId);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      final token = _mapper.loginToken(response);
      if (token.trim().isEmpty) {
        return const Result.failure(AuthError('Token not found in user login response.'));
      }
      return Result.success(token);
    });
  }

  @override
  Future<Result<void, AppError>> updateUserStatus(String userId, bool isActive) async {
    return _guardVoid(() => _api.updateUserStatus(userId, UpdateAdminUserStatusRequestDto(isActive: isActive)));
  }

  @override
  Future<Result<List<AdminVehicleListItem>, AppError>> getUserLinkedVehicles(String userId) async {
    final Result<List<AdminVehicleListItem>, AppError> primary = await _guard<List<AdminVehicleListItem>>(() async {
      final response = await _api.getUserLinkedVehicles(userId);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.vehicles(response));
    });
    if (primary.isSuccess) return primary;
    return _guard<List<AdminVehicleListItem>>(() async {
      final response = await _api.getUserLinkedVehiclesByQuery(userId: userId);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.vehicles(response));
    });
  }

  @override
  Future<Result<List<AdminVehicleListItem>, AppError>> getUnlinkedVehicles({String? userId}) async {
    Future<Result<List<AdminVehicleListItem>, AppError>> fetch(Map<String, dynamic>? query) {
      return _guard<List<AdminVehicleListItem>>(() async {
        final response = await _api.getUnlinkedVehicles(query: query);
        final failure = _failureIfRejected(response);
        if (failure != null) return Result.failure(failure);
        return Result.success(_mapper.vehicles(response));
      });
    }

    final first = await fetch(null);
    if (first.isSuccess || userId == null || userId.trim().isEmpty) return first;

    final Result<List<AdminVehicleListItem>, AppError> byPath = await _guard<List<AdminVehicleListItem>>(() async {
      final response = await _api.getUnlinkedVehiclesByUser(userId);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.vehicles(response));
    });
    if (byPath.isSuccess) return byPath;

    final byQuery = await fetch(<String, dynamic>{'userId': userId});
    return byQuery.isSuccess ? byQuery : first;
  }

  @override
  Future<Result<void, AppError>> assignVehicleToUser({required String userId, required String vehicleId}) async {
    return _guardVoid(() => _api.assignVehicleToUser(vehicleId, AdminAssignVehicleRequestDto(userId: userId)));
  }

  @override
  Future<Result<List<AdminDriverListItem>, AppError>> getUserLinkedDrivers(String userId) async {
    return _guard(() async {
      final response = await _api.getUserLinkedDrivers(userId);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.drivers(response));
    });
  }

  @override
  Future<Result<List<AdminDocumentItem>, AppError>> getUserDocuments(String userId) async {
    return _guard(() async {
      final response = await _api.getUserDocuments(userId);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.documents(response));
    });
  }

  @override
  Future<Result<List<SuperadminDocumentType>, AppError>> getDocumentTypes() async {
    return _guard(() async {
      final response = await _api.getDocumentTypes();
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.documentTypes(response));
    });
  }

  @override
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
  }) async {
    final dto = AdminUploadDocumentRequestDto(
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
    return _guardVoid(() => _api.uploadDocument(dto.toFormData()));
  }

  @override
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
  }) async {
    final dto = AdminUpdateDocumentRequestDto(
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
    return _guardVoid(() => _api.updateDocument(documentId, dto.toFormData()));
  }

  @override
  Future<Result<void, AppError>> deleteDocumentFile(String documentId) async {
    return _guardVoid(() => _api.deleteDocumentFile(documentId));
  }

  @override
  Future<Result<List<AdminTicketListItem>, AppError>> getUserTickets(String userId, {int? limit, int? rk}) async {
    return _guard(() async {
      final query = <String, Object?>{'userId': userId, if (limit != null) 'limit': limit, if (rk != null) 'rk': rk};
      final response = await _api.getUserTickets(query: query);
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.tickets(response));
    });
  }

  @override
  Future<Result<List<Map<String, Object?>>, AppError>> getUserActivityLogs(String userId, {int? limit}) async {
    return _guard(() async {
      final response = await _api.getUserActivityLogs(userId, query: <String, Object?>{if (limit != null) 'limit': limit});
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.activityLogs(response));
    });
  }

  @override
  Future<Result<List<AdminTransactionItem>, AppError>> getUserPayments(String userId) async {
    return _guard(() async {
      final response = await _api.getUserPayments(query: <String, Object?>{'page': 1, 'limit': 1000, 'userId': userId});
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.payments(response));
    });
  }

  @override
  Future<Result<void, AppError>> updateUserPassword(String userId, String newPassword) async {
    return _guardVoid(() => _api.updateUserPassword(userId, UpdateAdminUserPasswordRequestDto(newPassword: newPassword)));
  }

  @override
  Future<Result<AdminProfile, AppError>> getMyProfile() async {
    return _guard(() async {
      final response = await _api.getMyProfile();
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.profile(response));
    });
  }

  @override
  Future<Result<AdminProfile, AppError>> updateMyProfile(Map<String, Object?> payload) async {
    return _guard(() async {
      final response = await _api.updateMyProfile(AdminProfileUpdateRequestDto(payload));
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.profile(response));
    });
  }

  @override
  Future<Result<void, AppError>> updatePassword({required String currentPassword, required String newPassword}) async {
    if (currentPassword.trim().isEmpty || newPassword.trim().isEmpty) {
      return const Result.failure(ValidationError('currentPassword and newPassword required'));
    }
    return _guardVoid(
      () => _api.updatePassword(UpdateAdminPasswordRequestDto(currentPassword: currentPassword, newPassword: newPassword)),
    );
  }

  @override
  Future<Result<void, AppError>> sendEmailOtp() async => _guardVoid(() => _api.sendEmailOtp(const AdminOtpRequestDto()));

  @override
  Future<Result<void, AppError>> verifyEmailOtp(String code) async =>
      _guardVoid(() => _api.verifyEmailOtp(AdminOtpRequestDto(otp: code)));

  @override
  Future<Result<void, AppError>> sendPhoneOtp() async => _guardVoid(() => _api.sendPhoneOtp(const AdminOtpRequestDto()));

  @override
  Future<Result<void, AppError>> verifyPhoneOtp(String code) async =>
      _guardVoid(() => _api.verifyPhoneOtp(AdminOtpRequestDto(otp: code)));

  @override
  Future<Result<Map<String, Object?>, AppError>> updateCompanyDetails(String companyId, Map<String, Object?> payload) async {
    if (companyId.trim().isEmpty) {
      return const Result.failure(ValidationError('Company id is required'));
    }
    return _guard(() async {
      final response = await _api.updateCompanyDetails(companyId, AdminCompanyUpdateRequestDto(payload));
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.companyDetails(response));
    });
  }

  @override
  Future<Result<String, AppError>> uploadAdminFile({
    required String type,
    required Uint8List bytes,
    required String filename,
    String? contentType,
  }) async {
    return _guard(() async {
      final dto = AdminUploadFileRequestDto(type: type, bytes: bytes, filename: filename, contentType: contentType);
      final response = await _api.uploadAdminFile(dto.toFormData());
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.uploadedFileUrl(response));
    });
  }

  @override
  Future<Result<List<AdminLinkedVehicle>, AppError>> getLinkedVehicles({required String userId}) async {
    return _guard(() async {
      final response = await _api.getLinkedVehicles(userId, query: <String, Object?>{'rk': DateTime.now().millisecondsSinceEpoch});
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return Result.success(_mapper.linkedVehicles(response));
    });
  }

  @override
  Future<Result<void, AppError>> renewVehicles({
    required String userId,
    required List<int> vehicleIds,
    required String paymentMode,
    required double amount,
  }) async {
    return _guardVoid(
      () => _api.renewVehicles(
        AdminRenewVehiclesRequestDto(userId: userId, vehicleIds: vehicleIds, paymentMode: paymentMode),
      ),
    );
  }

  Future<Result<T, AppError>> _guard<T>(Future<Result<T, AppError>> Function() run) async {
    try {
      return await run();
    } on DioException catch (error) {
      return Result.failure(AppErrorMapper.fromDio(error));
    } catch (error) {
      return Result.failure(AppErrorMapper.fromObject(error));
    }
  }

  Future<Result<void, AppError>> _guardVoid(Future<ApiResponse<void>> Function() request) async {
    return _guard(() async {
      final response = await request();
      final failure = _failureIfRejected(response);
      if (failure != null) return Result.failure(failure);
      return const Result.success(null);
    });
  }

  AppError? _failureIfRejected<T>(ApiResponse<T> response) {
    if (response.action) return null;
    return ServerError(response.message.trim().isEmpty ? 'Request failed' : response.message);
  }
}
