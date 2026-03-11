import 'package:dio/dio.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/network/result.dart';

class PushWebConfigPayload {
  final Map<String, dynamic> webConfig;
  final String vapidKey;

  const PushWebConfigPayload({required this.webConfig, required this.vapidKey});
}

class PushTokenRepository {
  final ApiClient api;

  const PushTokenRepository({required this.api});

  Future<Result<PushWebConfigPayload>> getWebConfig({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get('/auth/fcm-web-config', cancelToken: cancelToken);
    return res.when(
      success: (data) {
        final map = _extractMap(data);
        final webConfig = _asMap(map['webConfig']);
        final vapidKey = (map['webVapidKey'] ?? '').toString().trim();
        if (webConfig.isEmpty || vapidKey.isEmpty) {
          return Result.fail(
            const ApiException(
              message: 'FCM web config was returned without config data.',
            ),
          );
        }
        return Result.ok(
          PushWebConfigPayload(webConfig: webConfig, vapidKey: vapidKey),
        );
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> registerToken({
    required String token,
    required String platform,
    required String deviceId,
    String? userAgent,
    CancelToken? cancelToken,
  }) async {
    final res = await api.post(
      '/auth/push-token',
      cancelToken: cancelToken,
      data: <String, dynamic>{
        'token': token,
        'platform': platform,
        'deviceId': deviceId,
        if ((userAgent ?? '').trim().isNotEmpty) 'userAgent': userAgent!.trim(),
      },
    );
    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<void>> unregisterToken({
    required String token,
    CancelToken? cancelToken,
  }) async {
    final res = await api.delete(
      '/auth/push-token',
      cancelToken: cancelToken,
      data: <String, dynamic>{'token': token},
    );
    return res.when(
      success: (_) => Result.ok(null),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<List<Map<String, dynamic>>>> getMyTokens({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get('/auth/push-tokens/me', cancelToken: cancelToken);
    return res.when(
      success: (data) {
        final list = _extractList(data);
        final out = <Map<String, dynamic>>[];
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            out.add(item);
          } else if (item is Map) {
            out.add(Map<String, dynamic>.from(item.cast()));
          }
        }
        return Result.ok(out);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Map<String, dynamic> _extractMap(Object? value) {
    Map<String, dynamic> walk(Object? node, int depth) {
      if (depth > 6) return const <String, dynamic>{};
      if (node is Map<String, dynamic>) {
        if (node.containsKey('webConfig') || node.containsKey('webVapidKey')) {
          return node;
        }
        for (final key in const ['data', 'result', 'item', 'payload']) {
          final nested = node[key];
          if (nested is Map || nested is Map<String, dynamic>) {
            final found = walk(nested, depth + 1);
            if (found.isNotEmpty) return found;
          }
        }
        return node;
      }
      if (node is Map) {
        return walk(Map<String, dynamic>.from(node.cast()), depth + 1);
      }
      return const <String, dynamic>{};
    }

    return walk(value, 0);
  }

  List _extractList(Object? value) {
    List walk(Object? node, int depth) {
      if (depth > 6) return const [];
      if (node is List) return node;
      if (node is Map<String, dynamic>) {
        for (final key in const ['data', 'items', 'result', 'rows']) {
          final nested = node[key];
          if (nested is List) return nested;
          if (nested is Map || nested is Map<String, dynamic>) {
            final found = walk(nested, depth + 1);
            if (found.isNotEmpty) return found;
          }
        }
      } else if (node is Map) {
        return walk(Map<String, dynamic>.from(node.cast()), depth + 1);
      }
      return const [];
    }

    return walk(value, 0);
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value.cast());
    return const <String, dynamic>{};
  }
}
