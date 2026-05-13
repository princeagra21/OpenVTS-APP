import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/features/reference_data/domain/entities/reference_options.dart';
import 'package:open_vts/features/user/data/models/user_vehicle_form_dtos.dart';

class UserVehicleFormMapper {
  const UserVehicleFormMapper();

  List<UserVehicleTypeDto> vehicleTypesFromResponse(Object? raw) {
    return ApiResponseNormalizer.listOf(
      raw,
      preferredKeys: const <String>['types', 'vehicleTypes'],
    ).map(_vehicleTypeDto).toList(growable: false);
  }

  ReferenceOption vehicleType(UserVehicleTypeDto dto) {
    String first(List<String> keys) {
      for (final key in keys) {
        final value = dto.raw[key]?.toString().trim() ?? '';
        if (value.isNotEmpty && value.toLowerCase() != 'null') return value;
      }
      return '';
    }

    return ReferenceOption(
      value: first(const ['id', 'value', 'code', 'vehicleTypeId']),
      label: first(const ['name', 'label', 'title', 'type']),
    );
  }

  UserVehicleTypeDto _vehicleTypeDto(Object? value) {
    if (value is UserVehicleTypeDto) return value;
    return UserVehicleTypeDto.fromJson(ApiResponseNormalizer.mapOf(value));
  }
}
