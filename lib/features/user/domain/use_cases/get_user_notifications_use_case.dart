import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/domain/entities/user_notification_item.dart';
import 'package:open_vts/features/user/domain/repositories/user_notification_repository.dart';

class GetUserNotificationsUseCase {
  const GetUserNotificationsUseCase(this._repository);
  final UserNotificationRepository _repository;
  Future<Result<List<UserNotificationItem>, AppError>> call() => _repository.getNotifications();
}
