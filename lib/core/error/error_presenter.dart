import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';

/// Presentation-safe AppError message mapper.
///
/// Widgets and transitional presentation controllers should use this instead
/// of legacy transport helpers. It accepts [Object] only to keep older result
/// facades usable while each feature moves toward `Result<T, AppError>`.
abstract final class ErrorPresenter {
  static AppError toAppError(Object? error, {String fallback = 'Something went wrong'}) {
    if (error is AppError) return error;
    if (error == null) return UnknownError(fallback);
    return AppErrorMapper.fromObject(error);
  }

  static String message(Object? error, {String fallback = 'Something went wrong'}) {
    final appError = toAppError(error, fallback: fallback);
    final text = appError.message.trim();
    return text.isEmpty ? fallback : text;
  }

  static int? statusCode(Object? error) => toAppError(error).statusCode;

  static bool hasStatus(Object? error, int status) => statusCode(error) == status;

  static bool isAuthOrPermission(Object? error) {
    final status = statusCode(error);
    return status == 401 || status == 403 || error is AuthError || error is PermissionAppError;
  }

  static bool isCancellation(Object? error) {
    final text = error?.toString().toLowerCase() ?? '';
    return text.contains('request cancelled') || text.contains('request canceled');
  }
}
