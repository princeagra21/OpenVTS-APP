import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/features/superadmin/data/models/superadmin_vehicle_dtos.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_vehicle.dart';

class SuperadminVehicleMapper {
  const SuperadminVehicleMapper();

  List<SuperadminVehicleDto> vehiclesFromResponse(Object? response) {
    return ApiResponseNormalizer.listOf(response, preferredKeys: const ['vehicles', 'items', 'rows', 'data'])
        .map(_mapOf)
        .where((m) => m.isNotEmpty)
        .map(SuperadminVehicleDto.fromJson)
        .toList(growable: false);
  }

  SuperadminVehicleDto? vehicleFromResponse(Object? response) {
    final payload = ApiResponseNormalizer.mapPayloadOf(response, preferredKeys: const ['vehicle', 'data']);
    final nested = _mapOf(payload['vehicle']);
    final chosen = nested.isNotEmpty ? nested : payload;
    return chosen.isEmpty ? null : SuperadminVehicleDto.fromJson(chosen);
  }

  SuperadminVehicleListItem listItem(SuperadminVehicleDto dto) {
    final json = dto.json;
    return SuperadminVehicleListItem(
      id: _text(_first(json, const ['id', 'vehicleID', 'vehicleId', 'vehicle_id', 'uuid', 'uid'])),
      name: _text(_first(json, const ['name', 'title', 'vehicleName', 'vehicle_name', 'plateNumber'])),
      plateNumber: _text(_first(json, const ['plateNumber', 'plate_number', 'plate', 'registrationNumber', 'registration_number'])),
      status: _status(_first(json, const ['status', 'state', 'vehicleStatus', 'isActive', 'active', 'is_active'])),
      isActive: _bool(_first(json, const ['isActive', 'active', 'is_active', 'status'])),
      imei: _text(_first(json, const ['imei', 'deviceImei', 'device_imei', 'imeiNumber'])),
      vin: _text(_first(json, const ['vin', 'VIN', 'chassisNumber'])),
      simNumber: _text(_first(json, const ['simNumber', 'sim_number', 'simNo', 'sim'])),
      type: _vehicleType(json),
      updatedAt: _text(_first(json, const ['updatedAt', 'updated_at', 'lastActivityAt', 'last_activity_at', 'lastSeenAt', 'last_seen_at', 'createdAt', 'created_at'])),
      raw: json,
    );
  }

  SuperadminVehicleDetail detail(SuperadminVehicleDto dto, {Map<String, Object?> telemetry = const <String, Object?>{}}) {
    final json = dto.json;
    final device = _mapOf(json['device']);
    final deviceType = _mapOf(device['type']);
    return SuperadminVehicleDetail(
      id: _text(_first(json, const ['id', 'vehicleId', 'vehicle_id', 'uuid'])),
      name: _text(_first(json, const ['name', 'vehicleName', 'vehicle_name', 'title'])),
      plate: _text(_first(json, const ['plateNumber', 'plate_number', 'plate', 'registrationNumber', 'registration_number'])),
      status: _text(_first(json, const ['status', 'state'])),
      isActive: _bool(_first(json, const ['active', 'isActive', 'is_active', 'status'])),
      imei: _text(_first(json, const ['imei', 'deviceImei', 'device_imei', 'imeiNumber'])) .isNotEmpty
          ? _text(_first(json, const ['imei', 'deviceImei', 'device_imei', 'imeiNumber']))
          : _text(device['imei']),
      model: _text(_first(json, const ['model', 'deviceModel'])) .isNotEmpty
          ? _text(_first(json, const ['model', 'deviceModel']))
          : _text(_first(deviceType, const ['name', 'manufacturer'])),
      type: _vehicleType(json),
      telemetryUpdatedAt: _text(_first(telemetry, const ['updatedAt', 'updated_at', 'timestamp', 'time'])),
    );
  }

  List<SuperadminCommandOption> commandOptionsFromResponse(Object? response) {
    return ApiResponseNormalizer.listOf(response, preferredKeys: const ['commandtypes', 'commands', 'items'])
        .map(_mapOf)
        .where((m) => m.isNotEmpty)
        .map((json) => SuperadminCommandOption(
              id: _text(_first(json, const ['id', 'commandTypeId', 'code'])),
              name: _text(_first(json, const ['name', 'title', 'command'])),
              code: _text(_first(json, const ['code', 'command', 'name'])),
              requiresPayload: _bool(_first(json, const ['requiresPayload', 'requires_data', 'hasPayload']), defaultValue: true),
            ))
        .toList(growable: false);
  }

  List<SuperadminSentCommand> sentCommandsFromResponse(Object? response) {
    return ApiResponseNormalizer.listOf(response, preferredKeys: const ['commands', 'customcommands', 'items'])
        .map(_mapOf)
        .where((m) => m.isNotEmpty)
        .map((json) => SuperadminSentCommand(
              name: _text(_first(json, const ['name', 'title', 'command', 'code'])),
              status: _text(_first(json, const ['status', 'state'])),
              createdAt: _text(_first(json, const ['createdAt', 'created_at', 'timestamp', 'time'])),
            ))
        .toList(growable: false);
  }

  static String _vehicleType(Map<String, Object?> json) {
    final nested = _mapOf(json['vehicleType']);
    final fromNested = _text(_first(nested, const ['name', 'title', 'type', 'slug']));
    if (fromNested.isNotEmpty) return fromNested;
    return _text(_first(json, const ['type', 'vehicleType', 'vehicleTypeName', 'vehicle_type_name']));
  }

  static Map<String, Object?> _mapOf(Object? value) {
    if (value is Map<String, Object?>) return value;
    if (value is Map) return <String, Object?>{for (final entry in value.entries) entry.key.toString(): entry.value};
    return const <String, Object?>{};
  }

  static Object? _first(Map<String, Object?> source, List<String> keys) {
    for (final key in keys) {
      if (!source.containsKey(key)) continue;
      final value = source[key];
      if (value == null) continue;
      if (value is String && value.trim().isEmpty) continue;
      return value;
    }
    return null;
  }

  static String _text(Object? value) => value?.toString().trim() ?? '';
  static String _status(Object? value) {
    if (value is bool) return value ? 'Active' : 'Inactive';
    if (value is num) return value != 0 ? 'Active' : 'Inactive';
    final text = _text(value);
    if (text.isEmpty) return '';
    final lower = text.toLowerCase();
    if (lower == 'true' || lower == '1' || lower == 'enabled') return 'Active';
    if (lower == 'false' || lower == '0' || lower == 'disabled') return 'Inactive';
    return text;
  }
  static bool _bool(Object? value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = _text(value).toLowerCase();
    if (text.isEmpty) return defaultValue;
    return text == 'true' || text == '1' || text == 'active' || text == 'running' || text == 'enabled';
  }
}
