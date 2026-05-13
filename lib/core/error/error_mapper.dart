import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_exception.dart';
import 'package:open_vts/core/error/app_error.dart';

/// Infrastructure error mapper.
///
/// Data repositories, interceptors, and legacy adapters may import this file.
/// Domain entities/use cases should only depend on [AppError].
class AppErrorMapper {
  const AppErrorMapper._();

  static AppError fromObject(Object error) {
    if (error is AppError) return error;
    if (error is ApiException) return fromApiException(error);
    if (error is DioException) return fromDio(error);
    return UnknownError(error.toString(), details: error);
  }

  static AppError fromApiException(ApiException error) {
    final message = error.message.trim().isEmpty ? 'Request failed' : error.message.trim();
    return switch (error.statusCode) {
      400 => ValidationError(message, details: error.details),
      401 => AuthError(message, details: error.details),
      403 => PermissionAppError(message, details: error.details),
      404 => NotFoundError(message, details: error.details),
      409 => ConflictError(message, details: error.details),
      429 => RateLimitError(message, details: error.details),
      int n when n >= 500 => ServerError(message, details: error.details),
      _ => UnknownError(message, statusCode: error.statusCode, details: error.details),
    };
  }

  static AppError fromDio(DioException error) {
    final message = _extractMessage(error.response?.data) ??
        error.response?.statusMessage ??
        error.message ??
        'Request failed';

    return switch (error.type) {
      DioExceptionType.connectionError => const NetworkError(
          'No internet connection. Please check your network.',
        ),
      DioExceptionType.connectionTimeout => const NetworkError(
          'Request timed out. Please try again.',
        ),
      DioExceptionType.receiveTimeout => const NetworkError(
          'Server is taking too long to respond.',
        ),
      _ => switch (error.response?.statusCode) {
          400 => ValidationError(message, details: error.response?.data),
          401 => AuthError('Session expired. Please log in again.', details: error.response?.data),
          403 => PermissionAppError('You do not have access to this resource.', details: error.response?.data),
          404 => NotFoundError('The requested resource was not found.', details: error.response?.data),
          409 => ConflictError(message, details: error.response?.data),
          429 => RateLimitError('Too many requests. Please slow down.', details: error.response?.data),
          int n when n >= 500 => const ServerError('A server error occurred. Please try again later.'),
          _ => UnknownError(message, details: error.response?.data),
        },
    };
  }

  static String? _extractMessage(Object? data) {
    if (data is Map) {
      final candidates = [
        data['message'],
        data['error'],
        data['msg'],
        data['data'] is Map ? (data['data'] as Map)['message'] : null,
      ];
      for (final candidate in candidates) {
        if (candidate is String && candidate.trim().isNotEmpty) {
          return candidate.trim();
        }
      }
    }
    return null;
  }
}
