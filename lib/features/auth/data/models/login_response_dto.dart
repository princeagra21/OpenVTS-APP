import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/core/auth/auth_token_parser.dart';

class LoginResponseDto {
  const LoginResponseDto({
    required this.accessToken,
    this.refreshToken,
    this.role,
    this.user = const <String, Object?>{},
    this.raw,
  });

  final String accessToken;
  final String? refreshToken;
  final String? role;
  final Map<String, Object?> user;
  final Object? raw;

  factory LoginResponseDto.fromRaw(Object? raw) {
    final payload = ApiResponseNormalizer.payloadOf(raw) ?? raw;
    final payloadMap = ApiResponseNormalizer.mapPayloadOf(payload);
    final rootMap = ApiResponseNormalizer.mapOf(raw);

    final accessToken = AuthTokenParser.extractAccessToken(raw) ??
        AuthTokenParser.extractAccessToken(payload) ??
        _text(payloadMap['accessToken'] ?? payloadMap['access_token'] ?? payloadMap['token']);

    final refreshToken = AuthTokenParser.extractRefreshToken(raw) ??
        AuthTokenParser.extractRefreshToken(payload) ??
        _text(payloadMap['refreshToken'] ?? payloadMap['refresh_token']);

    final user = _extractUserMap(payloadMap, rootMap);
    final role = _extractRole(payloadMap) ?? _extractRole(user) ?? _extractRole(rootMap);

    if (accessToken == null || accessToken.trim().isEmpty) {
      throw const FormatException('Login response did not contain an access token.');
    }

    return LoginResponseDto(
      accessToken: accessToken.trim(),
      refreshToken: refreshToken?.trim(),
      role: role?.trim(),
      user: user,
      raw: raw,
    );
  }

  static Map<String, Object?> _extractUserMap(
    Map<String, Object?> payloadMap,
    Map<String, Object?> rootMap,
  ) {
    for (final candidate in <Object?>[
      payloadMap['user'],
      payloadMap['account'],
      payloadMap['profile'],
      rootMap['user'],
      rootMap['account'],
      rootMap['profile'],
    ]) {
      final map = ApiResponseNormalizer.mapOf(candidate);
      if (map.isNotEmpty) return map;
    }

    return payloadMap;
  }

  static String? _extractRole(Map<String, Object?> map) {
    for (final key in const <String>[
      'role',
      'userRole',
      'user_role',
      'userType',
      'user_type',
      'roleType',
      'type',
    ]) {
      final value = _roleText(map[key]);
      if (value != null) return value;
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
        final text = _roleText(item);
        if (text != null) return text;
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

  static String? _text(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
