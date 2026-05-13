import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/storage/cache_keys.dart';
import 'package:open_vts/core/storage/secure_storage.dart';
import 'package:open_vts/core/storage/token_storage.dart';

void main() {
  test('cache scope includes role, account, user, and environment isolation', () async {
    final tokenA = _jwt(<String, Object?>{
      'role': 'ADMIN',
      'userId': 'user-1',
      'accountId': 'account-1',
    });
    final tokenB = _jwt(<String, Object?>{
      'role': 'ADMIN',
      'userId': 'user-2',
      'accountId': 'account-1',
    });

    final resolverA = CacheScopeResolver(
      secureStorage: SecureStorage(tokenStorage: _MemoryTokenStorage(tokenA)),
      dio: Dio(BaseOptions(baseUrl: 'https://tenant-a.example.com/api')),
    );
    final resolverB = CacheScopeResolver(
      secureStorage: SecureStorage(tokenStorage: _MemoryTokenStorage(tokenB)),
      dio: Dio(BaseOptions(baseUrl: 'https://tenant-a.example.com/api')),
    );
    final resolverOtherEnvironment = CacheScopeResolver(
      secureStorage: SecureStorage(tokenStorage: _MemoryTokenStorage(tokenA)),
      dio: Dio(BaseOptions(baseUrl: 'https://tenant-b.example.com/api')),
    );

    final scopeA = await resolverA.resolve();
    final scopeB = await resolverB.resolve();
    final scopeOtherEnvironment = await resolverOtherEnvironment.resolve();

    final keyA = scopeA.keyBuilder.feature(CacheFeatureKeys.vehicleList, 'page=1');
    final keyB = scopeB.keyBuilder.feature(CacheFeatureKeys.vehicleList, 'page=1');
    final keyOtherEnvironment = scopeOtherEnvironment.keyBuilder.feature(CacheFeatureKeys.vehicleList, 'page=1');

    expect(keyA, isNot(keyB));
    expect(keyA, isNot(keyOtherEnvironment));
    expect(keyA, contains('ADMIN'));
    expect(keyA, contains('account-1'));
    expect(keyA, contains('user-1'));
  });
}

String _jwt(Map<String, Object?> payload) {
  String part(Object value) => base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${part(<String, Object?>{'alg': 'none', 'typ': 'JWT'})}.${part(payload)}.';
}

class _MemoryTokenStorage implements TokenStorageBase {
  _MemoryTokenStorage(this.accessToken);

  String? accessToken;
  String? refreshToken;
  final List<String> impersonatorStack = <String>[];

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    impersonatorStack.clear();
  }

  @override
  Future<void> clearImpersonatorToken() async => impersonatorStack.clear();

  @override
  Future<void> clearRefreshToken() async => refreshToken = null;

  @override
  Future<String?> popImpersonatorToken() async => impersonatorStack.isEmpty ? null : impersonatorStack.removeLast();

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readImpersonatorToken() async => impersonatorStack.isEmpty ? null : impersonatorStack.last;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> writeAccessToken(String token) async => accessToken = token;

  @override
  Future<void> writeImpersonatorToken(String token) async => impersonatorStack.add(token);

  @override
  Future<void> writeRefreshToken(String token) async => refreshToken = token;
}
