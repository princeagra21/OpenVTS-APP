import 'package:open_vts/core/utils/presentation_result.dart' as legacy;
import 'package:open_vts/features/user/domain/entities/user_notification_preferences.dart';
import 'package:open_vts/features/user/domain/repositories/user_notification_repository.dart';

class PushNotificationRepository {
  const PushNotificationRepository({required UserNotificationRepository repository})
    : _repository = repository;

  final UserNotificationRepository _repository;

  Future<legacy.Result<UserNotificationPreferences>> getPreferences() async {
    final result = await _repository.getPreferences();
    return result.when(
      success: legacy.Result.ok,
      failure: legacy.Result.fail,
    );
  }

  Future<legacy.Result<void>> updatePreference(UserNotificationPreferenceItem item) {
    return updatePreferencesPayload(<String, Object?>{
      'settings': <Object?>[item.toPayload()],
    });
  }

  Future<legacy.Result<void>> updatePreferencesPayload(Map<String, Object?> payload) async {
    final result = await _repository.updatePreferences(payload);
    return result.when(
      success: legacy.Result.ok,
      failure: legacy.Result.fail,
    );
  }
}
