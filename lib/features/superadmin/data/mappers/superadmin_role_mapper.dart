import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/features/superadmin/data/models/superadmin_role_dtos.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_settings.dart';

class SuperadminRoleMapper {
  const SuperadminRoleMapper();

  List<SuperadminRoleDto> rolesFromResponse(Object? response) {
    final rawRoles = ApiResponseNormalizer.listOf(response, preferredKeys: const ['roles', 'items', 'rows', 'permissions']);
    final seen = <String>{};
    final out = <SuperadminRoleDto>[];
    for (final raw in rawRoles) {
      final map = _mapOf(raw);
      if (map.isEmpty) continue;
      final mappedRole = role(SuperadminRoleDto.fromJson(map));
      if (mappedRole.title.trim().isEmpty) continue;
      final fingerprint = '${mappedRole.key.toLowerCase()}|${mappedRole.title.toLowerCase()}';
      if (!seen.add(fingerprint)) continue;
      out.add(SuperadminRoleDto.fromJson(map));
    }
    if (out.isNotEmpty) return out;
    final single = ApiResponseNormalizer.mapPayloadOf(response, preferredKeys: const ['role', 'data']);
    return single.isEmpty ? const <SuperadminRoleDto>[] : <SuperadminRoleDto>[SuperadminRoleDto.fromJson(single)];
  }

  SuperadminRole role(SuperadminRoleDto dto) {
    final raw = dto.json;
    final roleMap = _mapOf(raw['role']);
    final dataMap = _mapOf(raw['data']);
    final merged = <String, Object?>{...raw, ...dataMap, ...roleMap};
    final title = _text(_first(merged, const ['name', 'title', 'roleName', 'role', 'label']));
    final key = _text(_first(merged, const ['id', 'roleId', 'uid', 'code', 'slug']));
    final currency = _text(_first(merged, const ['currency', 'billingCurrency', 'priceCurrency', 'costCurrency'])).toUpperCase();
    final amount = _int(_first(merged, const ['monthlyCost', 'amount', 'price', 'cost', 'monthly_price']));
    final permissionSource = merged['permissions'] ?? merged['permission'] ?? merged['access'] ?? merged['modules'] ?? merged['rights'];
    return SuperadminRole(
      key: key.isNotEmpty ? key : title,
      title: title,
      currency: currency,
      amount: amount,
      permissions: _parsePermissions(permissionSource),
    );
  }

  List<SuperadminRole> roleList(Object? response) => rolesFromResponse(response).map(role).toList(growable: false);

  Map<String, Object?> updatePayload(SuperadminRoleMutationInput input) => input.toJson();

  Map<String, int> _parsePermissions(Object? raw) {
    final out = <String, int>{};
    if (raw is Map) {
      final map = _mapOf(raw);
      map.forEach((module, value) {
        final name = module.trim();
        if (name.isEmpty) return;
        out[name] = _permissionLevelFromAny(value);
      });
      return out;
    }
    if (raw is List) {
      for (final item in raw) {
        final map = _mapOf(item);
        if (map.isEmpty) continue;
        final module = _text(_first(map, const ['module', 'name', 'key', 'resource', 'title']));
        if (module.isEmpty) continue;
        final level = _permissionLevelFromAny(map['level'] ?? map['access'] ?? map['permission'] ?? map['value']);
        out[module] = level;
      }
    }
    return out;
  }

  int _permissionLevelFromAny(Object? value) {
    if (value == null) return 0;
    if (value is int) return value.clamp(0, 4).toInt();
    if (value is num) return value.toInt().clamp(0, 4).toInt();
    if (value is bool) return value ? 1 : 0;
    if (value is Map) {
      final map = _mapOf(value);
      if (_truthy(map['full']) || _truthy(map['all']) || _truthy(map['owner']) || _truthy(map['superadmin'])) return 4;
      if (_truthy(map['manage']) || _truthy(map['admin'])) return 3;
      if (_truthy(map['edit']) || _truthy(map['write']) || _truthy(map['update'])) return 2;
      if (_truthy(map['view']) || _truthy(map['read']) || _truthy(map['access'])) return 1;
      return _permissionLevelFromAny(map['level'] ?? map['value']);
    }
    final text = _text(value).toLowerCase();
    if (const {'none', 'no', 'deny', 'denied', '0', 'false'}.contains(text)) return 0;
    if (const {'view', 'read', 'viewer', 'readonly', '1', 'true'}.contains(text)) return 1;
    if (const {'edit', 'write', 'update', '2'}.contains(text)) return 2;
    if (const {'manage', 'manager', 'admin', '3'}.contains(text)) return 3;
    if (const {'full', 'all', 'owner', 'superadmin', '4'}.contains(text)) return 4;
    return int.tryParse(text)?.clamp(0, 4).toInt() ?? 0;
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
  static int _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(_text(value).replaceAll(',', '')) ?? 0;
  }
  static bool _truthy(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    return const {'true', '1', 'yes', 'y'}.contains(_text(value).toLowerCase());
  }
}
