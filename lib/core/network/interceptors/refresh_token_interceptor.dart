import 'dart:async';

import 'package:dio/dio.dart';
import 'package:open_vts/core/auth/session_expired_bus.dart';
import 'package:open_vts/core/network/api_paths.dart';
import 'package:open_vts/core/storage/token_storage.dart';

class RefreshTokenInterceptor extends Interceptor {
  final TokenStorageBase tokenStorage;
  final Dio dio;

  RefreshTokenInterceptor({
    required this.tokenStorage,
    required this.dio,
  });

  Completer<void>? _refreshCompleter;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && _shouldRetry(err.requestOptions)) {
      try {
        final newToken = await _refreshToken();
        if (newToken != null) {
          // Retry the request with new token
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newToken';
          final response = await dio.fetch(options);
          handler.resolve(response);
          return;
        } else {
          // No refresh token, logout
          await _logout();
        }
      } catch (_) {
        // Refresh failed, logout
        await _logout();
      }
    } else if (err.response?.statusCode == 401) {
      // Shouldn't retry, logout
      await _logout();
    }

    // For 403 or other errors, just pass through
    handler.next(err);
  }

  bool _shouldRetry(RequestOptions options) {
    final path = options.path.toLowerCase();
    // Do not refresh for auth endpoints
    if (path == AuthApiPaths.login ||
        path == AuthApiPaths.forgotPassword ||
        path == AuthApiPaths.refreshToken) {
      return false;
    }
    return true;
  }

  Future<String?> _refreshToken() async {
    // Single-flight: if already refreshing, wait
    if (_refreshCompleter != null) {
      await _refreshCompleter!.future;
      // After wait, read the new token
      return await tokenStorage.readAccessToken();
    }

    _refreshCompleter = Completer<void>();

    try {
      final refreshToken = await tokenStorage.readRefreshToken();
      if (refreshToken == null || refreshToken.trim().isEmpty) {
        return null;
      }

      final response = await dio.post(
        AuthApiPaths.refreshToken,
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: {'Authorization': null}, // No auth for refresh
        ),
      );

      final data = response.data;
      final newAccessToken = data['access_token'] as String?;
      final newRefreshToken = data['refresh_token'] as String?;

      if (newAccessToken != null && newAccessToken.trim().isNotEmpty) {
        await tokenStorage.writeAccessToken(newAccessToken);
        if (newRefreshToken != null && newRefreshToken.trim().isNotEmpty) {
          await tokenStorage.writeRefreshToken(newRefreshToken);
        }
        _refreshCompleter!.complete();
        return newAccessToken;
      } else {
        throw Exception('Invalid refresh response');
      }
    } catch (e) {
      _refreshCompleter!.completeError(e);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<void> _logout() async {
    await tokenStorage.clear();
    SessionExpiredBus.emit();
  }
}