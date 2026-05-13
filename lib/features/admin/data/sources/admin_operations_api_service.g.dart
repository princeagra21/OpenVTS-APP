// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_operations_api_service.dart';

class _AdminOperationsApiService implements AdminOperationsApiService {
  _AdminOperationsApiService(this._dio, {this.baseUrl});

  final Dio _dio;
  final String? baseUrl;

  ApiResponse<T> decode<T>(Object? data, T Function(Object? json) fromJsonT) {
    if (data is Map<String, dynamic>) return ApiResponse<T>.fromJson(data, fromJsonT);
    if (data is Map) return ApiResponse<T>.fromJson(Map<String, dynamic>.from(data.cast()), fromJsonT);
    return ApiResponse<T>(
      status: '',
      timestamp: null,
      data: ApiData<T>(action: false, message: 'Invalid API response', data: null),
    );
  }

  Map<String, dynamic> mapValue(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value.cast());
    return const <String, dynamic>{};
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getCalendarEvents({Map<String, Object?>? query}) async {
    final response = await _dio.get<Object?>('/admin/calendar/events', queryParameters: query);
    return decode(response.data, mapValue);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getCalendarDay({Map<String, Object?>? query}) async {
    final response = await _dio.get<Object?>('/admin/calendar/day', queryParameters: query);
    return decode(response.data, mapValue);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getLogOptions() async {
    final response = await _dio.get<Object?>('/admin/logs/options');
    return decode(response.data, mapValue);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getLogActivity({Map<String, Object?>? query}) async {
    final response = await _dio.get<Object?>('/admin/logs/activity', queryParameters: query);
    return decode(response.data, mapValue);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getLogEvents({Map<String, Object?>? query}) async {
    final response = await _dio.get<Object?>('/admin/logs/events', queryParameters: query);
    return decode(response.data, mapValue);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getNotifications() async {
    final response = await _dio.get<Object?>('/admin/notifications');
    return decode(response.data, mapValue);
  }

  @override
  Future<ApiResponse<void>> markNotificationRead(String id) async {
    final response = await _dio.patch<Object?>('/admin/notifications/$id/read');
    return decode<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<void>> markAllNotificationsRead(AdminEmptyRequestDto body) async {
    final response = await _dio.patch<Object?>('/admin/notifications/read-all', data: body.toJson());
    return decode<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> searchNotificationRecipients({Map<String, Object?>? query}) async {
    final response = await _dio.get<Object?>('/admin/users', queryParameters: query);
    return decode(response.data, mapValue);
  }

  @override
  Future<ApiResponse<void>> sendNotification(AdminSendNotificationRequestDto body) async {
    final response = await _dio.post<Object?>('/admin/notifications/send', data: body.toJson());
    return decode<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getPayments({Map<String, Object?>? query}) async {
    final response = await _dio.get<Object?>('/admin/payments', queryParameters: query);
    return decode(response.data, mapValue);
  }

  @override
  Future<ApiResponse<void>> createPayment(AdminCreatePaymentRequestDto body) async {
    final response = await _dio.post<Object?>('/admin/payments/renew', data: body.toJson());
    return decode<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getPricingPlans() async {
    final response = await _dio.get<Object?>('/admin/pricingplans');
    return decode(response.data, mapValue);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> createPricingPlan(AdminCreatePricingPlanRequestDto body) async {
    final response = await _dio.post<Object?>('/admin/pricingplans', data: body.toJson());
    return decode(response.data, mapValue);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getTransactions({Map<String, Object?>? query}) async {
    final response = await _dio.get<Object?>('/admin/transactions', queryParameters: query);
    return decode(response.data, mapValue);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getTransactionsSummary() async {
    final response = await _dio.get<Object?>('/admin/transactions/analytics');
    return decode(response.data, mapValue);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getUserLinkedVehicles(String userId) async {
    final response = await _dio.get<Object?>('/admin/linkvehicles/$userId');
    return decode(response.data, mapValue);
  }
}
