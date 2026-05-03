import 'package:dio/dio.dart';
import 'package:fleet_stack/core/network/interceptors/auth_interceptor.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/capturing_adapter.dart';

class FakeTokenStorage implements TokenStorageBase {
  final String? token;

  FakeTokenStorage(this.token);

  @override
  Future<void> clear() async {}

  @override
  Future<String?> readAccessToken() async => token;

  @override
  Future<void> writeAccessToken(String token) async {}

  @override
  Future<String?> readImpersonatorToken() async => null;

  @override
  Future<void> writeImpersonatorToken(String token) async {}

  @override
  Future<String?> popImpersonatorToken() async => null;

  @override
  Future<void> clearImpersonatorToken() async {}
}

void main() {
  test('Public/role path classifiers', () {
    expect(AuthInterceptor.isPublicPath('/timezones'), isTrue);
    expect(AuthInterceptor.isPublicPath('/auth/login'), isTrue);
    expect(AuthInterceptor.isPublicPath('/health'), isTrue);
    expect(AuthInterceptor.isPublicPath('/user/profile'), isFalse);

    expect(AuthInterceptor.isRolePath('/user/profile'), isTrue);
    expect(AuthInterceptor.isRolePath('/admin/upload'), isTrue);
    expect(
      AuthInterceptor.isRolePath('/superadmin/dashboard/totalcounts'),
      isTrue,
    );
    expect(AuthInterceptor.isRolePath('/timezones'), isFalse);
  });

  test('Attaches token only for role endpoints', () async {
    final adapter = CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.httpClientAdapter = adapter;
    dio.interceptors.add(AuthInterceptor(tokenStorage: FakeTokenStorage('t1')));

    await dio.get('/timezones');
    expect(adapter.lastRequest?.headers['Authorization'], isNull);

    await dio.get('/user/profile');
    expect(adapter.lastRequest?.headers['Authorization'], 'Bearer t1');

    await dio.get('/admin/users');
    expect(adapter.lastRequest?.headers['Authorization'], 'Bearer t1');

    await dio.get('/superadmin/dashboard/totalcounts');
    expect(adapter.lastRequest?.headers['Authorization'], 'Bearer t1');
  });

  test(
    'Never attaches token for /auth/* or /health/* or common endpoints',
    () async {
      final adapter = CapturingAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(
        AuthInterceptor(tokenStorage: FakeTokenStorage('t1')),
      );

      await dio.get('/auth/login');
      expect(adapter.lastRequest?.headers['Authorization'], isNull);

      await dio.get('/health');
      expect(adapter.lastRequest?.headers['Authorization'], isNull);

      await dio.get('/countries');
      expect(adapter.lastRequest?.headers['Authorization'], isNull);

      await dio.get('/states/IN');
      expect(adapter.lastRequest?.headers['Authorization'], isNull);

      await dio.get('/cities/in/up');
      expect(adapter.lastRequest?.headers['Authorization'], isNull);

      await dio.get('/documenttypes/USER');
      expect(adapter.lastRequest?.headers['Authorization'], isNull);

      await dio.get('/branding', queryParameters: {'host': 'localhost'});
      expect(adapter.lastRequest?.headers['Authorization'], isNull);

      await dio.get('/policies/PRIVACY_POLICY');
      expect(adapter.lastRequest?.headers['Authorization'], isNull);

      await dio.get('/status');
      expect(adapter.lastRequest?.headers['Authorization'], isNull);

      await dio.get('/version');
      expect(adapter.lastRequest?.headers['Authorization'], isNull);
    },
  );

  test('Never attaches token to absolute URL with different host', () async {
    final adapter = CapturingAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
    dio.httpClientAdapter = adapter;
    dio.interceptors.add(AuthInterceptor(tokenStorage: FakeTokenStorage('t1')));

    await dio.get('https://agent.fleetstack.in/webhook/ftversion');
    expect(adapter.lastRequest?.headers['Authorization'], isNull);
  });
}
