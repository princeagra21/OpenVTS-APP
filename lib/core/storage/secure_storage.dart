import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:open_vts/core/storage/token_storage.dart';

/// Architecture-approved secure storage wrapper.
///
/// It delegates token operations to the existing production-tested TokenStorage
/// so old and new modules share one session source of truth.
class SecureStorage {
  SecureStorage({TokenStorageBase? tokenStorage})
      : _tokenStorage = tokenStorage ?? TokenStorage.defaultInstance();

  final TokenStorageBase _tokenStorage;
  static const FlutterSecureStorage raw = FlutterSecureStorage();

  String? _cachedAccessToken;

  Future<String?> getAccessToken() async =>
      _cachedAccessToken ??= await _tokenStorage.readAccessToken();

  String? getCachedToken() => _cachedAccessToken;

  Future<String?> getRefreshToken() => _tokenStorage.readRefreshToken();

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    _cachedAccessToken = accessToken;
    await _tokenStorage.writeAccessToken(accessToken);
    if (refreshToken != null && refreshToken.trim().isNotEmpty) {
      await _tokenStorage.writeRefreshToken(refreshToken);
    }
  }

  Future<void> clearAll() async {
    _cachedAccessToken = null;
    await _tokenStorage.clear();
  }
}
