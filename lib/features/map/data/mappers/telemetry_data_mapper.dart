import 'package:open_vts/features/map/domain/entities/telemetry_data.dart';

class TelemetryDataMapper {
  const TelemetryDataMapper();

  TelemetryData fromBackend(Object? response) => TelemetryData.fromJson(response);
}
