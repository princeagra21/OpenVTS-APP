import 'package:open_vts/core/storage/secure_storage.dart';

class AuthLocalSource {
  const AuthLocalSource(this.storage);

  final SecureStorage storage;

  Future<String?> getAccessToken() => storage.getAccessToken();
  Future<String?> getRefreshToken() => storage.getRefreshToken();
  Future<void> clear() => storage.clearAll();
}
