import 'package:open_vts/core/utils/request_control.dart';
import 'package:open_vts/features/user/domain/entities/user_notification_preferences.dart';
import 'package:open_vts/core/api/api_paths.dart';
import 'package:open_vts/core/api/api_result.dart';
import 'package:open_vts/core/debug/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:open_vts/core/api/legacy_api_transport.dart';

/// Infrastructure is injected by AppContainer.
/// Do not instantiate transport client, AppConfig, or TokenStorage inside this repository.
class UserNotificationPreferencesRepository {
  final LegacyApiTransport api;

  const UserNotificationPreferencesRepository({required this.api});

  Future<Result<UserNotificationPreferences>> getPreferences({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      ApiPaths.userNotificationsPreferences,
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
    final payload = <String, Object?>{
      'settings': [item.toPayload()],
      'channels': <String, Object?>{
        item.eventType: <String, Object?>{
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
    Map<String, Object?> payload, {
    CancelToken? cancelToken,
  }) async {
    if (kDebugMode) {
      AppLogger.debug(
        'PUT ${ApiPaths.userNotificationsPreferences} payload: $payload',
      );
    }
    final res = await api.put(
      ApiPaths.userNotificationsPreferences,
      data: payload,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        if (kDebugMode) {
          AppLogger.debug(
            'PUT ${ApiPaths.userNotificationsPreferences} response: $data',
          );
        }
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
