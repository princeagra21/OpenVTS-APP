import 'dart:async';

import 'package:dio/dio.dart';
import 'package:open_vts/core/debug/app_logger.dart';
import 'package:open_vts/core/diagnostics/api_diagnostics.dart';
import 'package:open_vts/core/observability/observability_service.dart';
import 'package:open_vts/core/security/token_redactor.dart';

class DiagnosticDioInterceptor extends Interceptor {
  DiagnosticDioInterceptor({
    required ApiDiagnostics diagnostics,
    required ObservabilityService observability,
    TokenRedactor redactor = const TokenRedactor(),
  })  : _diagnostics = diagnostics,
        _observability = observability,
        _redactor = redactor;

  final ApiDiagnostics _diagnostics;
  final ObservabilityService _observability;
  final TokenRedactor _redactor;

  static const String _startKey = 'diagnosticsStartedAt';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = DateTime.now().millisecondsSinceEpoch;
    unawaited(
      _observability.addBreadcrumb(
        'api',
        'api_request_started',
        data: <String, Object?>{
          'endpoint': _endpointPattern(options.path),
          'method': options.method,
        },
      ),
    );
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final options = response.requestOptions;
    final durationMs = _durationMs(options);
    unawaited(
      _observability.recordMetric(
        'api.request_duration_ms',
        durationMs ?? 0,
        tags: <String, Object?>{
          'endpoint': _endpointPattern(options.path),
          'method': options.method,
          'statusCode': response.statusCode,
        },
      ),
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    final durationMs = _durationMs(options);
    final requestId = options.headers['x-request-id']?.toString() ??
        err.response?.headers.value('x-request-id');

    final summary = SafeApiFailureSummary(
      endpointPattern: _endpointPattern(options.path),
      method: options.method,
      errorType: err.type.name,
      statusCode: err.response?.statusCode,
      requestId: requestId,
      durationMs: durationMs,
    );
    _diagnostics.recordFailure(summary);
    final context = _redactor.redactMap(<String, Object?>{
      'endpoint': summary.endpointPattern,
      'method': summary.method,
      'type': summary.errorType,
      if (summary.statusCode != null) 'statusCode': summary.statusCode,
      if (summary.durationMs != null) 'durationMs': summary.durationMs,
      if (summary.requestId != null) 'requestId': summary.requestId,
    });
    AppLogger.warning('api_request_failed', context: context);
    unawaited(_observability.addBreadcrumb('api', 'api_request_failed', data: context));
    unawaited(_observability.recordMetric('api.request_failure_count', 1, tags: context));
    unawaited(
      _observability.captureException(
        err,
        err.stackTrace,
        context: <String, Object?>{
          ...context,
          'reason': 'API request failed',
        },
      ),
    );
    handler.next(err);
  }

  int? _durationMs(RequestOptions options) {
    final startedAt = options.extra[_startKey];
    return startedAt is int ? DateTime.now().millisecondsSinceEpoch - startedAt : null;
  }

  String _endpointPattern(String path) {
    return _redactor.redact(
      path
          .replaceAll(RegExp(r'/[0-9a-fA-F]{16,}'), '/:id')
          .replaceAll(RegExp(r'/\d+'), '/:id'),
    );
  }
}
