import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/features/user/data/models/user_vehicle_dtos.dart';
import 'package:open_vts/features/user/domain/entities/user_vehicle_details.dart';

class UserVehicleMapper {
  const UserVehicleMapper();

  UserVehicleDto? detailFromResponse(Object? response) {
    final map = ApiResponseNormalizer.mapPayloadOf(
      response,
      preferredKeys: const ['vehicle', 'details', 'item'],
    );
    return map.isEmpty ? null : UserVehicleDto(map);
  }

  UserVehicleDetails details(UserVehicleDto dto) => UserVehicleDetails.fromRaw(_dynamicMap(dto.json));

  static Map<String, dynamic> _dynamicMap(Map<String, Object?> value) => <String, dynamic>{for (final entry in value.entries) entry.key: entry.value};
}
