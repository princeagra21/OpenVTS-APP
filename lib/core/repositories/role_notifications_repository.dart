import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/admin_notification_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';

class RoleNotificationsRepository {
  final ApiClient api;
  final String pathPrefix;

  const RoleNotificationsRepository({
    required this.api,
    required this.pathPrefix,
  });

  Future<Result<List<AdminNotificationItem>>> getNotifications({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(pathPrefix, cancelToken: cancelToken);

    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          extraKeys: const ['notifications', 'notification', 'rows'],
        );

        final out = <AdminNotificationItem>[];
        if (list != null) {
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              out.add(AdminNotificationItem(item));
            } else if (item is Map) {
              out.add(AdminNotificationItem(Map<String, dynamic>.from(item)));
            }
          }
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> markRead(String id, {CancelToken? cancelToken}) async {
    final res = await api.patch(
      '$pathPrefix/$id/read',
      cancelToken: cancelToken,
    );
    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> markAllRead({CancelToken? cancelToken}) async {
    final res = await api.patch(
      '$pathPrefix/read-all',
      cancelToken: cancelToken,
    );
    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  List? _extractList(Object? data, {List<String> extraKeys = const []}) {
    if (data is List) return data;

    final keys = <String>['data', 'items', 'result', 'results', ...extraKeys];

    List? walk(Object? node, int depth) {
      if (depth > 6) return null;
      if (node is List) return node;
      if (node is! Map) return null;

      final map = _asMap(node);
      for (final key in keys) {
        final value = map[key];
        if (value is List) return value;
      }

      for (final value in map.values) {
        if (value is List || value is Map) {
          final found = walk(value, depth + 1);
          if (found != null) return found;
        }
      }
      return null;
    }

    return walk(data, 0);
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value.cast());
    return const <String, dynamic>{};
  }
}
