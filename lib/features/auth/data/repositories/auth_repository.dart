import 'dart:convert';

import 'package:open_vts/core/utils/request_control.dart';
import 'package:open_vts/core/auth/auth_token_parser.dart';
import 'package:open_vts/core/api/api_envelope.dart';
import 'package:open_vts/core/api/api_exception.dart';
import 'package:open_vts/core/api/api_paths.dart';
import 'package:open_vts/core/api/api_result.dart';
import 'package:open_vts/core/storage/token_storage.dart';
import 'package:open_vts/core/api/legacy_api_transport.dart';

/// Infrastructure is injected by AppContainer.
/// Do not instantiate transport client, AppConfig, or TokenStorage inside this repository.
class AuthRepository {
  final LegacyApiTransport api;
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
      AuthApiPaths.login,
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
        final refreshToken = extractRefreshToken(data);
        await tokenStorage.writeAccessToken(token);
        if (refreshToken != null) {
          await tokenStorage.writeRefreshToken(refreshToken);
        }
        return Result.ok(
          AuthLoginContext(token: token, role: role, response: data),
        );
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<String> forgotPassword(
    String identifier, {
    CancelToken? cancelToken,
  }) async {
    final res = await api.post(
      AuthApiPaths.forgotPassword,
      data: {'identifier': identifier.trim()},
      cancelToken: cancelToken,
    );

    if (res.isFailure) {
      throw (res.error ??
          const ApiException(
            message: 'Unable to send reset link. Please try again.',
          ));
    }

    final data = res.data;
    final message = _extractForgotPasswordMessage(data);
    return message ??
        'If an account with that identifier exists, a password reset link has been sent.';
  }

  static String? _extractLogicalLoginFailureMessage(Object? data) {
    final root = ApiEnvelope.asMap(data);
    if (root.isEmpty) return null;

    final nested = ApiEnvelope.nestedMap(root);

    final actionValue = nested['action'] ?? root['action'];
    final action = ApiEnvelope.boolValue(actionValue);
    if (action == false) {
      return ApiEnvelope.firstNonEmpty([
        _extractMessageFromMap(nested),
        _extractMessageFromMap(root),
        'Invalid credentials.',
      ]);
    }

    final successValue =
        nested['success'] ?? root['success'] ?? nested['ok'] ?? root['ok'];
    final success = ApiEnvelope.boolValue(successValue);
    if (success == false) {
      return ApiEnvelope.firstNonEmpty([
        _extractMessageFromMap(nested),
        _extractMessageFromMap(root),
        'Login failed.',
      ]);
    }

    final statusRaw = (nested['status'] ?? root['status'])?.toString().trim();
    if (statusRaw != null && statusRaw.isNotEmpty) {
      final normalized = statusRaw.toLowerCase();
      if (const {
        'fail',
        'failed',
        'error',
        'unauthorized',
      }.contains(normalized)) {
        return ApiEnvelope.firstNonEmpty([
          _extractMessageFromMap(nested),
          _extractMessageFromMap(root),
          'Login failed.',
        ]);
      }
    }

    return null;
  }

  static String? _extractMessageFromMap(Map? map) {
    if (map == null) return null;
    final message = ApiEnvelope.message(ApiEnvelope.asMap(map));
    if (message == null || message.trim().isEmpty) return null;
    return message.trim();
  }

  static String? _extractForgotPasswordMessage(Object? data) {
    final message = ApiEnvelope.message(data);
    if (message == null || message.trim().isEmpty) return null;
    return message.trim();
  }

  static String? extractToken(Object? data) {
    return AuthTokenParser.extractAccessToken(data);
  }

  static String? extractRefreshToken(Object? data) {
    return AuthTokenParser.extractRefreshToken(data);
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
