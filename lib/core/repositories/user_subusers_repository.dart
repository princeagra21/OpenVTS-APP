import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/user_subuser_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';

class UserSubUsersRepository {
  final ApiClient api;

  const UserSubUsersRepository({required this.api});

  Future<Result<List<UserSubUserItem>>> getSubUsers({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get('/user/subusers', cancelToken: cancelToken);

    return res.when(
      success: (data) {
        final map = _extractMap(data);
        final items = _extractList(map['items'] ?? map['data']);
        final out = <UserSubUserItem>[];
        for (final item in items) {
          if (item is Map<String, dynamic>) {
            out.add(UserSubUserItem(item));
          } else if (item is Map) {
            out.add(UserSubUserItem(Map<String, dynamic>.from(item.cast())));
          }
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<UserSubUserItem>> createSubUser(
    Map<String, dynamic> payload, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.post(
      '/user/subusers',
      data: payload,
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) => Result.ok(UserSubUserItem(_extractMap(data))),
      failure: (err) => Result.fail(err),
    );
  }

  Map<String, dynamic> _extractMap(Object? data) {
    Map<String, dynamic>? walk(Object? node, int depth) {
      if (depth > 6 || node is! Map) return null;
      final map = node is Map<String, dynamic>
          ? node
          : Map<String, dynamic>.from(node.cast());

      for (final key in const ['data', 'result', 'items']) {
        final value = map[key];
        if (value is Map<String, dynamic>) return value;
        if (value is Map) return Map<String, dynamic>.from(value.cast());
      }

      for (final value in map.values) {
        if (value is Map) {
          final found = walk(value, depth + 1);
          if (found != null) return found;
        }
      }
      return map;
    }

    return walk(data, 0) ?? const <String, dynamic>{};
  }

  List _extractList(Object? data) {
    if (data is List) return data;
    return const [];
  }
}
