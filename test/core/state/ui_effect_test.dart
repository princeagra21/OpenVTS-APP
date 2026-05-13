import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/state/ui_effect.dart';

void main() {
  test('UiEffect showSuccess carries message', () {
    const effect = UiEffect.showSuccess('Saved');

    expect(effect, isA<UiSuccessEffect>());
    expect((effect as UiSuccessEffect).message, 'Saved');
  });

  test('UiEffect showError carries fallback', () {
    const effect = UiEffect.showError('Network failed', fallback: 'Try again');

    expect(effect, isA<UiErrorEffect>());
    expect((effect as UiErrorEffect).fallback, 'Try again');
  });
}
