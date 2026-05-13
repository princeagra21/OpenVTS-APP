class SuperadminSettingsDto {
  const SuperadminSettingsDto(this.json);
  final Map<String, Object?> json;
  factory SuperadminSettingsDto.fromJson(Map<String, Object?> json) => SuperadminSettingsDto(Map<String, Object?>.unmodifiable(json));
}


class SuperadminSettingsMutationDto {
  const SuperadminSettingsMutationDto(this.values);

  final Map<String, Object?> values;

  Map<String, Object?> toJson() => Map<String, Object?>.from(values);
}
