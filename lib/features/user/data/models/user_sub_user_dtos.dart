class UserSubUserDto {
  const UserSubUserDto(this.json);
  final Map<String, Object?> json;
}

class UserSubUserMutationDto {
  const UserSubUserMutationDto(this.body);
  final Map<String, Object?> body;

  Map<String, Object?> toJson() => body;
}
