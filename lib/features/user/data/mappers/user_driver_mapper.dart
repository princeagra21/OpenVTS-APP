import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_list_item.dart';
import 'package:open_vts/features/user/data/models/user_driver_dtos.dart';
import 'package:open_vts/features/user/domain/entities/user_driver_details.dart';

class UserDriverMapper {
  const UserDriverMapper();

  List<UserDriverDto> listFromResponse(Object? response) {
    return ApiResponseNormalizer.listOf(
      response,
      preferredKeys: const ['drivers', 'items', 'rows'],
    ).whereType<Map>().map((item) => UserDriverDto(_map(item))).toList(growable: false);
  }

  UserDriverDto? detailFromResponse(Object? response) {
    final map = ApiResponseNormalizer.mapPayloadOf(
      response,
      preferredKeys: const ['driver', 'item'],
    );
    return map.isEmpty ? null : UserDriverDto(map);
  }

  AdminDriverListItem listItem(UserDriverDto dto) => AdminDriverListItem.fromRaw(_dynamicMap(dto.json));
  UserDriverDetails details(UserDriverDto dto) => UserDriverDetails.fromRaw(_dynamicMap(dto.json));
  UserDriverMutationDto mutation(Map<String, Object?> body) => UserDriverMutationDto(body);

  static Map<String, Object?> _map(Map value) => <String, Object?>{for (final entry in value.entries) entry.key.toString(): entry.value};
  static Map<String, dynamic> _dynamicMap(Map<String, Object?> value) => <String, dynamic>{for (final entry in value.entries) entry.key: entry.value};
}
