class UserLandmarkDto {
  const UserLandmarkDto(this.json);
  final Map<String, Object?> json;
}

class UserLandmarkMutationDto {
  const UserLandmarkMutationDto(this.body);
  final Map<String, Object?> body;

  Map<String, Object?> toJson() => body;
}
