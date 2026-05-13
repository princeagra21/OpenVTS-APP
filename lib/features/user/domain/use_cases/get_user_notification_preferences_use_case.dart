import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/domain/entities/user_notification_preferences.dart';
import 'package:open_vts/features/user/domain/repositories/user_notification_repository.dart';

class GetUserNotificationPreferencesUseCase {
  const GetUserNotificationPreferencesUseCase(this._repository);
  final UserNotificationRepository _repository;

  Future<Result<UserNotificationPreferences, AppError>> call() => _repository.getPreferences();
}
