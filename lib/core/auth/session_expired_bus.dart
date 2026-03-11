import 'dart:async';

class SessionExpiredBus {
  SessionExpiredBus._();

  static final StreamController<void> _controller =
      StreamController<void>.broadcast();

  static DateTime? _lastEmitAt;

  static Stream<void> get stream => _controller.stream;

  static void emit() {
    final now = DateTime.now();
    final last = _lastEmitAt;
    if (last != null && now.difference(last).inMilliseconds < 1200) {
      return;
    }
    _lastEmitAt = now;
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }
}
