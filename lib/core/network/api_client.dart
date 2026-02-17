import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/network/interceptors/auth_interceptor.dart';
import 'package:fleet_stack/core/network/result.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';

class ApiClient {
  final Dio dio;
  final AppConfig _config;

  ApiClient._(this.dio, this._config);

  factory ApiClient({
    required AppConfig config,
    required TokenStorageBase tokenStorage,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );

    dio.interceptors.add(AuthInterceptor(tokenStorage: tokenStorage));
    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: false),
    );

    return ApiClient._(dio, config);
  }

  Future<Result<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    try {
      if (_config.baseUrl.trim().isEmpty && !_isAbsoluteUrl(path)) {
        return Result.fail(
          const ApiException(
            message:
                'API baseUrl is empty. Set --dart-define=API_BASE_URL=https://your-host',
          ),
        );
      }
      final res = await dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
      return Result.ok(res.data);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        return Result.fail(const ApiException(message: 'Request cancelled'));
      }
      return Result.fail(ApiException.fromDioException(e));
    } catch (e) {
      return Result.fail(ApiException(message: 'Unexpected error', details: e));
    }
  }

  Future<Result<dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  }) async {
    try {
      if (_config.baseUrl.trim().isEmpty && !_isAbsoluteUrl(path)) {
        return Result.fail(
          const ApiException(
            message:
                'API baseUrl is empty. Set --dart-define=API_BASE_URL=https://your-host',
          ),
        );
      }
      final res = await dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: options,
      );
      return Result.ok(res.data);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        return Result.fail(const ApiException(message: 'Request cancelled'));
      }
      return Result.fail(ApiException.fromDioException(e));
    } catch (e) {
      return Result.fail(ApiException(message: 'Unexpected error', details: e));
    }
  }

  Future<Result<dynamic>> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  }) async {
    try {
      if (_config.baseUrl.trim().isEmpty && !_isAbsoluteUrl(path)) {
        return Result.fail(
          const ApiException(
            message:
                'API baseUrl is empty. Set --dart-define=API_BASE_URL=https://your-host',
          ),
        );
      }
      final res = await dio.patch<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: options,
      );
      return Result.ok(res.data);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        return Result.fail(const ApiException(message: 'Request cancelled'));
      }
      return Result.fail(ApiException.fromDioException(e));
    } catch (e) {
      return Result.fail(ApiException(message: 'Unexpected error', details: e));
    }
  }

  Future<Result<dynamic>> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  }) async {
    try {
      if (_config.baseUrl.trim().isEmpty && !_isAbsoluteUrl(path)) {
        return Result.fail(
          const ApiException(
            message:
                'API baseUrl is empty. Set --dart-define=API_BASE_URL=https://your-host',
          ),
        );
      }
      final res = await dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: options,
      );
      return Result.ok(res.data);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        return Result.fail(const ApiException(message: 'Request cancelled'));
      }
      return Result.fail(ApiException.fromDioException(e));
    } catch (e) {
      return Result.fail(ApiException(message: 'Unexpected error', details: e));
    }
  }

  bool _isAbsoluteUrl(String path) {
    final p = path.trimLeft();
    return p.startsWith('http://') || p.startsWith('https://');
  }
}
