class ForgotPasswordRequestDto {
  const ForgotPasswordRequestDto({required this.identifier});

  final String identifier;

  Map<String, Object?> toJson() => <String, Object?>{
        'email': identifier.trim(),
        'identifier': identifier.trim(),
      };
}

class RefreshTokenRequestDto {
  const RefreshTokenRequestDto({required this.refreshToken});

  final String refreshToken;

  Map<String, Object?> toJson() => <String, Object?>{
        'refreshToken': refreshToken,
        'refresh_token': refreshToken,
      };
}
