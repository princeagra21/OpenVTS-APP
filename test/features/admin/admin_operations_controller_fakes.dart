import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_calendar_event_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_linked_vehicle.dart';
import 'package:open_vts/features/admin/domain/entities/admin_log_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_notification_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_transaction_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_transactions_summary.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_recipient.dart';
import 'package:open_vts/features/admin/domain/entities/pricing_plan.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_operations_repository.dart';

class FakeAdminOperationsRepository implements AdminOperationsRepository {
  Result<List<AdminLogItem>, AppError> logsResult = const Result.success(<AdminLogItem>[]);
  Result<List<AdminNotificationItem>, AppError> notificationsResult = const Result.success(<AdminNotificationItem>[]);
  Result<List<AdminUserRecipient>, AppError> recipientsResult = const Result.success(<AdminUserRecipient>[]);
  Result<void, AppError> sendResult = const Result.success(null);
  Result<List<AdminTransactionItem>, AppError> paymentsResult = const Result.success(<AdminTransactionItem>[]);
  Result<void, AppError> createPaymentResult = const Result.success(null);

  @override
  Future<Result<List<AdminCalendarEventItem>, AppError>> getCalendarEvents({required String from, required String to}) async {
    return const Result.success(<AdminCalendarEventItem>[]);
  }

  @override
  Future<Result<List<AdminCalendarEventItem>, AppError>> getCalendarDayEvents({required String date}) async {
    return const Result.success(<AdminCalendarEventItem>[]);
  }

  @override
  Future<Result<List<AdminLogItem>, AppError>> getLogs({String? search, String? level, int? page, int? limit, String? from, String? to}) async {
    return logsResult;
  }

  @override
  Future<Result<List<AdminNotificationItem>, AppError>> getNotifications() async {
    return notificationsResult;
  }

  @override
  Future<Result<void, AppError>> markNotificationRead(String id) async {
    return const Result.success(null);
  }

  @override
  Future<Result<void, AppError>> markAllNotificationsRead() async {
    return const Result.success(null);
  }

  @override
  Future<Result<List<AdminUserRecipient>, AppError>> searchNotificationRecipients({String query = ''}) async {
    return recipientsResult;
  }

  @override
  Future<Result<void, AppError>> sendNotification({required String channel, required List<String> userIds, String? subject, required String message}) async {
    return sendResult;
  }

  @override
  Future<Result<List<AdminTransactionItem>, AppError>> getPayments({String? search, String? status, int? page, int? limit, String? from, String? to}) async {
    return paymentsResult;
  }

  @override
  Future<Result<void, AppError>> createPayment({required String userId, required List<String> vehicleIds, required String amount, required String paymentMode}) async {
    return createPaymentResult;
  }

  @override
  Future<Result<List<PricingPlan>, AppError>> getPricingPlans() async {
    return const Result.success(<PricingPlan>[]);
  }

  @override
  Future<Result<Map<String, Object?>, AppError>> createPricingPlan({required String name, required int durationDays, required num price, required String currency}) async {
    return const Result.success(<String, Object?>{});
  }

  @override
  Future<Result<List<AdminTransactionItem>, AppError>> getTransactions({String? search, String? status, int? page, int? limit, String? from, String? to}) async {
    return const Result.success(<AdminTransactionItem>[]);
  }

  @override
  Future<Result<AdminTransactionsSummary, AppError>> getTransactionsSummary() async {
    return Result.success(AdminTransactionsSummary.fromRaw(const <String, Object?>{}));
  }

  @override
  Future<Result<List<AdminLinkedVehicle>, AppError>> getLinkedVehicles({required String userId}) async {
    return const Result.success(<AdminLinkedVehicle>[]);
  }
}
