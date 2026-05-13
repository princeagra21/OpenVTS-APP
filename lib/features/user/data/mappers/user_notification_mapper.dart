import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/features/user/data/models/user_notification_dtos.dart';
import 'package:open_vts/features/user/domain/entities/user_notification_item.dart';
import 'package:open_vts/features/user/domain/entities/user_notification_preferences.dart';

class UserNotificationMapper {
  const UserNotificationMapper();

  List<UserNotificationDto> notificationsFromResponse(Object? response) {
    return ApiResponseNormalizer.listOf(
      response,
      preferredKeys: const ['notifications', 'items', 'rows'],
    ).whereType<Map>().map((item) => UserNotificationDto(_map(item))).toList(growable: false);
  }

  UserNotificationPreferencesDto preferencesFromResponse(Object? response) {
    final map = ApiResponseNormalizer.mapPayloadOf(
      response,
      preferredKeys: const ['preferences', 'settings', 'notificationPreferences'],
    );
    return UserNotificationPreferencesDto(map.isEmpty ? ApiResponseNormalizer.mapOf(response) : map);
  }

  List<UserNotificationItem> toNotifications(List<UserNotificationDto> items) {
    return items.map(toNotification).toList(growable: false);
  }

  UserNotificationItem toNotification(UserNotificationDto dto) {
    final raw = dto.json;
    return UserNotificationItem(
      id: _text(raw['id'] ?? raw['notificationId'] ?? raw['notification_id'] ?? raw['uid'] ?? raw['_id'] ?? raw['code']),
      title: _text(raw['title'] ?? raw['subject'] ?? raw['name'] ?? raw['heading']),
      body: _text(raw['message'] ?? raw['body'] ?? raw['description'] ?? raw['content']),
      createdAt: _text(raw['createdAt'] ?? raw['created_at'] ?? raw['timestamp'] ?? raw['time'] ?? raw['date']),
      type: _text(raw['type'] ?? raw['category'] ?? raw['kind'] ?? raw['eventType']),
      isRead: _readState(raw),
    );
  }

  UserNotificationPreferences toPreferences(UserNotificationPreferencesDto dto) {
    return UserNotificationPreferences(dto.json);
  }

  UserNotificationPreferencesMutationDto mutation(Map<String, Object?> body) => UserNotificationPreferencesMutationDto(body);

  static bool _readState(Map<String, Object?> raw) {
    final direct = _boolOrNull(raw['isRead'] ?? raw['read'] ?? raw['is_read'] ?? raw['seen']);
    if (direct != null) return direct;
    final status = _text(raw['status'] ?? raw['state']).toLowerCase();
    return status == 'read' || status == 'seen' || status == 'closed';
  }

  static Map<String, Object?> _map(Map value) => <String, Object?>{for (final entry in value.entries) entry.key.toString(): entry.value};

  static String _text(Object? value) {
    if (value == null) return '';
    final text = value.toString().trim();
    return text.toLowerCase() == 'null' ? '' : text;
  }

  static bool? _boolOrNull(Object? value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final text = value.trim().toLowerCase();
      if (text == 'true' || text == '1' || text == 'yes') return true;
      if (text == 'false' || text == '0' || text == 'no') return false;
    }
    return null;
  }
}
