import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/features/admin/data/models/admin_driver_dtos.dart';
import 'package:open_vts/features/admin/domain/entities/admin_document_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_details.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_list_item.dart';

class AdminDriverMapper {
  const AdminDriverMapper();

  List<AdminDriverDto> driversFromResponse(Object? response) {
    return ApiResponseNormalizer.listOf(
      response,
      preferredKeys: const ['driverslist', 'driverlist', 'drivers'],
    ).map(_dtoOrNull).whereType<AdminDriverDto>().toList(growable: false);
  }

  AdminDriverDto? driverFromResponse(Object? response) {
    final map = ApiResponseNormalizer.mapPayloadOf(
      response,
      preferredKeys: const ['driver', 'item', 'result', 'config', 'settings'],
    );
    return map.isEmpty ? null : AdminDriverDto.fromJson(map);
  }

  List<AdminDocumentItem> documentsFromResponse(Object? response) {
    return ApiResponseNormalizer.listOf(
      response,
      preferredKeys: const ['documents', 'docs', 'files', 'items', 'results'],
    ).map(_mapOrNull).whereType<Map<String, Object?>>().map((e) => AdminDocumentItem(_dynamicMap(e))).toList(growable: false);
  }

  List<AdminUserListItem> usersFromResponse(Object? response) {
    return ApiResponseNormalizer.listOf(
      response,
      preferredKeys: const ['userslist', 'userlist', 'users', 'linkedUsers', 'unlinkedUsers'],
    ).map(_mapOrNull).whereType<Map<String, Object?>>().map((e) => AdminUserListItem(_dynamicMap(e))).toList(growable: false);
  }

  AdminDriverListItem listItem(AdminDriverDto dto) {
    return AdminDriverListItem(_dynamicMap(dto.json));
  }

  AdminDriverDetails details(AdminDriverDto dto) {
    return AdminDriverDetails(_dynamicMap(dto.json));
  }

  AdminDriverListItem withActive(AdminDriverListItem item, bool isActive) {
    final raw = Map<String, dynamic>.from(item.raw);
    raw['isactive'] = isActive;
    raw['isActive'] = isActive;
    raw['active'] = isActive;
    raw['enabled'] = isActive;
    raw['status'] = isActive ? 'Active' : 'Inactive';
    return AdminDriverListItem.fromRaw(raw);
  }

  AdminDriverDto? _dtoOrNull(Object? value) {
    final map = _mapOrNull(value);
    return map == null ? null : AdminDriverDto.fromJson(map);
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
