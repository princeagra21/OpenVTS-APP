class UserRouteDto {
  const UserRouteDto(this.json);
  final Map<String, Object?> json;
}

class UserRouteMutationDto {
  const UserRouteMutationDto(this.body);
  final Map<String, Object?> body;

  Map<String, Object?> toJson() => body;
}
