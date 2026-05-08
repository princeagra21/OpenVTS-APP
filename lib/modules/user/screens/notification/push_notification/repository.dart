import 'package:dio/dio.dart';
import 'package:open_vts/core/models/user_notification_preferences.dart';
import 'package:open_vts/core/network/result.dart';
import 'package:open_vts/core/repositories/user_notification_preferences_repository.dart';

class PushNotificationRepository {
  const PushNotificationRepository({required UserNotificationPreferencesRepository delegate})
    : _delegate = delegate;

  final UserNotificationPreferencesRepository _delegate;

  Future<Result<UserNotificationPreferences>> getPreferences({
    CancelToken? cancelToken,
  }) {
    return _delegate.getPreferences(cancelToken: cancelToken);
  }

  Future<Result<void>> updatePreference(
    UserNotificationPreferenceItem item, {
    CancelToken? cancelToken,
  }) {
    return _delegate.updatePreference(item, cancelToken: cancelToken);
  }

  Future<Result<void>> updatePreferencesPayload(
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) {
    return _delegate.updatePreferencesPayload(payload, cancelToken: cancelToken);
  }
}
