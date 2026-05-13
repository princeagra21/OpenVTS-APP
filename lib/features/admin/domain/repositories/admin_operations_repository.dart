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

abstract interface class AdminOperationsRepository {
  Future<Result<List<AdminCalendarEventItem>, AppError>> getCalendarEvents({
    required String from,
    required String to,
  });

  Future<Result<List<AdminCalendarEventItem>, AppError>> getCalendarDayEvents({
    required String date,
  });

  Future<Result<List<AdminLogItem>, AppError>> getLogs({
    String? search,
    String? level,
    int? page,
    int? limit,
    String? from,
    String? to,
  });

  Future<Result<List<AdminNotificationItem>, AppError>> getNotifications();
  Future<Result<void, AppError>> markNotificationRead(String id);
  Future<Result<void, AppError>> markAllNotificationsRead();

  Future<Result<List<AdminUserRecipient>, AppError>> searchNotificationRecipients({
    String query = '',
  });

  Future<Result<void, AppError>> sendNotification({
    required String channel,
    required List<String> userIds,
    String? subject,
    required String message,
  });

  Future<Result<List<AdminTransactionItem>, AppError>> getPayments({
    String? search,
    String? status,
    int? page,
    int? limit,
    String? from,
    String? to,
  });

  Future<Result<void, AppError>> createPayment({
    required String userId,
    required List<String> vehicleIds,
    required String amount,
    required String paymentMode,
  });

  Future<Result<List<PricingPlan>, AppError>> getPricingPlans();

  Future<Result<Map<String, Object?>, AppError>> createPricingPlan({
    required String name,
    required int durationDays,
    required num price,
    required String currency,
  });

  Future<Result<List<AdminTransactionItem>, AppError>> getTransactions({
    String? search,
    String? status,
    int? page,
    int? limit,
    String? from,
    String? to,
  });

  Future<Result<AdminTransactionsSummary, AppError>> getTransactionsSummary();

  Future<Result<List<AdminLinkedVehicle>, AppError>> getLinkedVehicles({
    required String userId,
  });
}
