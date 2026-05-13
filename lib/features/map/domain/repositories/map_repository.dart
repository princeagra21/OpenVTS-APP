import 'dart:async';
import 'package:open_vts/features/map/domain/entities/telemetry_data.dart';

abstract interface class MapRepository {
  Stream<TelemetryData> watchAllPositions();
  Stream<TelemetryData> watchVehicle(String imei);
}
