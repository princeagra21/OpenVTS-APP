import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/user_notification_preferences.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';

class UserNotificationPreferencesRepository {
  final ApiClient api;

  const UserNotificationPreferencesRepository({required this.api});

  Future<Result<UserNotificationPreferences>> getPreferences({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/user/notifications/preferences',
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) => Result.ok(UserNotificationPreferences(_asMap(data))),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> updatePreference(
    UserNotificationPreferenceItem item, {
    CancelToken? cancelToken,
  }) async {
    final payload = <String, dynamic>{
      'settings': [item.toPayload()],
      'channels': <String, dynamic>{
        item.eventType: <String, dynamic>{
          'notifyEmail': item.notifyEmail,
          'notifyWhatsapp': item.notifyWhatsapp,
          'notifyWebPush': item.notifyWebPush,
          'notifyMobilePush': item.notifyMobilePush,
          'notifyTelegram': item.notifyTelegram,
          'notifySms': item.notifySms,
        },
      },
    };
    final res = await updatePreferencesPayload(
      payload,
      cancelToken: cancelToken,
    );

    return res;
  }

  Future<Result<void>> updatePreferencesPayload(
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    // Debug logging for mismatch issues.
    assert(() {
      // ignore: avoid_print
      print('PUT /user/notifications/preferences payload: $payload');
      return true;
    }());
    final res = await api.put(
      '/user/notifications/preferences',
      data: payload,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        assert(() {
          // ignore: avoid_print
          print('PUT /user/notifications/preferences response: $data');
          return true;
        }());
        return Result.ok(null);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value.cast());
    return const <String, dynamic>{};
  }
}
