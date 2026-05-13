import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/features/user/data/models/user_sub_user_dtos.dart';
import 'package:open_vts/features/user/domain/entities/user_subuser_item.dart';

class UserSubUserMapper {
  const UserSubUserMapper();

  List<UserSubUserDto> listFromResponse(Object? response) {
    return ApiResponseNormalizer.listOf(
      response,
      preferredKeys: const ['subusers', 'subUsers', 'users', 'items', 'rows'],
    ).whereType<Map>().map((item) => UserSubUserDto(_map(item))).toList(growable: false);
  }

  UserSubUserDto? detailFromResponse(Object? response) {
    final map = ApiResponseNormalizer.mapPayloadOf(
      response,
      preferredKeys: const ['subuser', 'subUser', 'user', 'item'],
    );
    return map.isEmpty ? null : UserSubUserDto(map);
  }

  List<Map<String, Object?>> vehiclesFromResponse(Object? response) {
    return ApiResponseNormalizer.listOf(
      response,
      preferredKeys: const ['vehicles', 'assignedVehicles', 'items', 'rows'],
    ).whereType<Map>().map(_map).toList(growable: false);
  }

  UserSubUserItem toDomain(UserSubUserDto dto) => UserSubUserItem(_dynamicMap(dto.json));

  UserSubUserMutationDto mutation(Map<String, Object?> body) => UserSubUserMutationDto(body);

  static Map<String, Object?> _map(Map value) => <String, Object?>{for (final entry in value.entries) entry.key.toString(): entry.value};
  static Map<String, dynamic> _dynamicMap(Map<String, Object?> value) => <String, dynamic>{for (final entry in value.entries) entry.key: entry.value};
}
