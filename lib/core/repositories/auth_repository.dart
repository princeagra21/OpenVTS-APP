import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/network/result.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';

class AuthRepository {
  final ApiClient api;
  final TokenStorageBase tokenStorage;

  AuthRepository({required this.api, required this.tokenStorage});

  Future<Result<String>> login({
    required String identifier,
    required String password,
    CancelToken? cancelToken,
  }) async {
    final loginRes = await loginWithContext(
      identifier: identifier,
      password: password,
      cancelToken: cancelToken,
    );

    return loginRes.when(
      success: (ctx) => Result.ok(ctx.token),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<AuthLoginContext>> loginWithContext({
    required String identifier,
    required String password,
    CancelToken? cancelToken,
  }) async {
    final res = await api.post(
      '/auth/login',
      data: {'identifier': identifier, 'password': password},
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) async {
        final logicalFailureMessage = _extractLogicalLoginFailureMessage(data);
        if (logicalFailureMessage != null) {
          return Result.fail(
            ApiException(
              statusCode: 401,
              message: logicalFailureMessage,
              details: data,
            ),
          );
        }

        final token = extractToken(data);
        if (token == null || token.trim().isEmpty) {
          final fallbackMessage = data is Map
              ? _extractMessageFromMap(data)
              : null;
          return Result.fail(
            ApiException(
              statusCode: 401,
              message:
                  fallbackMessage ??
                  'Login succeeded but token was not found in response',
              details: data,
            ),
          );
        }

        final role = extractRole(data, token: token);
        await tokenStorage.writeAccessToken(token);
        return Result.ok(
          AuthLoginContext(token: token, role: role, response: data),
        );
      },
      failure: (err) => Result.fail(err),
    );
  }

  static String? _extractLogicalLoginFailureMessage(Object? data) {
    if (data is! Map) return null;

    final nestedData = data['data'];
    final nested = nestedData is Map ? nestedData : null;

    final actionValue = nested?['action'] ?? data['action'];
    final action = _coerceBool(actionValue);
    if (action == false) {
      return _firstNonEmpty([
        _extractMessageFromMap(nested),
        _extractMessageFromMap(data),
        'Invalid credentials.',
      ]);
    }

    final successValue =
        nested?['success'] ?? data['success'] ?? nested?['ok'] ?? data['ok'];
    final success = _coerceBool(successValue);
    if (success == false) {
      return _firstNonEmpty([
        _extractMessageFromMap(nested),
        _extractMessageFromMap(data),
        'Login failed.',
      ]);
    }

    final statusRaw = (nested?['status'] ?? data['status'])?.toString().trim();
    if (statusRaw != null && statusRaw.isNotEmpty) {
      final normalized = statusRaw.toLowerCase();
      if (const {
        'fail',
        'failed',
        'error',
        'unauthorized',
      }.contains(normalized)) {
        return _firstNonEmpty([
          _extractMessageFromMap(nested),
          _extractMessageFromMap(data),
          'Login failed.',
        ]);
      }
    }

    return null;
  }

  static String? _extractMessageFromMap(Map? map) {
    if (map == null) return null;

    final candidates = [
      map['message'],
      map['error'],
      map['msg'],
      map['detail'],
      map['reason'],
      (map['data'] is Map) ? (map['data'] as Map)['message'] : null,
    ];

    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }

    return null;
  }

  static String? _firstNonEmpty(List<String?> candidates) {
    for (final candidate in candidates) {
      final value = candidate?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static bool? _coerceBool(Object? value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = value.toString().trim().toLowerCase();
    if (text.isEmpty) return null;
    if (const {'true', '1', 'yes', 'y'}.contains(text)) return true;
    if (const {'false', '0', 'no', 'n'}.contains(text)) return false;
    return null;
  }

  static String? extractToken(Object? data) {
    if (data is Map) {
      return _extractTokenFromMap(data);
    }
    return null;
  }

  static String? _extractTokenFromMap(Map map) {
    String? asToken(Object? v) {
      if (v is String && v.trim().isNotEmpty) return v;
      return null;
    }

    final direct = asToken(
      map['token'] ?? map['accessToken'] ?? map['access_token'],
    );
    if (direct != null) return direct;

    for (final key in const ['data', 'result', 'item', 'payload', 'response']) {
      final nested = map[key];
      if (nested is Map) {
        final token = _extractTokenFromMap(nested);
        if (token != null) return token;
      } else if (nested is List) {
        for (final item in nested) {
          if (item is Map) {
            final token = _extractTokenFromMap(item);
            if (token != null) return token;
          }
        }
      }
    }

    return null;
  }

  static String? extractRole(Object? data, {String? token}) {
    String? pickFromMap(Map map) {
      final direct = [
        map['role'],
        map['userRole'],
        map['userType'],
        map['roleType'],
        map['type'],
      ];
      for (final v in direct) {
        final s = _coerceRoleString(v);
        if (s != null) return s;
      }

      final nestedData = map['data'];
      if (nestedData is Map) {
        final nested = pickFromMap(nestedData);
        if (nested != null) return nested;
      }

      final user = map['user'];
      if (user is Map) {
        final nested = pickFromMap(user);
        if (nested != null) return nested;
      }

      final account = map['account'];
      if (account is Map) {
        final nested = pickFromMap(account);
        if (nested != null) return nested;
      }

      return null;
    }

    if (data is Map) {
      final fromBody = pickFromMap(data);
      if (fromBody != null) return fromBody;
    }

    final t = token?.trim();
    if (t != null && t.isNotEmpty) {
      final payload = _decodeJwtPayload(t);
      if (payload != null) {
        final fromJwt = pickFromMap(payload);
        if (fromJwt != null) return fromJwt;
      }
    }

    return null;
  }

  static String? _coerceRoleString(Object? value) {
    if (value == null) return null;
    if (value is String) {
      final s = value.trim();
      return s.isEmpty ? null : s;
    }

    if (value is List) {
      for (final item in value) {
        final s = _coerceRoleString(item);
        if (s != null) return s;
      }
    }

    if (value is Map) {
      final s = _coerceRoleString(
        value['name'] ??
            value['role'] ??
            value['type'] ??
            value['slug'] ??
            value['code'],
      );
      if (s != null) return s;
    }

    final asString = value.toString().trim();
    return asString.isEmpty ? null : asString;
  }

  static Map<String, dynamic>? _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      final decoded = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final payload = jsonDecode(decoded);
      if (payload is Map<String, dynamic>) return payload;
      if (payload is Map) return Map<String, dynamic>.from(payload.cast());
    } catch (_) {
      return null;
    }
    return null;
  }
}

class AuthLoginContext {
  final String token;
  final String? role;
  final Object? response;

  const AuthLoginContext({
    required this.token,
    required this.role,
    this.response,
  });
}
