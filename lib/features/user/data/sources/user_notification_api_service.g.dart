// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_notification_api_service.dart';

class _UserNotificationApiService implements UserNotificationApiService {
  _UserNotificationApiService(this._dio, {this.baseUrl});

  final Dio _dio;
  final String? baseUrl;

  @override
  Future<ApiResponse<List<Map<String, dynamic>>>> getNotifications() async {
    final response = await _dio.get<Object?>('/user/notifications');
    return apiDecodeResponse<List<Map<String, dynamic>>>(response.data, apiListMapDynamic);
  }

  @override
  Future<ApiResponse<void>> markNotificationRead(String id) async {
    final response = await _dio.patch<Object?>('/user/notifications/$id/read');
    return apiDecodeResponse<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<void>> markAllNotificationsRead() async {
    final response = await _dio.patch<Object?>('/user/notifications/read-all');
    return apiDecodeResponse<void>(response.data, (_) {});
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getPreferences() async {
    final response = await _dio.get<Object?>('/user/notifications/preferences');
    return apiDecodeResponse<Map<String, dynamic>>(response.data, apiMapDynamic);
  }

  @override
  Future<ApiResponse<void>> updatePreferences(UserNotificationPreferencesMutationDto body) async {
    final response = await _dio.put<Object?>('/user/notifications/preferences', data: body.toJson());
    return apiDecodeResponse<void>(response.data, (_) {});
  }
}
