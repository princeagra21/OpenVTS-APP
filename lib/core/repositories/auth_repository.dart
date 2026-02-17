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
    final res = await api.post(
      '/auth/login',
      data: {'identifier': identifier, 'password': password},
      cancelToken: cancelToken,
    );

    return res.when(
      success: (data) async {
        final token = extractToken(data);
        if (token == null || token.trim().isEmpty) {
          return Result.fail(
            ApiException(
              message: 'Login succeeded but token was not found in response',
              details: data,
            ),
          );
        }
        await tokenStorage.writeAccessToken(token);
        return Result.ok(token);
      },
      failure: (err) => Result.fail(err),
    );
  }

  static String? extractToken(Object? data) {
    if (data is Map) {
      final direct =
          data['token'] ?? data['accessToken'] ?? data['access_token'];
      if (direct is String) return direct;

      final d = data['data'];
      if (d is Map) {
        final nested = d['token'] ?? d['accessToken'] ?? d['access_token'];
        if (nested is String) return nested;
      }
    }
    return null;
  }
}
