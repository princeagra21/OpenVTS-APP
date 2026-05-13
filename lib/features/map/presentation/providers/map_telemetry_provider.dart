import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/telemetry/telemetry_backpressure_policy.dart';
import 'package:open_vts/core/telemetry/telemetry_buffer.dart';
import 'package:open_vts/core/telemetry/telemetry_deduplicator.dart';
import 'package:open_vts/core/telemetry/telemetry_parser.dart';
import 'package:open_vts/core/diagnostics/diagnostics_providers.dart';
import 'package:open_vts/features/map/di/map_socket_providers.dart';
import 'package:open_vts/features/map/domain/entities/map_vehicle_snapshot.dart';
import 'package:open_vts/features/map/domain/entities/map_vehicle_point.dart';
import 'package:open_vts/features/map/domain/entities/telemetry_point.dart';
import 'package:open_vts/features/map/domain/entities/vehicle_marker_state.dart';
import 'package:open_vts/features/map/presentation/open_vts_map/open_vts_map_marker_projection.dart';
import 'package:open_vts/features/map/presentation/open_vts_map/models/map_vehicle_status_filter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'map_telemetry_provider.g.dart';

@riverpod
TelemetryParser telemetryParser(TelemetryParserRef ref) => const TelemetryParser();

@riverpod
TelemetryBackpressurePolicy telemetryBackpressurePolicy(
  TelemetryBackpressurePolicyRef ref,
) {
  return const TelemetryBackpressurePolicy(
    flushInterval: Duration(milliseconds: 500),
  );
}

class MapTelemetryUpdate {
  const MapTelemetryUpdate({
    required this.snapshot,
    required this.point,
  });

  final MapVehicleSnapshot snapshot;
  final TelemetryPoint point;
}

final liveMapVehiclePointsProvider = Provider.autoDispose<List<MapVehiclePoint>>((ref) {
  final markerState = ref.watch(mapTelemetryNotifierProvider);
  return OpenVtsMapMarkerProjection.fromMarkerState(markerState);
});

final mapStatusCountsProvider = Provider.autoDispose<MapVehicleStatusCounts>((ref) {
  final points = ref.watch(liveMapVehiclePointsProvider);
  return buildMapVehicleStatusCounts(points);
});

@riverpod
class MapTelemetryNotifier extends _$MapTelemetryNotifier {
  StreamSubscription<MapVehicleSnapshot>? _subscription;
  late final TelemetryDeduplicator _deduplicator;
  late final TelemetryBuffer _buffer;

  @override
  VehicleMarkerState build() {
    _deduplicator = TelemetryDeduplicator();
    _buffer = TelemetryBuffer(
      policy: ref.watch(telemetryBackpressurePolicyProvider),
    );
    _buffer.onFlush = (snapshot) {
      final nextState = state.merge(snapshot);
      ref.read(mapPerformanceDiagnosticsProvider).recordMarkerBatch(
            markerCount: nextState.latestByVehicle.length,
            batchSize: snapshot.length,
          );
      ref.read(socketDiagnosticsProvider).recordBufferFlush();
      state = nextState;
    };
    ref.onDispose(() {
      _subscription?.cancel();
      _buffer.dispose();
      _deduplicator.clear();
    });
    unawaited(_listen());
    return const VehicleMarkerState.empty();
  }

  Future<void> _listen() async {
    final stream = ref.read(mapVehicleSnapshotStreamProvider.stream);
    _subscription ??= stream.listen(_acceptSnapshot);
  }

  void _acceptSnapshot(MapVehicleSnapshot snapshot) {
    final point = snapshot.toTelemetryPoint();
    final policy = ref.read(telemetryBackpressurePolicyProvider);
    if (!policy.isFresh(point.recordedAt, DateTime.now())) {
      ref.read(socketDiagnosticsProvider).recordTelemetryDropped();
      return;
    }
    if (!_deduplicator.shouldAccept(point)) {
      ref.read(socketDiagnosticsProvider).recordTelemetryDropped();
      return;
    }
    _buffer.add(point);
  }
}

@riverpod
TelemetryPoint? selectedVehicleTelemetry(
  SelectedVehicleTelemetryRef ref,
  String imei,
) {
  final markers = ref.watch(
    mapTelemetryNotifierProvider.select((state) => state.latestByVehicle),
  );
  return markers[imei];
}
