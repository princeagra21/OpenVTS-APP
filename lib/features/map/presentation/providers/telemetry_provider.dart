import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/map/domain/entities/telemetry_data.dart';
import 'package:open_vts/features/map/presentation/providers/map_telemetry_provider.dart';

/// Backward-compatible telemetry providers derived from the single enterprise
/// map telemetry pipeline.
///
/// Do not subscribe to raw realtime transport from presentation. Events flow
/// through map_socket_providers -> MapTelemetryNotifier -> UI-ready state.
final allVehiclePositionsProvider = Provider.autoDispose<List<TelemetryData>>((ref) {
  final markerState = ref.watch(mapTelemetryNotifierProvider);
  return markerState.latestByVehicle.values
      .map(
        (point) => TelemetryData(
          imei: point.imei,
          latitude: point.latitude,
          longitude: point.longitude,
          speed: point.speedKph,
          heading: point.heading,
          ignition: point.ignition,
        ),
      )
      .toList(growable: false);
});

final vehicleTelemetryProvider =
    Provider.autoDispose.family<TelemetryData?, String>((ref, imei) {
  final marker = ref.watch(
    mapTelemetryNotifierProvider.select(
      (state) => state.latestByVehicle[imei],
    ),
  );
  if (marker == null) return null;
  return TelemetryData(
    imei: marker.imei,
    latitude: marker.latitude,
    longitude: marker.longitude,
    speed: marker.speedKph,
    heading: marker.heading,
    ignition: marker.ignition,
  );
});
