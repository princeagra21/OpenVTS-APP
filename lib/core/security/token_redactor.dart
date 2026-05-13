/// Central redaction utility for logs, diagnostics, breadcrumbs, and crash
/// context. Keep this class dependency-free so it can be used from every layer.
class TokenRedactor {
  const TokenRedactor();

  static const String redacted = '[REDACTED]';

  static const Set<String> _exactSensitiveKeys = <String>{
    'authorization',
    'access_token',
    'access-token',
    'accessToken',
    'refresh_token',
    'refresh-token',
    'refreshToken',
    'id_token',
    'id-token',
    'idToken',
    'token',
    'password',
    'newPassword',
    'oldPassword',
    'confirmPassword',
    'otp',
    'pin',
    'secret',
    'apiKey',
    'api_key',
    'privateKey',
    'private_key',
    'clientSecret',
    'client_secret',
    'cookie',
    'set-cookie',
    'email',
    'phone',
    'mobile',
    'address',
    'street',
    'fullName',
    'full_name',
    'latitude',
    'longitude',
    'lat',
    'lng',
  };

  static const List<String> _sensitiveFragments = <String>[
    'token',
    'password',
    'authorization',
    'secret',
    'apikey',
    'api_key',
    'privatekey',
    'private_key',
    'clientsecret',
    'client_secret',
    'cookie',
    'otp',
    'private',
    'address',
    'phone',
    'mobile',
  ];

  String redact(Object? input) => _redactText(input?.toString() ?? '');

  /// Returns a log-safe representation of any object. Maps/lists are preserved
  /// structurally, while sensitive values are removed recursively.
  Object? sanitize(Object? value) {
    if (value == null) return null;
    if (value is Map) {
      return value.map<String, Object?>(
        (key, entryValue) {
          final keyText = key.toString();
          return MapEntry(
            redact(keyText),
            _isSensitiveKey(keyText) ? redacted : sanitize(entryValue),
          );
        },
      );
    }
    if (value is Iterable) {
      return value.map(sanitize).toList(growable: false);
    }
    if (value is Uri) {
      return _redactUri(value).toString();
    }
    if (value is String) return _redactText(value);
    return value;
  }

  Map<String, Object?> redactMap(Map<String, Object?> input) {
    final sanitized = sanitize(input);
    if (sanitized is Map<String, Object?>) return sanitized;
    return <String, Object?>{};
  }

  Map<String, Object?> redactHeaders(Map<String, Object?> headers) {
    return headers.map((key, value) {
      return MapEntry(
        key,
        _isSensitiveKey(key) ? redacted : sanitize(value),
      );
    });
  }

  Uri _redactUri(Uri uri) {
    if (uri.queryParameters.isEmpty) return uri;
    return uri.replace(
      queryParameters: uri.queryParameters.map((key, value) {
        return MapEntry(key, _isSensitiveKey(key) ? redacted : _redactText(value));
      }),
    );
  }

  bool _isSensitiveKey(String key) {
    final normalized = key.trim().replaceAll(RegExp(r'[\s_\-]'), '').toLowerCase();
    if (_exactSensitiveKeys.any((candidate) {
      return candidate.replaceAll(RegExp(r'[\s_\-]'), '').toLowerCase() == normalized;
    })) {
      return true;
    }
    return _sensitiveFragments.any(normalized.contains);
  }

  String _redactText(String text) {
    if (text.isEmpty) return text;
    var output = text;

    // PEM private keys and key-like blocks.
    output = output.replaceAll(
      RegExp(
        r'-----BEGIN [^-]*PRIVATE KEY-----[\s\S]*?-----END [^-]*PRIVATE KEY-----',
        caseSensitive: false,
      ),
      redacted,
    );

    // Authorization header and bearer tokens.
    output = output.replaceAll(
      RegExp(r'Bearer\s+[A-Za-z0-9\-\._~\+\/=]+', caseSensitive: false),
      'Bearer $redacted',
    );

    // JSON-style sensitive keys: "password":"value" and 'password':'value'.
    output = output.replaceAllMapped(
      RegExp(
        r'''(["'])(accessToken|refreshToken|access_token|refresh_token|idToken|id_token|token|password|oldPassword|newPassword|confirmPassword|otp|pin|secret|apiKey|api_key|privateKey|private_key|clientSecret|client_secret|authorization|cookie|email|phone|mobile|address|street|fullName|full_name|latitude|longitude|lat|lng)\1\s*:\s*(["'])(.*?)\3''',
        caseSensitive: false,
      ),
      (match) => '${match.group(1)}${match.group(2)}${match.group(1)}:$redacted',
    );

    // Dart Map.toString style: password: value, token: value.
    output = output.replaceAllMapped(
      RegExp(
        r'\b(accessToken|refreshToken|access_token|refresh_token|idToken|id_token|token|password|oldPassword|newPassword|confirmPassword|otp|pin|secret|apiKey|api_key|privateKey|private_key|clientSecret|client_secret|authorization|cookie|email|phone|mobile|address|street|fullName|full_name|latitude|longitude|lat|lng)\b\s*:\s*([^,}\]\s]+)',
        caseSensitive: false,
      ),
      (match) => '${match.group(1)}: $redacted',
    );

    // Query-string style secrets.
    output = output.replaceAllMapped(
      RegExp(
        r'([?&]|\b)(access_token|refresh_token|id_token|token|password|otp|pin|secret|api_key|client_secret|authorization|email|phone|mobile|address|lat|lng|latitude|longitude)=([^&\s]+)',
        caseSensitive: false,
      ),
      (match) => '${match.group(1)}${match.group(2)}=$redacted',
    );

    return output;
  }
}
