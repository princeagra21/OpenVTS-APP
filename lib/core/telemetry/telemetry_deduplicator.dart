import 'package:open_vts/features/map/domain/entities/telemetry_point.dart';

class TelemetryDeduplicator {
  TelemetryDeduplicator({this.maxKeys = 20000});

  final int maxKeys;
  final Set<String> _seen = <String>{};
  final List<String> _order = <String>[];

  bool shouldAccept(TelemetryPoint point) {
    final key = point.dedupeKey;
    if (_seen.contains(key)) return false;
    _seen.add(key);
    _order.add(key);
    while (_order.length > maxKeys) {
      _seen.remove(_order.removeAt(0));
    }
    return true;
  }

  void clear() {
    _seen.clear();
    _order.clear();
  }
}
