import 'dart:async';

import 'package:open_vts/core/utils/request_control.dart';
import 'package:open_vts/core/auth/auth_token_parser.dart';
import 'package:open_vts/core/auth/session_expired_bus.dart';
import 'package:open_vts/core/api/api_paths.dart';
import 'package:open_vts/core/storage/token_storage.dart';

class RefreshTokenInterceptor extends Interceptor {
  static const String retriedAfterRefreshKey = 'retriedAfterRefresh';
  static const String skipAuthRefreshKey = 'skipAuthRefresh';

  final TokenStorageBase tokenStorage;
  final Dio dio;

  RefreshTokenInterceptor({required this.tokenStorage, required this.dio});

  Future<String>? _refreshFuture;
  bool _refreshEndpointUnavailable = false;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    final options = err.requestOptions;
    if (_refreshEndpointUnavailable || _shouldSkipRefresh(options)) {
      handler.next(err);
      return;
    }

    if (_wasRetriedAfterRefresh(options)) {
      await _expireSession();
      handler.next(err);
      return;
    }

    try {
      final newToken = await _refreshToken();
      final response = await _retryWithNewToken(options, newToken);
      handler.resolve(response);
      return;
    } on DioException catch (retryErr) {
      if (_wasRetriedAfterRefresh(retryErr.requestOptions)) {
        handler.next(retryErr);
        return;
      }
      await _expireSession();
    } catch (_) {
      await _expireSession();
    }

    handler.next(err);
  }

  bool _shouldSkipRefresh(RequestOptions options) {
    if (options.extra[skipAuthRefreshKey] == true) return true;

    final path = _normalizedPath(options.path);
    return path == AuthApiPaths.login ||
        path == AuthApiPaths.forgotPassword ||
        path == AuthApiPaths.refreshToken;
  }

  bool _wasRetriedAfterRefresh(RequestOptions options) {
    return options.extra[retriedAfterRefreshKey] == true;
  }

  Future<String> _refreshToken() {
    final inFlight = _refreshFuture;
    if (inFlight != null) return inFlight;

    late final Future<String> refresh;
    refresh = _performRefresh().whenComplete(() {
      if (identical(_refreshFuture, refresh)) {
        _refreshFuture = null;
      }
    });
    _refreshFuture = refresh;
    return refresh;
  }

  Future<String> _performRefresh() async {
    final refreshToken = (await tokenStorage.readRefreshToken())?.trim();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const _RefreshTokenUnavailable();
    }

    late final Response<dynamic> response;
    try {
      response = await dio.post<dynamic>(
        AuthApiPaths.refreshToken,
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: const <String, dynamic>{
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          extra: const <String, dynamic>{skipAuthRefreshKey: true},
        ),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        _refreshEndpointUnavailable = true;
      }
      rethrow;
    }

    final newAccessToken = AuthTokenParser.extractAccessToken(response.data);
    if (newAccessToken == null || newAccessToken.trim().isEmpty) {
      throw const FormatException('Refresh response did not contain a token');
    }

    final normalizedAccessToken = newAccessToken.trim();
    await tokenStorage.writeAccessToken(normalizedAccessToken);

    final newRefreshToken = AuthTokenParser.extractRefreshToken(response.data);
    if (newRefreshToken != null && newRefreshToken.trim().isNotEmpty) {
      await tokenStorage.writeRefreshToken(newRefreshToken.trim());
    }

    return normalizedAccessToken;
  }

  Future<Response<dynamic>> _retryWithNewToken(
    RequestOptions options,
    String accessToken,
  ) {
    options.extra[retriedAfterRefreshKey] = true;
    options.headers['Authorization'] = 'Bearer $accessToken';
    return dio.fetch<dynamic>(options);
  }

  String _normalizedPath(String path) {
    final parsed = Uri.tryParse(path);
    final value = parsed?.hasScheme == true ? parsed!.path : path;
    final withoutQuery = value.split('?').first.trim().toLowerCase();
    if (withoutQuery.isEmpty) return '/';
    return withoutQuery.startsWith('/') ? withoutQuery : '/$withoutQuery';
  }

  Future<void> _expireSession() async {
    await tokenStorage.clear();
    SessionExpiredBus.emit();
  }
}

class _RefreshTokenUnavailable implements Exception {
  const _RefreshTokenUnavailable();
}
