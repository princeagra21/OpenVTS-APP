import 'package:open_vts/core/state/listenable_controller.dart';
import 'package:open_vts/core/state/ui_effect.dart';

/// Adds one-shot UI effect support to transitional listenable controllers.
///
/// New Riverpod Notifiers can expose the same [UiEffect] model through typed
/// state. This mixin exists so migrated legacy controllers can stop presenting
/// errors directly and let widgets listen/render effects.
mixin EffectControllerMixin on ListenableController {
  UiEffect? _pendingEffect;
  int _effectVersion = 0;

  UiEffect? get pendingEffect => _pendingEffect;
  int get effectVersion => _effectVersion;

  void emitEffect(UiEffect effect) {
    _pendingEffect = effect;
    _effectVersion++;
    notifyListeners();
  }

  UiEffect? takeEffect() {
    final effect = _pendingEffect;
    _pendingEffect = null;
    return effect;
  }
}
