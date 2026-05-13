import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:open_vts/features/admin/data/models/admin_operations_dtos.dart';
import 'package:retrofit/retrofit.dart';

part 'admin_operations_api_service.g.dart';

@RestApi()
abstract class AdminOperationsApiService {
  factory AdminOperationsApiService(Dio dio, {String? baseUrl}) = _AdminOperationsApiService;

  @GET('/admin/calendar/events')
  Future<ApiResponse<Map<String, dynamic>>> getCalendarEvents({
    @Queries() Map<String, Object?>? query,
  });

  @GET('/admin/calendar/day')
  Future<ApiResponse<Map<String, dynamic>>> getCalendarDay({
    @Queries() Map<String, Object?>? query,
  });

  @GET('/admin/logs/options')
  Future<ApiResponse<Map<String, dynamic>>> getLogOptions();

  @GET('/admin/logs/activity')
  Future<ApiResponse<Map<String, dynamic>>> getLogActivity({
    @Queries() Map<String, Object?>? query,
  });

  @GET('/admin/logs/events')
  Future<ApiResponse<Map<String, dynamic>>> getLogEvents({
    @Queries() Map<String, Object?>? query,
  });

  @GET('/admin/notifications')
  Future<ApiResponse<Map<String, dynamic>>> getNotifications();

  @PATCH('/admin/notifications/{id}/read')
  Future<ApiResponse<void>> markNotificationRead(@Path('id') String id);

  @PATCH('/admin/notifications/read-all')
  Future<ApiResponse<void>> markAllNotificationsRead(@Body() AdminEmptyRequestDto body);

  @GET('/admin/users')
  Future<ApiResponse<Map<String, dynamic>>> searchNotificationRecipients({
    @Queries() Map<String, Object?>? query,
  });

  @POST('/admin/notifications/send')
  Future<ApiResponse<void>> sendNotification(@Body() AdminSendNotificationRequestDto body);

  @GET('/admin/payments')
  Future<ApiResponse<Map<String, dynamic>>> getPayments({
    @Queries() Map<String, Object?>? query,
  });

  @POST('/admin/payments/renew')
  Future<ApiResponse<void>> createPayment(@Body() AdminCreatePaymentRequestDto body);

  @GET('/admin/pricingplans')
  Future<ApiResponse<Map<String, dynamic>>> getPricingPlans();

  @POST('/admin/pricingplans')
  Future<ApiResponse<Map<String, dynamic>>> createPricingPlan(@Body() AdminCreatePricingPlanRequestDto body);

  @GET('/admin/transactions')
  Future<ApiResponse<Map<String, dynamic>>> getTransactions({
    @Queries() Map<String, Object?>? query,
  });

  @GET('/admin/transactions/analytics')
  Future<ApiResponse<Map<String, dynamic>>> getTransactionsSummary();

  @GET('/admin/linkvehicles/{userId}')
  Future<ApiResponse<Map<String, dynamic>>> getUserLinkedVehicles(@Path('userId') String userId);
}
