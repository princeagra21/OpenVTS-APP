class AdminDriverDto {
  const AdminDriverDto(this.json);

  final Map<String, Object?> json;

  factory AdminDriverDto.fromJson(Map<String, Object?> json) {
    return AdminDriverDto(Map<String, Object?>.unmodifiable(json));
  }
}

class AdminDriverUpdateRequestDto {
  const AdminDriverUpdateRequestDto({required this.isActive});

  final bool isActive;

  Map<String, Object?> toStatusJson() => <String, Object?>{
        // Preserve the backend/Postman lower-case key used by the legacy flow.
        'isactive': isActive.toString(),
      };
}

class AdminDriverUserLinkRequestDto {
  const AdminDriverUserLinkRequestDto({required this.userId});

  final int userId;

  Map<String, Object?> toJson() => <String, Object?>{'userId': userId};
}
