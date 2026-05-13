/// Infrastructure-neutral application error hierarchy.
///
/// This file is intentionally pure Dart. It must not import HTTP clients,
/// generated transport exceptions, storage, or socket infrastructure.
/// Data/infrastructure failures are converted into these errors by
/// `error_mapper.dart`.
sealed class AppError {
  const AppError(this.message, {this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final Object? details;

  @override
  String toString() => '$runtimeType($message)';
}

final class NetworkError extends AppError {
  const NetworkError(super.message, {super.statusCode, super.details});
}

final class AuthError extends AppError {
  const AuthError(super.message, {super.statusCode = 401, super.details});
}

final class PermissionAppError extends AppError {
  const PermissionAppError(super.message, {super.statusCode = 403, super.details});
}

final class ValidationError extends AppError {
  const ValidationError(super.message, {super.statusCode = 400, super.details});
}

final class NotFoundError extends AppError {
  const NotFoundError(super.message, {super.statusCode = 404, super.details});
}

final class ConflictError extends AppError {
  const ConflictError(super.message, {super.statusCode = 409, super.details});
}

final class ServerError extends AppError {
  const ServerError(super.message, {super.statusCode = 500, super.details});
}

final class RateLimitError extends AppError {
  const RateLimitError(super.message, {super.statusCode = 429, super.details});
}

final class UnknownError extends AppError {
  const UnknownError(super.message, {super.statusCode, super.details});
}
