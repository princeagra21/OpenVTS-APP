import 'package:open_vts/core/error/app_error.dart';

/// One-shot UI effects emitted by controllers.
///
/// State objects should own loading/data/error. Effects are reserved for
/// transient UI actions such as SnackBars, dialogs, route changes, and session
/// expiration. Widgets listen for these effects and render the platform UI.
sealed class UiEffect {
  const UiEffect();

  const factory UiEffect.showSuccess(String message) = UiSuccessEffect;
  const factory UiEffect.showError(Object error, {String? fallback}) = UiErrorEffect;
  const factory UiEffect.showMessage(String message) = UiMessageEffect;
  const factory UiEffect.navigate(String routeName, {Object? extra}) = UiNavigateEffect;
  const factory UiEffect.confirmDialog({
    required String title,
    required String message,
    String confirmLabel,
    String cancelLabel,
  }) = UiConfirmDialogEffect;
  const factory UiEffect.sessionExpired({String message}) = UiSessionExpiredEffect;
}

final class UiSuccessEffect extends UiEffect {
  const UiSuccessEffect(this.message);
  final String message;
}

final class UiErrorEffect extends UiEffect {
  const UiErrorEffect(this.error, {this.fallback});
  final Object error;
  final String? fallback;

  AppError? get appError => error is AppError ? error as AppError : null;
}

final class UiMessageEffect extends UiEffect {
  const UiMessageEffect(this.message);
  final String message;
}

final class UiNavigateEffect extends UiEffect {
  const UiNavigateEffect(this.routeName, {this.extra});
  final String routeName;
  final Object? extra;
}

final class UiConfirmDialogEffect extends UiEffect {
  const UiConfirmDialogEffect({
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
}

final class UiSessionExpiredEffect extends UiEffect {
  const UiSessionExpiredEffect({this.message = 'Session expired. Please log in again.'});
  final String message;
}
