import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class TokenStorageBase {
  Future<String?> readAccessToken();

  Future<void> writeAccessToken(String token);

  Future<String?> readImpersonatorToken();

  Future<void> writeImpersonatorToken(String token);

  Future<String?> popImpersonatorToken();

  Future<void> clearImpersonatorToken();

  Future<void> clear();
}

class TokenStorage implements TokenStorageBase {
  static const _kAccessTokenKey = 'access_token';
  static const _kImpersonatorTokenKey = 'impersonator_access_token';
  static const _kImpersonatorStackKey = 'impersonator_access_token_stack';

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
  Future<String?> readImpersonatorToken() async {
    final stack = await _readImpersonatorStack();
    if (stack.isNotEmpty) return stack.last;

    final legacy = await _storage.read(key: _kImpersonatorTokenKey);
    if (legacy != null && legacy.trim().isNotEmpty) return legacy;
    return null;
  }

  @override
  Future<void> writeImpersonatorToken(String token) async {
    final normalized = token.trim();
    if (normalized.isEmpty) return;
    final stack = await _readImpersonatorStack();
    stack.add(normalized);
    await _writeImpersonatorStack(stack);
  }

  @override
  Future<String?> popImpersonatorToken() async {
    final stack = await _readImpersonatorStack();
    if (stack.isEmpty) {
      final legacy = await _storage.read(key: _kImpersonatorTokenKey);
      if (legacy == null || legacy.trim().isEmpty) return null;
      await clearImpersonatorToken();
      return legacy;
    }

    final popped = stack.removeLast();
    await _writeImpersonatorStack(stack);
    return popped;
  }

  @override
  Future<void> clearImpersonatorToken() async {
    await _storage.delete(key: _kImpersonatorTokenKey);
    await _storage.delete(key: _kImpersonatorStackKey);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _kAccessTokenKey);
    await _storage.delete(key: _kImpersonatorTokenKey);
    await _storage.delete(key: _kImpersonatorStackKey);
  }

  Future<List<String>> _readImpersonatorStack() async {
    final raw = await _storage.read(key: _kImpersonatorStackKey);
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } catch (_) {
        // Fall through to legacy token handling.
      }
    }

    final legacy = await _storage.read(key: _kImpersonatorTokenKey);
    if (legacy != null && legacy.trim().isNotEmpty) {
      return <String>[legacy.trim()];
    }
    return <String>[];
  }

  Future<void> _writeImpersonatorStack(List<String> stack) async {
    if (stack.isEmpty) {
      await _storage.delete(key: _kImpersonatorStackKey);
      await _storage.delete(key: _kImpersonatorTokenKey);
      return;
    }
    await _storage.write(
      key: _kImpersonatorStackKey,
      value: jsonEncode(stack),
    );
    await _storage.delete(key: _kImpersonatorTokenKey);
  }
}
