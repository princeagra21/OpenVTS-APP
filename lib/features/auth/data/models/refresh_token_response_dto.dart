import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/core/auth/auth_token_parser.dart';

class RefreshTokenResponseDto {
  const RefreshTokenResponseDto({
    required this.accessToken,
    this.refreshToken,
    this.raw,
  });

  final String accessToken;
  final String? refreshToken;
  final Object? raw;

  factory RefreshTokenResponseDto.fromRaw(Object? raw) {
    final payload = ApiResponseNormalizer.payloadOf(raw) ?? raw;
    final payloadMap = ApiResponseNormalizer.mapPayloadOf(payload);

    final accessToken = AuthTokenParser.extractAccessToken(raw) ??
        AuthTokenParser.extractAccessToken(payload) ??
        _text(payloadMap['accessToken'] ?? payloadMap['access_token'] ?? payloadMap['token']);

    final refreshToken = AuthTokenParser.extractRefreshToken(raw) ??
        AuthTokenParser.extractRefreshToken(payload) ??
        _text(payloadMap['refreshToken'] ?? payloadMap['refresh_token']);

    if (accessToken == null || accessToken.trim().isEmpty) {
      throw const FormatException('Refresh response did not contain an access token.');
    }

    return RefreshTokenResponseDto(
      accessToken: accessToken.trim(),
      refreshToken: refreshToken?.trim(),
      raw: raw,
    );
  }

  static String? _text(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
