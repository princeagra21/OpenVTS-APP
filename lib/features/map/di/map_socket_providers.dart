import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/socket/socket_providers.dart';
import 'package:open_vts/core/socket/socket_service.dart';
import 'package:open_vts/features/map/data/mappers/map_vehicle_snapshot_mapper.dart';
import 'package:open_vts/features/map/domain/entities/map_vehicle_snapshot.dart';

/// Map-specific socket dependencies.
///
/// This feature DI layer intentionally avoids presentation repository bridges.
/// It exposes typed live vehicle snapshots to the map telemetry notifier.
final mapSocketServiceProvider = FutureProvider<SocketService>((ref) {
  return ref.watch(coreSocketServiceProvider.future);
});

final mapVehicleSnapshotMapperProvider = Provider<MapVehicleSnapshotMapper>((ref) {
  return const MapVehicleSnapshotMapper();
});

final mapVehicleSnapshotStreamProvider = StreamProvider.autoDispose<MapVehicleSnapshot>((ref) async* {
  final socket = await ref.watch(mapSocketServiceProvider.future);
  final mapper = ref.watch(mapVehicleSnapshotMapperProvider);

  await for (final raw in socket.allVehiclePositions()) {
    final snapshot = mapper.fromBackendMap(raw);
    if (snapshot == null || !snapshot.hasValidPosition) continue;
    yield snapshot;
  }
});
