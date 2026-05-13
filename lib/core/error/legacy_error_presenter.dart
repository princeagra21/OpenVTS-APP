import 'package:open_vts/core/api/api_exception.dart';

/// Presentation-safe helpers for legacy transport errors.
///
/// Widgets should not import or type-check ApiException directly. These helpers
/// keep transport exception details behind a UI-safe facade until legacy flows
/// are fully migrated to AppError-based notifier states.
abstract final class LegacyErrorPresenter {
  static bool isApiFailure(Object? error) => error is ApiException;

  static int? statusCode(Object? error) {
    if (error is ApiException) return error.statusCode;
    return null;
  }

  static String message(Object? error, {String fallback = 'Something went wrong'}) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }
    final text = error?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }

  static bool hasMessage(Object? error) {
    if (error is ApiException) return error.message.trim().isNotEmpty;
    return error?.toString().trim().isNotEmpty ?? false;
  }

  static bool hasStatus(Object? error, int status) => statusCode(error) == status;
}
