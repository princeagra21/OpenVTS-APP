import 'package:open_vts/features/map/domain/entities/telemetry_point.dart';

class TelemetryParser {
  const TelemetryParser();

  TelemetryPoint? parse(Map<String, dynamic> raw) {
    final imei = _string(raw, const ['imei', 'deviceImei', 'deviceIMEI']);
    final vehicleId = _string(raw, const ['vehicleId', 'id', 'vehicle_id']);
    final latitude = _double(raw, const ['latitude', 'lat']);
    final longitude = _double(raw, const ['longitude', 'lng', 'lon']);
    if (imei.isEmpty || latitude == null || longitude == null) return null;

    final timestamp = _date(raw, const ['timestamp', 'recordedAt', 'createdAt', 'time']) ?? DateTime.now();
    return TelemetryPoint(
      vehicleId: vehicleId.isEmpty ? imei : vehicleId,
      imei: imei,
      latitude: latitude,
      longitude: longitude,
      recordedAt: timestamp,
      speedKph: _double(raw, const ['speed', 'speedKph']) ?? 0,
      heading: _double(raw, const ['heading', 'course', 'bearing']) ?? 0,
      ignition: _bool(raw, const ['ignition', 'acc']) ?? ((_double(raw, const ['speed', 'speedKph']) ?? 0) > 0),
      sequence: _string(raw, const ['sequence', 'seq', 'packetId']),
      raw: Map<String, Object?>.from(raw),
    );
  }

  String _string(Map<String, dynamic> raw, List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value != null && value.toString().trim().isNotEmpty) return value.toString();
    }
    return '';
  }

  double? _double(Map<String, dynamic> raw, List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value.trim());
    }
    return null;
  }

  bool? _bool(Map<String, dynamic> raw, List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
    }
    return null;
  }

  DateTime? _date(Map<String, dynamic> raw, List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) return DateTime.tryParse(value);
    }
    return null;
  }
}
