import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:retrofit/retrofit.dart';
import 'package:open_vts/features/user/data/models/user_notification_dtos.dart';

part 'user_notification_api_service.g.dart';

@RestApi()
abstract class UserNotificationApiService {
  factory UserNotificationApiService(Dio dio, {String? baseUrl}) = _UserNotificationApiService;

  @GET('/user/notifications')
  Future<ApiResponse<List<Map<String, dynamic>>>> getNotifications();

  @PATCH('/user/notifications/{id}/read')
  Future<ApiResponse<void>> markNotificationRead(@Path('id') String id);

  @PATCH('/user/notifications/read-all')
  Future<ApiResponse<void>> markAllNotificationsRead();

  @GET('/user/notifications/preferences')
  Future<ApiResponse<Map<String, dynamic>>> getPreferences();

  @PUT('/user/notifications/preferences')
  Future<ApiResponse<void>> updatePreferences(@Body() UserNotificationPreferencesMutationDto body);
}
