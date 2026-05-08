import 'dart:convert';

import 'package:open_vts/core/repositories/auth_repository.dart';
import 'package:open_vts/core/storage/token_storage.dart';

class SessionService {
  SessionService({required TokenStorageBase tokenStorage})
    : _tokenStorage = tokenStorage;

  final TokenStorageBase _tokenStorage;

  Future<String?> readAccessToken() => _tokenStorage.readAccessToken();

  Future<String?> readRefreshToken() => _tokenStorage.readRefreshToken();

  Future<void> logout() async {
    final impersonatorToken = await _tokenStorage.popImpersonatorToken();
    if (impersonatorToken != null && impersonatorToken.trim().isNotEmpty) {
      await _tokenStorage.writeAccessToken(impersonatorToken.trim());
      await _tokenStorage.clearRefreshToken();
      return;
    }
    await _tokenStorage.clear();
  }

  Future<void> clearSession() => _tokenStorage.clear();

  Future<bool> hasValidAccessToken() async {
    final token = await readAccessToken();
    if (token == null || token.trim().isEmpty) {
      return false;
    }
    return !_isExpired(token);
  }

  Future<String?> roleFromCurrentToken() async {
    final token = await readAccessToken();
    if (token == null || token.trim().isEmpty) {
      return null;
    }
    return AuthRepository.extractRole(null, token: token)?.trim();
  }

  Future<void> startImpersonation(String impersonatedAccessToken) async {
    final nextToken = impersonatedAccessToken.trim();
    if (nextToken.isEmpty) {
      return;
    }

    final currentToken = await readAccessToken();
    if (currentToken != null && currentToken.trim().isNotEmpty) {
      await _tokenStorage.writeImpersonatorToken(currentToken.trim());
    }

    await _tokenStorage.writeAccessToken(nextToken);
  }

  bool _isExpired(String token) {
    final payload = _decodeJwtPayload(token);
    if (payload == null) {
      return false;
    }

    final expRaw = payload['exp'];
    int? expSeconds;
    if (expRaw is int) {
      expSeconds = expRaw;
    } else if (expRaw is num) {
      expSeconds = expRaw.toInt();
    } else if (expRaw is String) {
      expSeconds = int.tryParse(expRaw);
    }

    if (expSeconds == null) {
      return false;
    }

    final expiry = DateTime.fromMillisecondsSinceEpoch(
      expSeconds * 1000,
      isUtc: true,
    );

    return DateTime.now().toUtc().isAfter(expiry);
  }

  Map<String, dynamic>? _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length < 2) {
      return null;
    }

    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded.cast());
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}
