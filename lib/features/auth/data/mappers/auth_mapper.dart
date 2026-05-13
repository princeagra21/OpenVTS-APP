import 'dart:convert';

import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/auth/data/models/login_response_dto.dart';
import 'package:open_vts/features/auth/data/models/session_dto.dart';
import 'package:open_vts/features/auth/domain/entities/auth_user.dart';
import 'package:open_vts/features/auth/domain/entities/login_response.dart';
import 'package:open_vts/features/auth/domain/entities/user_role.dart';

class AuthMapper {
  const AuthMapper();

  Result<LoginResponseDto, AppError> loginDtoFromRaw(Object? raw) {
    final logicalFailure = _logicalFailure(raw);
    if (logicalFailure != null) return Result.failure(AuthError(logicalFailure, details: raw));

    try {
      return Result.success(LoginResponseDto.fromRaw(raw));
    } on FormatException catch (error) {
      return Result.failure(AuthError(error.message, details: raw));
    } catch (error) {
      return Result.failure(UnknownError('Unable to parse login response.', details: error));
    }
  }

  Result<LoginResponse, AppError> loginResponseFromDto(LoginResponseDto dto) {
    final session = SessionDto(
      accessToken: dto.accessToken,
      refreshToken: dto.refreshToken,
      role: dto.role,
      user: dto.user,
    );
    final userResult = userFromSession(session);
    return userResult.when(
      success: (user) => Result.success(LoginResponse(user: user)),
      failure: (error) => Result.failure(error),
    );
  }

  Result<AuthUser, AppError> userFromSession(SessionDto session) {
    final tokenPayload = _decodeJwtPayload(session.accessToken);
    final userMap = <String, Object?>{
      ...tokenPayload,
      ...session.user,
    };

    final role = _resolveRole(session.role, userMap, tokenPayload);
    if (!_isSupportedRole(role)) {
      return const Result.failure(
        PermissionAppError('This account role is not supported in this app.'),
      );
    }

    return Result.success(
      AuthUser(
        id: _firstText(userMap, const <String>['id', 'userId', 'user_id', '_id', 'uuid', 'sub']),
        name: _firstText(userMap, const <String>['name', 'fullName', 'full_name', 'username', 'displayName']),
        email: _firstText(userMap, const <String>['email', 'emailAddress', 'email_address']),
        role: role,
        raw: <String, dynamic>{
          for (final entry in userMap.entries) entry.key: entry.value,
        },
      ),
    );
  }

  SessionDto sessionFromToken(String accessToken, {String? refreshToken}) {
    final payload = _decodeJwtPayload(accessToken);
    return SessionDto(
      accessToken: accessToken,
      refreshToken: refreshToken,
      role: _roleTextFromMap(payload),
      user: payload,
    );
  }

  String forgotPasswordMessage(Object? raw) {
    final message = ApiResponseNormalizer.message(raw).trim();
    if (message.isNotEmpty) return message;
    return 'If an account with that identifier exists, a password reset link has been sent.';
  }

  String? _logicalFailure(Object? raw) {
    final action = ApiResponseNormalizer.action(raw, defaultValue: true);
    if (!action) {
      final message = ApiResponseNormalizer.message(raw).trim();
      return message.isNotEmpty ? message : 'Invalid credentials.';
    }

    final status = ApiResponseNormalizer.status(raw).trim().toLowerCase();
    if (const <String>{'fail', 'failed', 'error', 'unauthorized'}.contains(status)) {
      final message = ApiResponseNormalizer.message(raw).trim();
      return message.isNotEmpty ? message : 'Login failed.';
    }

    return null;
  }

  UserRole _resolveRole(
    String? explicitRole,
    Map<String, Object?> userMap,
    Map<String, Object?> tokenPayload,
  ) {
    final role = explicitRole ?? _roleTextFromMap(userMap) ?? _roleTextFromMap(tokenPayload);
    return UserRole.fromBackend(role);
  }

  bool _isSupportedRole(UserRole role) => role != UserRole.unknown;

  static String _firstText(Map<String, Object?> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  static String? _roleTextFromMap(Map<String, Object?> map) {
    for (final key in const <String>[
      'role',
      'userRole',
      'user_role',
      'userType',
      'user_type',
      'roleType',
      'type',
    ]) {
      final role = _roleText(map[key]);
      if (role != null) return role;
    }

    for (final key in const <String>['data', 'user', 'account', 'profile']) {
      final nested = map[key];
      if (nested is Map) {
        final role = _roleTextFromMap(ApiResponseNormalizer.mapOf(nested));
        if (role != null) return role;
      }
    }
    return null;
  }

  static String? _roleText(Object? value) {
    if (value == null) return null;
    if (value is String) {
      final text = value.trim();
      return text.isEmpty ? null : text;
    }
    if (value is List) {
      for (final item in value) {
        final role = _roleText(item);
        if (role != null) return role;
      }
    }
    if (value is Map) {
      final map = ApiResponseNormalizer.mapOf(value);
      return _roleText(
        map['name'] ?? map['role'] ?? map['type'] ?? map['slug'] ?? map['code'],
      );
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static Map<String, Object?> _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return const <String, Object?>{};

    try {
      final decoded = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final payload = jsonDecode(decoded);
      if (payload is Map<String, dynamic>) return payload;
      if (payload is Map) return ApiResponseNormalizer.mapOf(payload);
    } catch (_) {
      return const <String, Object?>{};
    }
    return const <String, Object?>{};
  }
}
