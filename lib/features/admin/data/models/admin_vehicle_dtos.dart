class AdminVehicleDto {
  const AdminVehicleDto(this.json);

  final Map<String, Object?> json;

  factory AdminVehicleDto.fromJson(Map<String, Object?> json) {
    return AdminVehicleDto(Map<String, Object?>.unmodifiable(json));
  }
}

class AdminVehicleLogDto {
  const AdminVehicleLogDto(this.json);

  final Map<String, Object?> json;

  factory AdminVehicleLogDto.fromJson(Map<String, Object?> json) {
    return AdminVehicleLogDto(Map<String, Object?>.unmodifiable(json));
  }
}

class UpdateAdminVehicleStatusRequestDto {
  const UpdateAdminVehicleStatusRequestDto({required this.isActive});

  final bool isActive;

  Map<String, Object?> toJson() => <String, Object?>{'isActive': isActive};
}

class AdminVehicleDriverAssignmentRequestDto {
  const AdminVehicleDriverAssignmentRequestDto({required this.driverId});

  final String driverId;

  Map<String, Object?> toJson() => <String, Object?>{
        'driverId': _toNumOrString(driverId.trim()),
      };
}

Object _toNumOrString(String value) {
  final parsed = int.tryParse(value);
  return parsed ?? value;
}


class AdminVehicleConfigUpdateRequestDto {
  const AdminVehicleConfigUpdateRequestDto(this.values);

  final Map<String, Object?> values;

  Map<String, Object?> toJson() => Map<String, Object?>.from(values);
}
