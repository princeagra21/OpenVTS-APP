import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/admin_user_recipient.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/network/result.dart';

class AdminNotificationRepository {
  final ApiClient api;

  const AdminNotificationRepository({required this.api});

  Future<Result<List<AdminUserRecipient>>> searchRecipients({
    String query = '',
    CancelToken? cancelToken,
  }) async {
    final q = query.trim();
    final qp = <String, dynamic>{};
    if (q.isNotEmpty) qp['search'] = q;

    final res = await api.get(
      '/admin/users',
      queryParameters: qp.isEmpty ? null : qp,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) {
        final list = _extractList(
          data,
          extraKeys: const ['users', 'userslist'],
        );
        final out = <AdminUserRecipient>[];
        if (list != null) {
          for (final item in list) {
            if (item is Map<String, dynamic>) {
              out.add(AdminUserRecipient(item));
            } else if (item is Map) {
              out.add(
                AdminUserRecipient(Map<String, dynamic>.from(item.cast())),
              );
            }
          }
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> sendNotification({
    required String channel,
    required List<String> userIds,
    String? subject,
    required String message,
    CancelToken? cancelToken,
  }) async {
    return Result.fail(
      const ApiException(
        message:
            'Send notification API is not available in FleetStack-API-Reference.md for ADMIN.',
      ),
    );
  }

  List? _extractList(Object? data, {List<String> extraKeys = const []}) {
    if (data is List) return data;

    final keys = <String>['data', 'items', 'result', 'results', ...extraKeys];

    List? walk(Object? node, int depth) {
      if (depth > 5) return null;
      if (node is List) return node;
      if (node is! Map) return null;

      final map = _asMap(node);
      for (final key in keys) {
        final value = map[key];
        if (value is List) return value;
      }

      for (final value in map.values) {
        if (value is Map || value is List) {
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
