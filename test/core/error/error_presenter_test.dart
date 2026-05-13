import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_presenter.dart';

void main() {
  test('ErrorPresenter preserves AppError message', () {
    const error = PermissionAppError('No access');

    expect(ErrorPresenter.message(error), 'No access');
    expect(ErrorPresenter.isAuthOrPermission(error), isTrue);
  });

  test('ErrorPresenter uses fallback for null error', () {
    expect(
      ErrorPresenter.message(null, fallback: 'Fallback message'),
      'Fallback message',
    );
  });

  test('ErrorPresenter detects request cancellation text', () {
    expect(ErrorPresenter.isCancellation('Request cancelled'), isTrue);
  });
}
