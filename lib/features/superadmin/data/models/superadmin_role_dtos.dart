class SuperadminRoleDto {
  const SuperadminRoleDto(this.json);
  final Map<String, Object?> json;
  factory SuperadminRoleDto.fromJson(Map<String, Object?> json) => SuperadminRoleDto(Map<String, Object?>.unmodifiable(json));
}


class SuperadminRoleMutationDto {
  const SuperadminRoleMutationDto(this.values);

  final Map<String, Object?> values;

  Map<String, Object?> toJson() => Map<String, Object?>.from(values);
}
