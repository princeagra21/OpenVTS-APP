import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/features/admin/data/models/admin_team_dtos.dart';
import 'package:open_vts/features/admin/domain/entities/admin_team_list_item.dart';

class AdminTeamMapper {
  const AdminTeamMapper();

  List<AdminTeamDto> teamsFromResponse(Object? response) {
    return ApiResponseNormalizer.listOf(
      response,
      preferredKeys: const ['teamslist', 'teamlist', 'teams', 'items', 'results'],
    ).map(_dtoOrNull).whereType<AdminTeamDto>().toList(growable: false);
  }

  AdminTeamDto? teamFromResponse(Object? response) {
    final map = ApiResponseNormalizer.mapPayloadOf(
      response,
      preferredKeys: const ['team', 'item', 'result'],
    );
    return map.isEmpty ? null : AdminTeamDto.fromJson(map);
  }

  AdminTeamListItem listItem(AdminTeamDto dto) {
    return AdminTeamListItem.fromRaw(_dynamicMap(dto.json));
  }

  AdminTeamListItem withActive(AdminTeamListItem item, bool isActive) {
    final raw = Map<String, dynamic>.from(item.raw);
    raw['isActive'] = isActive;
    raw['active'] = isActive;
    raw['enabled'] = isActive;
    return AdminTeamListItem.fromRaw(raw);
  }

  AdminTeamDto? _dtoOrNull(Object? value) {
    final map = _mapOrNull(value);
    return map == null ? null : AdminTeamDto.fromJson(map);
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
