import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:open_vts/core/network/api_paths.dart';
import 'package:open_vts/core/network/interceptors/refresh_token_interceptor.dart';
import 'package:open_vts/core/storage/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTokenStorage implements TokenStorageBase {
  String? accessToken;
  String? refreshToken;
  bool cleared = false;
  int clearCount = 0;

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
    clearCount += 1;
    accessToken = null;
    refreshToken = null;
  }
}

class TestAdapter implements HttpClientAdapter {
  List<RequestOptions> requests = [];
  late FutureOr<ResponseBody> Function(RequestOptions options) handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  int count(String path) {
    return requests.where((request) => request.path == path).length;
  }

  RequestOptions requestFor(String path) {
    return requests.firstWhere((request) => request.path == path);
  }
}

ResponseBody jsonResponse(Object? data, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(data ?? <String, dynamic>{}),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  late Dio dio;
  late FakeTokenStorage tokenStorage;
  late RefreshTokenInterceptor interceptor;
  late TestAdapter adapter;

  setUp(() {
    tokenStorage = FakeTokenStorage();
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.example.test',
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );
    adapter = TestAdapter();
    dio.httpClientAdapter = adapter;
    interceptor = RefreshTokenInterceptor(tokenStorage: tokenStorage, dio: dio);
    dio.interceptors.add(interceptor);
  });

  Future<Response<dynamic>> requestThatRefreshesWith(Object? refreshData) {
    tokenStorage.accessToken = 'old_token';
    tokenStorage.refreshToken = 'refresh_token';

    adapter.handler = (options) {
      if (options.path == AuthApiPaths.refreshToken) {
        return jsonResponse(refreshData);
      }
      if (options.extra[RefreshTokenInterceptor.retriedAfterRefreshKey] ==
          true) {
        return jsonResponse({'ok': true});
      }
      return jsonResponse({'message': 'Unauthorized'}, statusCode: 401);
    };

    return dio.get<dynamic>(
      '/user/profile',
      options: Options(headers: {'Authorization': 'Bearer old_token'}),
    );
  }

  test(
    'refresh response with direct token fields retries original request',
    () async {
      final response = await requestThatRefreshesWith({
        'access_token': 'new_token',
        'refresh_token': 'new_refresh',
      });

      expect(response.data, {'ok': true});
      expect(tokenStorage.accessToken, 'new_token');
      expect(tokenStorage.refreshToken, 'new_refresh');
      expect(adapter.count(AuthApiPaths.refreshToken), 1);
    },
  );

  test(
    'refresh response with nested data.token retries original request',
    () async {
      final response = await requestThatRefreshesWith({
        'status': 'success',
        'data': {'token': 'nested_token', 'refresh_token': 'nested_refresh'},
      });

      expect(response.data, {'ok': true});
      expect(tokenStorage.accessToken, 'nested_token');
      expect(tokenStorage.refreshToken, 'nested_refresh');
    },
  );

  test(
    'refresh response with nested data.access_token retries original request',
    () async {
      final response = await requestThatRefreshesWith({
        'data': {
          'data': {
            'access_token': 'deep_token',
            'refresh_token': 'deep_refresh',
          },
        },
      });

      expect(response.data, {'ok': true});
      expect(tokenStorage.accessToken, 'deep_token');
      expect(tokenStorage.refreshToken, 'deep_refresh');
    },
  );

  test('401 without refresh token logs out', () async {
    tokenStorage.accessToken = 'old_token';
    tokenStorage.refreshToken = null;

    adapter.handler = (_) {
      return jsonResponse({'message': 'Unauthorized'}, statusCode: 401);
    };

    await expectLater(dio.get('/user/profile'), throwsA(isA<DioException>()));

    expect(tokenStorage.cleared, isTrue);
    expect(adapter.count(AuthApiPaths.refreshToken), 0);
  });

  test('401 with refresh token retries once using new token', () async {
    tokenStorage.accessToken = 'old_token';
    tokenStorage.refreshToken = 'refresh_token';

    adapter.handler = (options) {
      if (options.path == AuthApiPaths.refreshToken) {
        return jsonResponse({
          'access_token': 'new_token',
          'refresh_token': 'new_refresh',
        });
      }
      if (options.extra[RefreshTokenInterceptor.retriedAfterRefreshKey] ==
          true) {
        return jsonResponse({'user': 'data'});
      }
      return jsonResponse({'message': 'Unauthorized'}, statusCode: 401);
    };

    final response = await dio.get('/user/profile');

    expect(response.data, {'user': 'data'});
    expect(tokenStorage.accessToken, 'new_token');
    expect(tokenStorage.refreshToken, 'new_refresh');
    expect(adapter.count('/user/profile'), 2);
    expect(adapter.count(AuthApiPaths.refreshToken), 1);

    final refreshRequest = adapter.requestFor(AuthApiPaths.refreshToken);
    expect(refreshRequest.headers.containsKey('Authorization'), isFalse);

    final retryRequest = adapter.requests.last;
    expect(
      retryRequest.extra[RefreshTokenInterceptor.retriedAfterRefreshKey],
      isTrue,
    );
    expect(retryRequest.headers['Authorization'], 'Bearer new_token');
  });

  test('refresh failure logs out', () async {
    tokenStorage.accessToken = 'old_token';
    tokenStorage.refreshToken = 'refresh_token';

    adapter.handler = (options) {
      if (options.path == AuthApiPaths.refreshToken) {
        return jsonResponse({'message': 'Nope'}, statusCode: 400);
      }
      return jsonResponse({'message': 'Unauthorized'}, statusCode: 401);
    };

    await expectLater(dio.get('/user/profile'), throwsA(isA<DioException>()));

    expect(tokenStorage.cleared, isTrue);
  });

  test('second 401 after retry does not loop', () async {
    tokenStorage.accessToken = 'old_token';
    tokenStorage.refreshToken = 'refresh_token';

    adapter.handler = (options) {
      if (options.path == AuthApiPaths.refreshToken) {
        return jsonResponse({'access_token': 'new_token'});
      }
      return jsonResponse({'message': 'Unauthorized'}, statusCode: 401);
    };

    await expectLater(dio.get('/user/profile'), throwsA(isA<DioException>()));

    expect(adapter.count('/user/profile'), 2);
    expect(adapter.count(AuthApiPaths.refreshToken), 1);
    expect(tokenStorage.clearCount, 1);
  });

  test('403 does not logout', () async {
    tokenStorage.accessToken = 'token';

    adapter.handler = (_) {
      return jsonResponse({'message': 'Forbidden'}, statusCode: 403);
    };

    await expectLater(dio.get('/user/profile'), throwsA(isA<DioException>()));

    expect(tokenStorage.cleared, isFalse);
    expect(adapter.count(AuthApiPaths.refreshToken), 0);
  });

  test('parallel 401 only refreshes once', () async {
    tokenStorage.accessToken = 'old_token';
    tokenStorage.refreshToken = 'refresh_token';
    final refreshStarted = Completer<void>();
    final refreshCompleter = Completer<void>();
    final secondUnauthorizedSeen = Completer<void>();

    adapter.handler = (options) async {
      if (options.path == AuthApiPaths.refreshToken) {
        if (!refreshStarted.isCompleted) refreshStarted.complete();
        await refreshCompleter.future;
        return jsonResponse({'access_token': 'new_token'});
      }
      if (options.extra[RefreshTokenInterceptor.retriedAfterRefreshKey] ==
          true) {
        return jsonResponse({'path': options.path});
      }
      if (options.path == '/user/data' && !secondUnauthorizedSeen.isCompleted) {
        secondUnauthorizedSeen.complete();
      }
      return jsonResponse({'message': 'Unauthorized'}, statusCode: 401);
    };

    final future1 = dio.get('/user/profile');
    await refreshStarted.future;
    final future2 = dio.get('/user/data');
    await secondUnauthorizedSeen.future;
    refreshCompleter.complete();

    final results = await Future.wait([future1, future2]);

    expect(results[0].data, {'path': '/user/profile'});
    expect(results[1].data, {'path': '/user/data'});
    expect(adapter.count(AuthApiPaths.refreshToken), 1);
    expect(adapter.count('/user/profile'), 2);
    expect(adapter.count('/user/data'), 2);
    expect(tokenStorage.accessToken, 'new_token');
  });

  test('does not refresh for auth endpoints', () async {
    tokenStorage.accessToken = 'token';
    tokenStorage.refreshToken = 'refresh';

    adapter.handler = (_) {
      return jsonResponse({'message': 'Unauthorized'}, statusCode: 401);
    };

    await expectLater(
      dio.get(AuthApiPaths.login),
      throwsA(isA<DioException>()),
    );
    await expectLater(
      dio.get(AuthApiPaths.forgotPassword),
      throwsA(isA<DioException>()),
    );
    await expectLater(
      dio.get(AuthApiPaths.refreshToken),
      throwsA(isA<DioException>()),
    );

    expect(adapter.count(AuthApiPaths.refreshToken), 1);
    expect(tokenStorage.cleared, isFalse);
  });
}
