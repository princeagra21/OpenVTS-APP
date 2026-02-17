import 'package:dio/dio.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final Object? details;

  const ApiException({required this.message, this.statusCode, this.details});

  factory ApiException.fromDioException(DioException e) {
    final res = e.response;
    final status = res?.statusCode;
    final data = res?.data;

    // Try to derive a human-friendly message from common API response shapes.
    final msg =
        _extractMessage(data) ??
        res?.statusMessage ??
        e.message ??
        'Request failed';

    return ApiException(statusCode: status, message: msg, details: data);
  }

  static String? _extractMessage(Object? data) {
    if (data is Map) {
      final candidates = [
        data['message'],
        data['error'],
        data['msg'],
        (data['data'] is Map) ? (data['data'] as Map)['message'] : null,
      ];
      for (final c in candidates) {
        if (c is String && c.trim().isNotEmpty) return c;
      }
    }
    return null;
  }

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message)';
}
