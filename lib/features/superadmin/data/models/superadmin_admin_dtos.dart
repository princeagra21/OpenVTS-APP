class SuperadminAdminDto {
  const SuperadminAdminDto(this.json);
  final Map<String, Object?> json;
  factory SuperadminAdminDto.fromJson(Map<String, Object?> json) => SuperadminAdminDto(Map<String, Object?>.unmodifiable(json));
}

class SuperadminAdminMutationDto {
  const SuperadminAdminMutationDto(this.fields);
  final Map<String, Object?> fields;
  Map<String, Object?> toJson() => Map<String, Object?>.from(fields);
}

class SuperadminAdminStatusDto {
  const SuperadminAdminStatusDto({required this.isActive});
  final bool isActive;
  Map<String, Object?> toPrimaryJson() => <String, Object?>{'isActive': isActive};
  Map<String, Object?> toFallbackJson(String adminId) => <String, Object?>{'adminid': adminId, 'status': isActive};
}


class SuperadminCompanyMutationDto {
  const SuperadminCompanyMutationDto(this.fields);

  final Map<String, Object?> fields;

  Map<String, Object?> toJson() => Map<String, Object?>.from(fields);
}
