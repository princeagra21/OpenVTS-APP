class SettingsUpdateRequestDto {
  const SettingsUpdateRequestDto(this.values);

  final Map<String, Object?> values;

  Map<String, Object?> toJson() => Map<String, Object?>.from(values);
}
