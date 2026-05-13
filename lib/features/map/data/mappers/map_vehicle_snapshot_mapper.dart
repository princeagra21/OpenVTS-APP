import 'package:open_vts/features/map/domain/entities/map_vehicle_snapshot.dart';

class MapVehicleSnapshotMapper {
  const MapVehicleSnapshotMapper();

  MapVehicleSnapshot? fromBackendMap(Map<String, dynamic> raw) {
    final telemetry = _map(
      raw['telemetry'] ??
          raw['latestTelemetry'] ??
          raw['latest_telemetry'] ??
          raw['lastTelemetry'] ??
          raw['telemetryData'] ??
          raw['telemetry_data'],
    );

    final imei = _string(raw, const ['imei', 'deviceImei', 'deviceIMEI', 'device_imei', 'imeiNumber']);
    final vehicleId = _string(raw, const ['vehicleId', 'vehicle_id', 'id', 'uuid']);
    final lat = _double(raw, const ['lat', 'latitude', 'locationLat', 'location_lat']) ??
        _double(telemetry, const ['lat', 'latitude']);
    final lng = _double(raw, const ['lng', 'lon', 'long', 'longitude', 'locationLng', 'location_lng']) ??
        _double(telemetry, const ['lng', 'lon', 'longitude']);

    if (lat == null || lng == null || !_validLatLng(lat, lng)) {
      return null;
    }
    if (imei.trim().isEmpty && vehicleId.trim().isEmpty) {
      return null;
    }

    final speed = _double(raw, const ['speedKph', 'speed_kph', 'speed', 'currentSpeed']) ??
        _double(telemetry, const ['speedKph', 'speed_kph', 'speed', 'currentSpeed']) ??
        0;
    final heading = _double(raw, const ['heading', 'course', 'bearing', 'angle']) ??
        _double(telemetry, const ['heading', 'course', 'bearing', 'angle']) ??
        0;
    final ignition = _bool(raw, const ['ignition', 'ignitionStatus', 'isIgnitionOn', 'acc']) ??
        _bool(telemetry, const ['ignition', 'ignitionStatus', 'isIgnitionOn', 'acc']) ??
        speed > 0;

    return MapVehicleSnapshot(
      vehicleId: vehicleId.trim().isEmpty ? imei : vehicleId,
      imei: imei.trim().isEmpty ? vehicleId : imei,
      plateNumber: _string(raw, const [
        'plateNumber',
        'plate',
        'registrationNumber',
        'vehicleName',
        'name',
      ]),
      lat: lat,
      lng: lng,
      speedKph: speed,
      heading: heading,
      ignition: ignition,
      status: _string(raw, const ['status', 'state', 'motion']),
      vehicleTypeName: _vehicleTypeName(raw),
      serverTime: _date(raw, const ['serverTime', 'server_time']) ??
          _date(telemetry, const ['serverTime', 'server_time']),
      deviceTime: _date(raw, const ['deviceTime', 'device_time']) ??
          _date(telemetry, const ['deviceTime', 'device_time']),
      lastUpdate: _date(raw, const [
            'lastUpdate',
            'last_update',
            'updatedAt',
            'updated_at',
            'lastSeen',
            'lastSeenAt',
            'last_seen_at',
            'timestamp',
            'time',
            'recordedAt',
          ]) ??
          _date(telemetry, const ['timestamp', 'time', 'recordedAt']),
    );
  }

  static bool _validLatLng(double lat, double lng) {
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180 && !(lat == 0 && lng == 0);
  }

  static String _string(Map<String, dynamic> raw, List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  static double? _double(Map<String, dynamic> raw, List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value.trim());
    }
    return null;
  }

  static bool? _bool(Map<String, dynamic> raw, List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1' || normalized == 'on') return true;
        if (normalized == 'false' || normalized == '0' || normalized == 'off') return false;
      }
    }
    return null;
  }

  static DateTime? _date(Map<String, dynamic> raw, List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String && value.trim().isNotEmpty) {
        return DateTime.tryParse(value.trim());
      }
    }
    return null;
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value.cast());
    return const <String, dynamic>{};
  }

  static String _vehicleTypeName(Map<String, dynamic> raw) {
    final candidates = <Object?>[
      raw['vehicleTypeName'],
      raw['vehicle_type_name'],
      raw['vehicle_type'],
      raw['type'],
      raw['vehicleType'],
      raw['vehicletype'],
      raw['vehicle_class'],
      raw['vehicleClass'],
      raw['typeName'],
      raw['type_name'],
    ];
    for (final candidate in candidates) {
      final value = _extractVehicleTypeLabel(candidate);
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static String _extractVehicleTypeLabel(Object? value) {
    if (value == null) return '';
    if (value is Map) {
      final map = Map<String, dynamic>.from(value.cast());
      final nested = map['vehicleType'] is Map
          ? _extractVehicleTypeLabel(map['vehicleType'])
          : '';
      if (nested.isNotEmpty) return nested;
      return (map['name'] ??
              map['title'] ??
              map['type'] ??
              map['slug'] ??
              map['label'] ??
              map['code'] ??
              map['displayName'] ??
              map['display_name'] ??
              '')
          .toString()
          .trim();
    }
    final text = value.toString().trim();
    if (text.startsWith('{') && text.endsWith('}')) return '';
    return text;
  }
}
