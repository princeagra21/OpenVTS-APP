class UserNotificationDto {
  const UserNotificationDto(this.json);
  final Map<String, Object?> json;
}

class UserNotificationPreferencesDto {
  const UserNotificationPreferencesDto(this.json);
  final Map<String, Object?> json;
}

class UserNotificationPreferencesMutationDto {
  const UserNotificationPreferencesMutationDto(this.body);
  final Map<String, Object?> body;

  Map<String, Object?> toJson() => body;
}
