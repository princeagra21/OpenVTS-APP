import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/features/admin/data/models/admin_vehicle_dtos.dart';
import 'package:open_vts/features/admin/domain/entities/admin_document_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_vehicle_details.dart';
import 'package:open_vts/features/admin/domain/entities/admin_vehicle_log_item.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_config.dart';

class AdminVehicleMapper {
  const AdminVehicleMapper();

  AdminVehicleDto? vehicleFromResponse(Object? response) {
    final map = ApiResponseNormalizer.mapPayloadOf(
      response,
      preferredKeys: const ['vehicle', 'item', 'result', 'payload'],
    );
    return map.isEmpty ? null : AdminVehicleDto.fromJson(map);
  }

  AdminVehicleDetails details(AdminVehicleDto dto) {
    return AdminVehicleDetails.fromRaw(_dynamicMap(dto.json));
  }

  List<AdminUserListItem> linkedUsersFromResponse(Object? response) {
    return ApiResponseNormalizer.listOf(
      response,
      preferredKeys: const ['userslist', 'userlist', 'users', 'linkedUsers', 'rows', 'items'],
    ).map(_mapOrNull).whereType<Map<String, Object?>>().map((e) => AdminUserListItem(_dynamicMap(e))).toList(growable: false);
  }

  List<AdminDocumentItem> documentsFromResponse(Object? response) {
    return ApiResponseNormalizer.listOf(
      response,
      preferredKeys: const ['documents', 'docs', 'files', 'items', 'rows'],
    ).map(_mapOrNull).whereType<Map<String, Object?>>().map((e) => AdminDocumentItem(_dynamicMap(e))).toList(growable: false);
  }

  VehicleConfig? configFromResponse(Object? response) {
    final map = ApiResponseNormalizer.mapPayloadOf(
      response,
      preferredKeys: const ['config', 'vehicleConfig', 'settings', 'data'],
    );
    return map.isEmpty ? null : VehicleConfig(_dynamicMap(map));
  }

  List<AdminVehicleLogItem> logsFromResponse(Object? response) {
    return ApiResponseNormalizer.listOf(
      response,
      preferredKeys: const ['items', 'logs', 'rows', 'data'],
    ).map(_mapOrNull).whereType<Map<String, Object?>>().map(logItem).toList(growable: false);
  }

  AdminVehicleLogItem logItem(Map<String, Object?> map) {
    String s(Object? value) => value == null ? '' : value.toString();
    String b(Object? value) {
      if (value == null) return '';
      if (value is bool) return value ? 'Yes' : 'No';
      return value.toString();
    }

    return AdminVehicleLogItem(
      id: s(map['id']),
      imei: s(map['imei']),
      packetType: s(map['packetType']),
      deviceTime: s(map['deviceTime']),
      latitude: s(map['latitude']),
      longitude: s(map['longitude']),
      ignition: b(map['ignition']),
      acc: b(map['acc']),
      valid: b(map['valid']),
    );
  }

  static Map<String, Object?>? _mapOrNull(Object? value) {
    if (value is Map<String, Object?>) return value;
    if (value is Map) {
      return <String, Object?>{for (final entry in value.entries) entry.key.toString(): entry.value};
    }
    return null;
  }

  static Map<String, dynamic> _dynamicMap(Map<String, Object?> value) {
    return <String, dynamic>{for (final entry in value.entries) entry.key: entry.value};
  }
}
