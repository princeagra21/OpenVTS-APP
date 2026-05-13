class AdminTeamDto {
  const AdminTeamDto(this.json);

  final Map<String, Object?> json;

  factory AdminTeamDto.fromJson(Map<String, Object?> json) {
    return AdminTeamDto(Map<String, Object?>.unmodifiable(json));
  }
}

class CreateAdminTeamRequestDto {
  const CreateAdminTeamRequestDto({
    required this.name,
    required this.email,
    required this.mobilePrefix,
    required this.mobileNumber,
    required this.username,
    required this.password,
  });

  final String name;
  final String email;
  final String mobilePrefix;
  final String mobileNumber;
  final String username;
  final String password;

  Map<String, Object?> toJson() => <String, Object?>{
        'name': name.trim(),
        'email': email.trim(),
        'mobilePrefix': mobilePrefix.trim(),
        'mobileNumber': mobileNumber.trim(),
        'username': username.trim(),
        'password': password,
      };
}

class UpdateAdminTeamRequestDto {
  const UpdateAdminTeamRequestDto({
    required this.name,
    required this.email,
    required this.mobilePrefix,
    required this.mobileNumber,
    required this.username,
  });

  final String name;
  final String email;
  final String mobilePrefix;
  final String mobileNumber;
  final String username;

  Map<String, Object?> toJson() => <String, Object?>{
        'name': name.trim(),
        'email': email.trim(),
        'mobilePrefix': mobilePrefix.trim(),
        'mobileNumber': mobileNumber.trim(),
        'username': username.trim(),
      };
}

class UpdateAdminTeamStatusRequestDto {
  const UpdateAdminTeamStatusRequestDto({required this.isActive});

  final bool isActive;

  Map<String, Object?> toJson() => <String, Object?>{'isActive': isActive};
}

class UpdateAdminTeamPasswordRequestDto {
  const UpdateAdminTeamPasswordRequestDto({required this.password});

  final String password;

  Map<String, Object?> toJson() => <String, Object?>{'password': password};
}


class AdminTeamMutationRequestDto {
  const AdminTeamMutationRequestDto(this.values);

  final Map<String, Object?> values;

  factory AdminTeamMutationRequestDto.fromJson(Map<String, Object?> values) {
    return AdminTeamMutationRequestDto(Map<String, Object?>.from(values));
  }

  Map<String, Object?> toJson() => Map<String, Object?>.from(values);
}
