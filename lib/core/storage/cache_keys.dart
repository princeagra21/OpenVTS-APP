import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:open_vts/core/security/cache_key_builder.dart';
import 'package:open_vts/core/storage/secure_storage.dart';

class CacheScope {
  const CacheScope({
    required this.environmentKey,
    required this.role,
    required this.accountId,
    required this.userId,
  });

  final String environmentKey;
  final String role;
  final String accountId;
  final String userId;

  CacheKeyBuilder get keyBuilder => CacheKeyBuilder(
        environmentKey: environmentKey,
        role: role,
        accountId: accountId,
        userId: userId,
      );
}

class CacheFeatureKeys {
  const CacheFeatureKeys._();

  static const vehicleList = 'vehicles.list';
  static const vehicleDetail = 'vehicles.detail';
  static const historyRange = 'history.range';
}

class CacheScopeResolver {
  const CacheScopeResolver({
    required SecureStorage secureStorage,
    required Dio dio,
  })  : _secureStorage = secureStorage,
        _dio = dio;

  final SecureStorage _secureStorage;
  final Dio _dio;

  Future<CacheScope> resolve() async {
    final token = await _secureStorage.getAccessToken();
    final payload = _decodeJwtPayload(token);
    final baseUrl = _dio.options.baseUrl.trim();

    final role = _firstString(payload, const [
      'role',
      'userRole',
      'user_role',
      'type',
    ]);
    final userId = _firstString(payload, const [
      'sub',
      'id',
      '_id',
      'userId',
      'user_id',
      'adminId',
      'admin_id',
    ]);
    final accountId = _firstString(payload, const [
      'tenantId',
      'tenant_id',
      'accountId',
      'account_id',
      'companyId',
      'company_id',
      'ownerId',
      'owner_id',
      'adminId',
      'admin_id',
    ]);

    return CacheScope(
      environmentKey: _environmentKey(baseUrl),
      role: role.isEmpty ? 'anonymous' : role,
      accountId: accountId.isEmpty ? (userId.isEmpty ? 'anonymous' : userId) : accountId,
      userId: userId.isEmpty ? 'anonymous' : userId,
    );
  }

  static String queryKey(Map<String, Object?> values) {
    final entries = values.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries
        .map((entry) => '${entry.key}=${entry.value?.toString().trim() ?? ''}')
        .join('&')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-.:=&]'), '_');
  }

  static Map<String, Object?> _decodeJwtPayload(String? token) {
    final value = token?.trim() ?? '';
    if (value.isEmpty) return const <String, Object?>{};
    final parts = value.split('.');
    if (parts.length < 2) return const <String, Object?>{};
    try {
      final decoded = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return <String, Object?>{for (final entry in decoded.entries) entry.key.toString(): entry.value};
    } catch (_) {
      return const <String, Object?>{};
    }
    return const <String, Object?>{};
  }

  static String _firstString(Map<String, Object?> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  static String _environmentKey(String baseUrl) {
    final normalized = baseUrl.trim().toLowerCase().replaceAll(RegExp(r'/+$'), '');
    if (normalized.isEmpty) return 'unknown_environment';
    return base64Url.encode(utf8.encode(normalized)).replaceAll('=', '');
  }
}
