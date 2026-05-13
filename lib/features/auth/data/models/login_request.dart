class LoginRequest {
  const LoginRequest({required this.identifier, required this.password});

  final String identifier;
  final String password;

  Map<String, Object?> toJson() => <String, Object?>{
        'identifier': identifier.trim(),
        'password': password,
      };
}
