import 'dart:async';
import 'package:open_vts/features/map/domain/entities/telemetry_data.dart';
import 'package:open_vts/features/map/domain/repositories/map_repository.dart';

class WatchAllVehiclePositionsUseCase {
  const WatchAllVehiclePositionsUseCase(this.repository);
  final MapRepository repository;
  Stream<TelemetryData> call() => repository.watchAllPositions();
}

class WatchVehicleTelemetryUseCase {
  const WatchVehicleTelemetryUseCase(this.repository);
  final MapRepository repository;
  Stream<TelemetryData> call(String imei) => repository.watchVehicle(imei);
}
