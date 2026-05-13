import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('OpenVTS map keeps live telemetry watches inside small consumers', () {
    final source = File(
      'lib/features/map/presentation/open_vts_map/open_vts_map_screen.dart',
    ).readAsStringSync();

    expect(source, contains('RepaintBoundary'));
    expect(source, contains('LiveVehicleMarkerLayer'));
    expect(source, isNot(contains('ref.listen<List<MapVehiclePoint>>')));
    expect(source, isNot(contains('final livePoints = ref.watch(liveMapVehiclePointsProvider);\n    final pointsToRender')));
  });

  test('marker layer remains presentation-only', () {
    final source = File(
      'lib/features/map/presentation/open_vts_map/widgets/live_vehicle_marker_layer.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('/data/repositories/')));
    expect(source, isNot(contains('core/api')));
    expect(source, isNot(contains('SocketService')));
    expect(source, isNot(contains('ApiClient')));
  });
}
