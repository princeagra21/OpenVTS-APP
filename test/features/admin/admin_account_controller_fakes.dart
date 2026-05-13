import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_document_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_transaction_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_ticket_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_details.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_vehicle_list_item.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_account_repository.dart';
import 'package:open_vts/shared/models/admin_profile.dart';

class FakeAdminAccountRepository implements AdminAccountRepository {
  List<AdminUserListItem> users = const <AdminUserListItem>[];
  AdminUserDetails? details;
  List<AdminVehicleListItem> vehicles = const <AdminVehicleListItem>[];
  List<AdminDriverListItem> drivers = const <AdminDriverListItem>[];
  List<AdminDocumentItem> documents = const <AdminDocumentItem>[];
  List<AdminTicketListItem> tickets = const <AdminTicketListItem>[];
  List<AdminTransactionItem> payments = const <AdminTransactionItem>[];
  AdminProfile profile = const AdminProfile(<String, dynamic>{});
  AppError? failure;
  String loginToken = 'impersonation-token';

  @override
  Future<Result<List<AdminUserListItem>, AppError>> getUsers({
    String? search,
    String? status,
    int? page,
    int? limit,
  }) async {
    final error = failure;
    if (error != null) return Result.failure(error);
    return Result.success(users);
  }

  @override
  Future<Result<AdminUserDetails, AppError>> getUserDetails(String userId) async {
    final error = failure;
    if (error != null) return Result.failure(error);
    return Result.success(details ?? AdminUserDetails(<String, Object?>{'id': userId}));
  }

  @override
  Future<Result<void, AppError>> updateUserStatus(String userId, bool isActive) async {
    final error = failure;
    if (error != null) return Result.failure(error);
    return const Result.success(null);
  }

  @override
  Future<Result<String, AppError>> loginAsUser(String userId) async {
    final error = failure;
    if (error != null) return Result.failure(error);
    return Result.success(loginToken);
  }

  @override
  Future<Result<List<AdminVehicleListItem>, AppError>> getUserLinkedVehicles(String userId) async {
    final error = failure;
    if (error != null) return Result.failure(error);
    return Result.success(vehicles);
  }


  @override
  Future<Result<List<AdminDriverListItem>, AppError>> getUserLinkedDrivers(String userId) async {
    final error = failure;
    if (error != null) return Result.failure(error);
    return Result.success(drivers);
  }

  @override
  Future<Result<List<AdminDocumentItem>, AppError>> getUserDocuments(String userId) async {
    final error = failure;
    if (error != null) return Result.failure(error);
    return Result.success(documents);
  }

  @override
  Future<Result<List<AdminTicketListItem>, AppError>> getUserTickets(String userId, {int? limit, int? rk}) async {
    final error = failure;
    if (error != null) return Result.failure(error);
    return Result.success(tickets);
  }


  @override
  Future<Result<List<AdminTransactionItem>, AppError>> getUserPayments(String userId) async {
    final error = failure;
    if (error != null) return Result.failure(error);
    return Result.success(payments);
  }

  @override
  Future<Result<AdminProfile, AppError>> getMyProfile() async {
    final error = failure;
    if (error != null) return Result.failure(error);
    return Result.success(profile);
  }

  @override
  Future<Result<AdminProfile, AppError>> updateMyProfile(Map<String, Object?> payload) async {
    final error = failure;
    if (error != null) return Result.failure(error);
    profile = AdminProfile(<String, dynamic>{...profile.raw, ...payload});
    return Result.success(profile);
  }

  @override
  Future<Result<void, AppError>> updatePassword({required String currentPassword, required String newPassword}) async {
    final error = failure;
    if (error != null) return Result.failure(error);
    return const Result.success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
