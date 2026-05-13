import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/user/domain/repositories/user_notification_repository.dart';

class UpdateUserNotificationPreferencesUseCase {
  const UpdateUserNotificationPreferencesUseCase(this._repository);
  final UserNotificationRepository _repository;
  Future<Result<void, AppError>> call(Map<String, Object?> payload) => _repository.updatePreferences(payload);
}
