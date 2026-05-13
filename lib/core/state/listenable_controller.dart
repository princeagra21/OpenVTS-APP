import 'package:flutter/foundation.dart';

/// Small compatibility listenable used while legacy screen-created controllers
/// are migrated toward Riverpod state controllers.
///
/// It intentionally does not extend [ChangeNotifier], so API/business state no
/// longer relies on Flutter's ChangeNotifier inheritance. New work should prefer
/// Riverpod Notifier/StateNotifier providers directly.
abstract class ListenableController {
  final List<VoidCallback> _listeners = <VoidCallback>[];
  bool _disposed = false;

  void addListener(VoidCallback listener) {
    if (_disposed || _listeners.contains(listener)) return;
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  @protected
  void notifyListeners() {
    if (_disposed) return;
    for (final listener in List<VoidCallback>.from(_listeners)) {
      listener();
    }
  }

  @mustCallSuper
  void dispose() {
    _disposed = true;
    _listeners.clear();
  }
}
