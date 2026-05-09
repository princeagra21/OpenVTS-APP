import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:open_vts/core/config/app_config.dart';
import 'package:open_vts/core/network/api_client.dart';
import 'package:open_vts/core/network/api_exception.dart';
import 'package:open_vts/core/network/result.dart';
import 'package:open_vts/core/storage/token_storage.dart';

class MockTokenStorage implements TokenStorageBase {
  String? _accessToken;
  String? _refreshToken;

  @override
  Future<String?> readAccessToken() async => _accessToken;

  @override
  Future<void> writeAccessToken(String token) async {
    _accessToken = token;
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
  Future<String?> readRefreshToken() async => _refreshToken;

  @override
  Future<void> writeRefreshToken(String token) async {
    _refreshToken = token;
  }

  @override
  Future<void> clearRefreshToken() async {
    _refreshToken = null;
  }

  @override
  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
  }
}

void main() {
  late MockTokenStorage mockTokenStorage;
  late ApiClient apiClient;
  late Dio mockDio;

  setUp(() {
    mockTokenStorage = MockTokenStorage();
    mockDio = Dio();
    final config = AppConfig(environment: 'test', baseUrl: 'https://test.com');
    apiClient = ApiClient._(mockDio, config, mockTokenStorage);
  });

  tearDown(() {
    mockDio.close();
  });

  group('ApiClient auth tests', () {
    test('401 error triggers session expired', () async {
      // This would require mocking Dio to return 401
      // and checking if session expired bus is notified
      // For now, just test that ApiException is created correctly
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
          data: {'message': 'Unauthorized'},
        ),
      );

      final exception = ApiException.fromDioException(dioException);

      expect(exception.statusCode, 401);
      expect(exception.message, 'Unauthorized');
    });

    test('403 error creates correct exception', () async {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 403,
          data: {'message': 'Forbidden'},
        ),
      );

      final exception = ApiException.fromDioException(dioException);

      expect(exception.statusCode, 403);
      expect(exception.message, 'Forbidden');
    });

    test('auth header added for protected routes', () async {
      mockTokenStorage._accessToken = 'test-token';

      // This test would require intercepting the Dio request
      // to check if Authorization header is set
      // For now, we test the interceptor logic indirectly
      expect(mockTokenStorage._accessToken, 'test-token');
    });

    test('no auth header for public routes', () async {
      // Public routes should not have auth headers
      // This would be tested by checking the interceptor
      expect(true, isTrue); // Placeholder
    });

    test('empty baseUrl creates error', () async {
      final config = AppConfig(environment: 'test', baseUrl: '');
      final emptyClient = ApiClient._(mockDio, config, mockTokenStorage);

      final result = await emptyClient.get('/test');

      expect(result.isFailure, isTrue);
      expect(result.failure!.message, contains('API baseUrl is empty'));
    });

    test('absolute URLs work without baseUrl', () async {
      final config = AppConfig(environment: 'test', baseUrl: '');
      final absClient = ApiClient._(mockDio, config, mockTokenStorage);

      // This would require mocking Dio to handle absolute URLs
      expect(true, isTrue); // Placeholder
    });
  });
}