import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/domain/entities/user_notification_item.dart';
import 'package:open_vts/features/user/domain/entities/user_notification_preferences.dart';

abstract interface class UserNotificationRepository {
  Future<Result<List<UserNotificationItem>, AppError>> getNotifications();
  Future<Result<void, AppError>> markNotificationRead(String id);
  Future<Result<void, AppError>> markAllNotificationsRead();
  Future<Result<UserNotificationPreferences, AppError>> getPreferences();
  Future<Result<void, AppError>> updatePreferences(Map<String, Object?> payload);
}
