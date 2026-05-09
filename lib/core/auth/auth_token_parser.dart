class AuthTokenParser {
  AuthTokenParser._();

  static const Set<String> _accessTokenKeys = <String>{'token', 'accesstoken'};

  static const Set<String> _refreshTokenKeys = <String>{'refreshtoken'};

  static const List<String> _nestedKeys = <String>[
    'data',
    'result',
    'item',
    'payload',
    'response',
  ];

  static String? extractAccessToken(Object? data) {
    return _extractToken(data, _accessTokenKeys);
  }

  static String? extractRefreshToken(Object? data) {
    return _extractToken(data, _refreshTokenKeys);
  }

  static String? _extractToken(Object? data, Set<String> acceptedKeys) {
    if (data is Map) {
      return _extractTokenFromMap(data, acceptedKeys);
    }
    if (data is List) {
      for (final item in data) {
        final token = _extractToken(item, acceptedKeys);
        if (token != null) return token;
      }
    }
    return null;
  }

  static String? _extractTokenFromMap(Map map, Set<String> acceptedKeys) {
    for (final entry in map.entries) {
      if (!acceptedKeys.contains(_normalizeKey(entry.key))) continue;
      final token = _asToken(entry.value);
      if (token != null) return token;
    }

    for (final key in _nestedKeys) {
      final nested = _valueForNormalizedKey(map, key);
      final token = _extractToken(nested, acceptedKeys);
      if (token != null) return token;
    }

    return null;
  }

  static Object? _valueForNormalizedKey(Map map, String normalizedKey) {
    for (final entry in map.entries) {
      if (_normalizeKey(entry.key) == normalizedKey) return entry.value;
    }
    return null;
  }

  static String _normalizeKey(Object? key) {
    return key
        .toString()
        .trim()
        .replaceAll('_', '')
        .replaceAll('-', '')
        .toLowerCase();
  }

  static String? _asToken(Object? value) {
    if (value is! String) return null;
    final token = value.trim();
    return token.isEmpty ? null : token;
  }
}
