import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_vts/core/debug/app_logger.dart';
import 'package:open_vts/core/security/token_redactor.dart';

/// Debug-only, metadata-only Dio logger.
///
/// This interceptor deliberately never logs HTTP bodies. It records only safe
/// request metadata such as method, endpoint pattern, status code, and redacted
/// query/header keys. Detailed production diagnostics belong in
/// [DiagnosticDioInterceptor], not console logging.
class LoggingInterceptorFactory {
  const LoggingInterceptorFactory._();

  static Interceptor? create({TokenRedactor redactor = const TokenRedactor()}) {
    if (!kDebugMode) return null;
    return SafeDioLoggingInterceptor(redactor: redactor);
  }
}

class SafeDioLoggingInterceptor extends Interceptor {
  SafeDioLoggingInterceptor({TokenRedactor redactor = const TokenRedactor()})
      : _redactor = redactor;

  final TokenRedactor _redactor;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.event('api_request', context: safeRequestContext(options));
    handler.next(options);
  }

  @visibleForTesting
  Map<String, Object?> safeRequestContext(RequestOptions options) {
    return <String, Object?>{
      'method': options.method,
      'endpoint': _endpointPattern(options.path),
      'queryKeys': options.queryParameters.keys.map(_redactor.redact).toList(growable: false),
      'headerKeys': _safeHeaderKeys(options.headers),
    };
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    AppLogger.event(
      'api_response',
      context: <String, Object?>{
        'method': response.requestOptions.method,
        'endpoint': _endpointPattern(response.requestOptions.path),
        'statusCode': response.statusCode,
      },
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.warning(
      'api_error',
      context: <String, Object?>{
        'method': err.requestOptions.method,
        'endpoint': _endpointPattern(err.requestOptions.path),
        'type': err.type.name,
        if (err.response?.statusCode != null) 'statusCode': err.response?.statusCode,
      },
    );
    handler.next(err);
  }

  List<String> _safeHeaderKeys(Map<String, Object?> headers) {
    return headers.keys
        .map(_redactor.redact)
        .where((key) => key.toLowerCase() != 'authorization')
        .toList(growable: false);
  }

  String _endpointPattern(String path) {
    return _redactor.redact(
      path
          .replaceAll(RegExp(r'/[0-9a-fA-F]{16,}'), '/:id')
          .replaceAll(RegExp(r'/\d+'), '/:id'),
    );
  }
}
