import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class TokenStorageBase {
  Future<String?> readAccessToken();

  Future<void> writeAccessToken(String token);

  Future<String?> readImpersonatorToken();

  Future<void> writeImpersonatorToken(String token);

  Future<void> clearImpersonatorToken();

  Future<void> clear();
}

class TokenStorage implements TokenStorageBase {
  static const _kAccessTokenKey = 'access_token';
  static const _kImpersonatorTokenKey = 'impersonator_access_token';

  final FlutterSecureStorage _storage;

  const TokenStorage(this._storage);

  static TokenStorage defaultInstance() {
    // Defaults are fine for most mobile targets.
    return TokenStorage(const FlutterSecureStorage());
  }

  @override
  Future<String?> readAccessToken() => _storage.read(key: _kAccessTokenKey);

  @override
  Future<void> writeAccessToken(String token) =>
      _storage.write(key: _kAccessTokenKey, value: token);

  @override
  Future<String?> readImpersonatorToken() =>
      _storage.read(key: _kImpersonatorTokenKey);

  @override
  Future<void> writeImpersonatorToken(String token) =>
      _storage.write(key: _kImpersonatorTokenKey, value: token);

  @override
  Future<void> clearImpersonatorToken() async {
    await _storage.delete(key: _kImpersonatorTokenKey);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _kAccessTokenKey);
    await _storage.delete(key: _kImpersonatorTokenKey);
  }
}
