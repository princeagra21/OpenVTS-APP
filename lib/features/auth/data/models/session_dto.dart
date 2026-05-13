class SessionDto {
  const SessionDto({
    required this.accessToken,
    this.refreshToken,
    this.role,
    this.user = const <String, Object?>{},
  });

  final String accessToken;
  final String? refreshToken;
  final String? role;
  final Map<String, Object?> user;
}
