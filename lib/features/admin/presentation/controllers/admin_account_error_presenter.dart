import 'package:open_vts/core/error/app_error.dart';

bool adminAccountIsKnownFailure(Object? error) => error is AppError;

int? adminAccountStatusCode(Object? error) {
  if (error is AppError) return error.statusCode;
  return null;
}

bool adminAccountIsAuthFailure(Object? error) {
  if (error is AuthError || error is PermissionAppError) return true;
  final status = adminAccountStatusCode(error);
  return status == 401 || status == 403;
}

bool adminAccountIsCancelled(Object? error) {
  final message = adminAccountErrorMessage(error).toLowerCase();
  return message == 'request cancelled' || message.contains('cancelled');
}

String adminAccountErrorMessage(Object? error, {String fallback = 'Request failed.'}) {
  if (error is AppError && error.message.trim().isNotEmpty) return error.message.trim();
  final text = error?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}
