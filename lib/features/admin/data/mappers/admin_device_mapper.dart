import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/features/admin/data/models/admin_device_dtos.dart';
import 'package:open_vts/features/admin/domain/entities/admin_device_list_item.dart';
import 'package:open_vts/features/vehicles/domain/entities/device_type_option.dart';
import 'package:open_vts/features/vehicles/domain/entities/sim_option.dart';
import 'package:open_vts/features/vehicles/domain/entities/sim_provider_option.dart';

class AdminDeviceMapper {
  const AdminDeviceMapper();

  List<AdminDeviceDto> devicesFromResponse(Object? response) {
    return ApiResponseNormalizer.listOf(
      response,
      preferredKeys: const ['devices', 'deviceslist', 'deviceList', 'items', 'results'],
    ).map(_dtoOrNull).whereType<AdminDeviceDto>().toList(growable: false);
  }

  AdminDeviceDto? deviceFromResponse(Object? response) {
    final map = ApiResponseNormalizer.mapPayloadOf(
      response,
      preferredKeys: const ['device', 'item', 'result'],
    );
    return map.isEmpty ? null : AdminDeviceDto.fromJson(map);
  }

  List<DeviceTypeOption> deviceTypesFromResponse(Object? response) {
    return ApiResponseNormalizer.listOf(
      response,
      preferredKeys: const ['devicetypes', 'deviceTypes', 'types', 'items', 'results'],
    ).map(_mapOrNull).whereType<Map<String, Object?>>().map((e) => DeviceTypeOption.fromRaw(_dynamicMap(e))).toList(growable: false);
  }

  List<SimProviderOption> simProvidersFromResponse(Object? response) {
    return ApiResponseNormalizer.listOf(
      response,
      preferredKeys: const ['simproviders', 'providers', 'items', 'results'],
    ).map(_mapOrNull).whereType<Map<String, Object?>>().map((e) => SimProviderOption.fromRaw(_dynamicMap(e))).toList(growable: false);
  }

  List<SimOption> simsFromResponse(Object? response) {
    return ApiResponseNormalizer.listOf(
      response,
      preferredKeys: const ['simcards', 'sims', 'items', 'results'],
    ).map(_mapOrNull).whereType<Map<String, Object?>>().map((e) => SimOption.fromRaw(_dynamicMap(e))).toList(growable: false);
  }

  AdminDeviceListItem listItem(AdminDeviceDto dto) {
    return AdminDeviceListItem.fromRaw(_dynamicMap(dto.json));
  }

  AdminDeviceListItem withActive(AdminDeviceListItem item, bool isActive) {
    final raw = Map<String, dynamic>.from(item.raw);
    raw['isActive'] = isActive;
    raw['active'] = isActive;
    raw['enabled'] = isActive;
    raw['status'] = isActive ? 'Active' : 'Inactive';
    return AdminDeviceListItem.fromRaw(raw);
  }

  AdminDeviceDto? _dtoOrNull(Object? value) {
    final map = _mapOrNull(value);
    return map == null ? null : AdminDeviceDto.fromJson(map);
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
