import 'dart:async';

/// Generic latest-value throttler for telemetry-derived UI state.
///
/// The map pipeline primarily uses [TelemetryBuffer] for per-vehicle batching.
/// This utility is intentionally small and testable so future map overlays can
/// throttle expensive UI projections without subscribing directly to raw socket
/// events.
class TelemetryThrottler<T> {
  TelemetryThrottler({required this.interval});

  final Duration interval;
  Timer? _timer;
  T? _latest;
  void Function(T value)? onEmit;

  void add(T value) {
    _latest = value;
    _timer ??= Timer(interval, flush);
  }

  void flush() {
    final value = _latest;
    _latest = null;
    _timer?.cancel();
    _timer = null;
    if (value != null) onEmit?.call(value);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _latest = null;
  }
}
