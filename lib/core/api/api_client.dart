import 'package:open_vts/core/api/api_exception.dart';
import 'package:open_vts/core/api/api_result.dart';
import 'package:open_vts/core/api/interceptors/auth_interceptor.dart';
import 'package:open_vts/core/api/interceptors/refresh_token_interceptor.dart';
import 'package:open_vts/core/api/interceptors/logging_interceptor.dart';
import 'package:open_vts/core/api/legacy_api_transport.dart';
import 'package:open_vts/core/config/app_config.dart';
import 'package:open_vts/core/diagnostics/api_diagnostics.dart';
import 'package:open_vts/core/network/diagnostic_dio_interceptor.dart';
import 'package:open_vts/core/observability/observability_service.dart';
import 'package:open_vts/core/storage/token_storage.dart';
import 'package:open_vts/core/utils/request_control.dart';

/// Legacy HTTP client kept only for old compatibility repositories.
///
/// New code should use generated Retrofit services from feature DI. This class
/// remains the single initialized transport for old modules until their
/// repositories are removed.
class ApiClient implements LegacyApiTransport {
  final Dio dio;
  AppConfig _config;
  final TokenStorageBase _tokenStorage;

  ApiClient._(this.dio, this._config, this._tokenStorage);

  factory ApiClient({
    required AppConfig config,
    required TokenStorageBase tokenStorage,
    ObservabilityService? observability,
    ApiDiagnostics? apiDiagnostics,
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
      RefreshTokenInterceptor(tokenStorage: tokenStorage, dio: dio),
    );
    if (observability != null && config.enablePerformanceDiagnostics) {
      dio.interceptors.add(
        DiagnosticDioInterceptor(
          diagnostics: apiDiagnostics ?? ApiDiagnostics(),
          observability: observability,
        ),
      );
    }

    if (config.enableNetworkLogs) {
      final safeLogger = LoggingInterceptorFactory.create();
      if (safeLogger != null) {
        dio.interceptors.add(safeLogger);
      }
    }

    return ApiClient._(dio, config, tokenStorage);
  }

  void updateBaseUrl(String baseUrl) {
    var normalized = baseUrl.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    _config = _config.copyWith(baseUrl: normalized, socketUrl: normalized);
    dio.options.baseUrl = normalized;
  }

  @override
  Future<Result<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return _send(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<Result<dynamic>> post(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  }) {
    return _send(
      method: 'POST',
      path: path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: options,
    );
  }

  @override
  Future<Result<dynamic>> patch(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  }) {
    return _send(
      method: 'PATCH',
      path: path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: options,
    );
  }

  @override
  Future<Result<dynamic>> put(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  }) {
    return _send(
      method: 'PUT',
      path: path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: options,
    );
  }

  @override
  Future<Result<dynamic>> delete(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  }) {
    return _send(
      method: 'DELETE',
      path: path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      options: options,
    );
  }

  Future<Result<dynamic>> _send({
    required String method,
    required String path,
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
  }) async {
    try {
      final baseUrl = _config.baseUrl.trim();
      if (baseUrl.isEmpty && !_isAbsoluteUrl(path)) {
        return Result.fail(
          const ApiException(
            message:
                'API baseUrl is empty. Set --dart-define=API_BASE_URL=https://your-host',
          ),
        );
      }

      final response = await dio.request<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        options: (options ?? Options()).copyWith(method: method),
      );
      return Result.ok(response.data);
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        return Result.fail(const ApiException(message: 'Request cancelled'));
      }
      return Result.fail(ApiException.fromDioException(error));
    } catch (error) {
      return Result.fail(
        ApiException(message: 'Unexpected error', details: error),
      );
    }
  }

  bool _isAbsoluteUrl(String path) {
    final value = path.trimLeft();
    return value.startsWith('http://') || value.startsWith('https://');
  }
}
