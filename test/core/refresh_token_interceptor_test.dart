import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:open_vts/core/auth/session_expired_bus.dart';
import 'package:open_vts/core/network/interceptors/refresh_token_interceptor.dart';
import 'package:open_vts/core/storage/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTokenStorage implements TokenStorageBase {
  String? accessToken;
  String? refreshToken;
  bool cleared = false;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<void> writeAccessToken(String token) async {
    accessToken = token;
  }

  @override
  Future<String?> readImpersonatorToken() async => null;

  @override
  Future<void> writeImpersonatorToken(String token) async {}

  @override
  Future<String?> popImpersonatorToken() async => null;

  @override
  Future<void> clearImpersonatorToken() async {}

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> writeRefreshToken(String token) async {
    refreshToken = token;
  }

  @override
  Future<void> clearRefreshToken() async {}

  @override
  Future<void> clear() async {
    cleared = true;
    accessToken = null;
    refreshToken = null;
  }
}

class TestAdapter implements HttpClientAdapter {
  List<Response> responses = [];
  List<RequestOptions> requests = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (responses.isNotEmpty) {
      final response = responses.removeAt(0);
      if (response.statusCode! >= 400) {
        throw DioException(
          requestOptions: options,
          response: response,
        );
      }
      final jsonString = response.data != null ? jsonEncode(response.data) : '{}';
      return ResponseBody.fromString(
        jsonString,
        response.statusCode ?? 200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString('{}', 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }
}

void main() {
  late Dio dio;
  late FakeTokenStorage tokenStorage;
  late RefreshTokenInterceptor interceptor;
  late TestAdapter adapter;

  setUp(() {
    tokenStorage = FakeTokenStorage();
    dio = Dio();
    adapter = TestAdapter();
    dio.httpClientAdapter = adapter;
    interceptor = RefreshTokenInterceptor(tokenStorage: tokenStorage, dio: dio);
    dio.interceptors.add(interceptor);
  });

  test('401 without refresh token logs out', () async {
    tokenStorage.accessToken = 'old_token';
    tokenStorage.refreshToken = null;

    adapter.responses = [
      Response(statusCode: 401, requestOptions: RequestOptions(path: '/user/profile')),
    ];

    try {
      await dio.get('/user/profile');
      fail('Should have thrown');
    } catch (_) {}

    expect(tokenStorage.cleared, isTrue);
  });

  test('401 with valid refresh token retries original request once', () async {
    tokenStorage.accessToken = 'old_token';
    tokenStorage.refreshToken = 'refresh_token';

    adapter.responses = [
      Response(statusCode: 401, requestOptions: RequestOptions(path: '/user/profile')),
      Response(statusCode: 200, data: {'access_token': 'new_token', 'refresh_token': 'new_refresh'}, requestOptions: RequestOptions(path: '/auth/refresh')),
      Response(statusCode: 200, data: {'user': 'data'}, requestOptions: RequestOptions(path: '/user/profile')),
    ];

    final response = await dio.get('/user/profile');

    expect(response.data, {'user': 'data'});
    expect(tokenStorage.accessToken, 'new_token');
    expect(tokenStorage.refreshToken, 'new_refresh');
  });

  test('refresh failure logs out', () async {
    tokenStorage.accessToken = 'old_token';
    tokenStorage.refreshToken = 'refresh_token';

    adapter.responses = [
      Response(statusCode: 401, requestOptions: RequestOptions(path: '/user/profile')),
      Response(statusCode: 400, requestOptions: RequestOptions(path: '/auth/refresh')),
    ];

    try {
      await dio.get('/user/profile');
      fail('Should have thrown');
    } catch (_) {}

    expect(tokenStorage.cleared, isTrue);
  });

  test('403 does not logout', () async {
    tokenStorage.accessToken = 'token';

    adapter.responses = [
      Response(statusCode: 403, requestOptions: RequestOptions(path: '/user/profile')),
    ];

    try {
      await dio.get('/user/profile');
      fail('Should have thrown');
    } catch (_) {}

    expect(tokenStorage.cleared, isFalse);
  });

  test('parallel 401 triggers only one refresh request', () async {
    tokenStorage.accessToken = 'old_token';
    tokenStorage.refreshToken = 'refresh_token';

    adapter.responses = [
      Response(statusCode: 401, requestOptions: RequestOptions(path: '/user/profile')),
      Response(statusCode: 401, requestOptions: RequestOptions(path: '/user/data')),
      Response(statusCode: 200, data: {'access_token': 'new_token'}, requestOptions: RequestOptions(path: '/auth/refresh')),
      Response(statusCode: 200, data: {'profile': 'data'}, requestOptions: RequestOptions(path: '/user/profile')),
      Response(statusCode: 200, data: {'data': 'info'}, requestOptions: RequestOptions(path: '/user/data')),
    ];

    final future1 = dio.get('/user/profile');
    final future2 = dio.get('/user/data');

    final results = await Future.wait([future1, future2]);

    expect(results[0].data, {'profile': 'data'});
    expect(results[1].data, {'data': 'info'});
    expect(adapter.requests.length, 5); // 2 initial 401s + 1 refresh + 2 retries
  });

  test('does not refresh for auth endpoints', () async {
    tokenStorage.accessToken = 'token';
    tokenStorage.refreshToken = 'refresh';

    adapter.responses = [
      Response(statusCode: 401, requestOptions: RequestOptions(path: '/auth/login')),
    ];

    try {
      await dio.get('/auth/login');
      fail('Should have thrown');
    } catch (_) {}

    expect(tokenStorage.cleared, isTrue);
  });
}