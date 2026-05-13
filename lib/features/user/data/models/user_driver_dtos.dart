class UserDriverDto {
  const UserDriverDto(this.json);
  final Map<String, Object?> json;
}

class UserDriverMutationDto {
  const UserDriverMutationDto(this.body);
  final Map<String, Object?> body;

  Map<String, Object?> toJson() => body;
}
