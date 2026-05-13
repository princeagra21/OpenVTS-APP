import 'package:open_vts/features/map/domain/entities/telemetry_point.dart';

class VehicleMarkerState {
  const VehicleMarkerState({
    required this.latestByVehicle,
    this.lastFlushAt,
  });

  final Map<String, TelemetryPoint> latestByVehicle;
  final DateTime? lastFlushAt;

  const VehicleMarkerState.empty()
      : latestByVehicle = const <String, TelemetryPoint>{},
        lastFlushAt = null;

  VehicleMarkerState merge(Map<String, TelemetryPoint> updates) {
    return VehicleMarkerState(
      latestByVehicle: <String, TelemetryPoint>{...latestByVehicle, ...updates},
      lastFlushAt: DateTime.now(),
    );
  }
}
