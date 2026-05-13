class CacheKeyBuilder {
  const CacheKeyBuilder({
    required this.environmentKey,
    required this.role,
    required this.accountId,
    required this.userId,
  });

  final String environmentKey;
  final String role;
  final String accountId;
  final String userId;

  String feature(String feature, String key) {
    final parts = <String>[
      _safe(environmentKey),
      _safe(role),
      _safe(accountId),
      _safe(userId),
      _safe(feature),
      _safe(key),
    ];
    return parts.join(':');
  }

  String _safe(String input) {
    final value = input.trim().isEmpty ? 'unknown' : input.trim();
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_\-:.]'), '_');
  }
}
