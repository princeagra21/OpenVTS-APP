import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/storage/secure_storage.dart';
import 'package:open_vts/core/storage/token_storage.dart';
import 'package:open_vts/features/auth/data/mappers/auth_mapper.dart';
import 'package:open_vts/features/auth/data/models/auth_request_dtos.dart';
import 'package:open_vts/features/auth/data/models/login_request.dart';
import 'package:open_vts/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:open_vts/features/auth/data/sources/auth_retrofit_service.dart';
import 'package:open_vts/features/auth/domain/entities/user_role.dart';

class _FakeAuthRetrofitService implements AuthRetrofitService {
  Object? loginResponse;
  Object? forgotPasswordResponse = const ApiResponse<void>(
    status: 'ok',
    data: ApiData<void>(action: true, message: 'OK', data: null),
    timestamp: null,
  );
  Object? refreshResponse;
  Object? refreshError;

  @override
  Future<ApiResponse<Map<String, Object?>>> login(LoginRequest request) async => loginResponse as ApiResponse<Map<String, Object?>>;

  @override
  Future<ApiResponse<void>> forgotPassword(ForgotPasswordRequestDto request) async => forgotPasswordResponse as ApiResponse<void>;

  @override
  Future<ApiResponse<Map<String, Object?>>> refreshToken(RefreshTokenRequestDto request) async {
    final error = refreshError;
    if (error != null) throw error;
    return refreshResponse as ApiResponse<Map<String, Object?>>;
  }
}

class _MemoryTokenStorage implements TokenStorageBase {
  String? accessToken;
  String? refreshToken;
  String? impersonatorToken;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<void> writeAccessToken(String token) async => accessToken = token;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> writeRefreshToken(String token) async => refreshToken = token;

  @override
  Future<void> clearRefreshToken() async => refreshToken = null;

  @override
  Future<String?> readImpersonatorToken() async => impersonatorToken;

  @override
  Future<void> writeImpersonatorToken(String token) async => impersonatorToken = token;

  @override
  Future<String?> popImpersonatorToken() async {
    final value = impersonatorToken;
    impersonatorToken = null;
    return value;
  }

  @override
  Future<void> clearImpersonatorToken() async => impersonatorToken = null;

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    impersonatorToken = null;
  }
}

void main() {
  late _FakeAuthRetrofitService api;
  late _MemoryTokenStorage tokenStorage;
  late AuthRepositoryImpl repository;

  setUp(() {
    api = _FakeAuthRetrofitService();
    tokenStorage = _MemoryTokenStorage();
    repository = AuthRepositoryImpl(
      api: api,
      storage: SecureStorage(tokenStorage: tokenStorage),
      mapper: const AuthMapper(),
    );
  });

  test('login success maps user/session and stores tokens securely', () async {
    api.loginResponse = _envelope(<String, Object?>{
      'token': 'access-token',
      'refreshToken': 'refresh-token',
      'user': <String, Object?>{
        'id': '1',
        'name': 'Admin User',
        'email': 'admin@example.com',
        'role': 'ADMIN',
      },
    });

    final result = await repository.login(identifier: 'admin', password: 'secret');

    expect(result.isSuccess, true);
    expect(result.valueOrNull?.user.role, UserRole.admin);
    expect(result.valueOrNull?.user.email, 'admin@example.com');
    expect(tokenStorage.accessToken, 'access-token');
    expect(tokenStorage.refreshToken, 'refresh-token');
  });

  test('invalid credentials maps to AppError and does not store tokens', () async {
    api.loginResponse = const ApiResponse<Map<String, Object?>>(
      status: 'ok',
      data: ApiData<Map<String, Object?>>(
        action: false,
        message: 'Invalid credentials.',
        data: null,
      ),
      timestamp: null,
    );

    final result = await repository.login(identifier: 'admin', password: 'bad');

    expect(result.isFailure, true);
    expect(result.errorOrNull, isA<AuthError>());
    expect(tokenStorage.accessToken, isNull);
  });

  test('unsupported role clears session', () async {
    tokenStorage.accessToken = 'old-token';
    tokenStorage.refreshToken = 'old-refresh';
    api.loginResponse = _envelope(<String, Object?>{
      'token': 'access-token',
      'refreshToken': 'refresh-token',
      'user': <String, Object?>{
        'id': '1',
        'role': 'ALIEN',
      },
    });

    final result = await repository.login(identifier: 'admin', password: 'secret');

    expect(result.isFailure, true);
    expect(result.errorOrNull, isA<PermissionAppError>());
    expect(tokenStorage.accessToken, isNull);
    expect(tokenStorage.refreshToken, isNull);
  });

  test('logout clears secure storage', () async {
    tokenStorage.accessToken = 'access-token';
    tokenStorage.refreshToken = 'refresh-token';

    final result = await repository.logout();

    expect(result.isSuccess, true);
    expect(tokenStorage.accessToken, isNull);
    expect(tokenStorage.refreshToken, isNull);
  });

  test('restore session with no token returns unauthenticated', () async {
    final result = await repository.restoreSession();

    expect(result.isSuccess, true);
    expect(result.valueOrNull, isNull);
  });

  test('restore session with valid token returns authenticated', () async {
    tokenStorage.accessToken = _jwt(<String, Object?>{
      'sub': '42',
      'email': 'admin@example.com',
      'name': 'Admin User',
      'role': 'ADMIN',
    });

    final result = await repository.restoreSession();

    expect(result.isSuccess, true);
    expect(result.valueOrNull?.id, '42');
    expect(result.valueOrNull?.role, UserRole.admin);
  });

  test('refresh token failure clears session', () async {
    tokenStorage.accessToken = 'old-token';
    tokenStorage.refreshToken = 'old-refresh';
    api.refreshResponse = const ApiResponse<Map<String, Object?>>(
      status: 'ok',
      data: ApiData<Map<String, Object?>>(
        action: true,
        message: 'OK',
        data: <String, Object?>{},
      ),
      timestamp: null,
    );

    final result = await repository.refreshSession();

    expect(result.isFailure, true);
    expect(tokenStorage.accessToken, isNull);
    expect(tokenStorage.refreshToken, isNull);
  });
}

ApiResponse<Map<String, Object?>> _envelope(Map<String, Object?> data) {
  return ApiResponse<Map<String, Object?>>(
    status: 'ok',
    data: ApiData<Map<String, Object?>>(
      action: true,
      message: 'OK',
      data: data,
    ),
    timestamp: null,
  );
}

String _jwt(Map<String, Object?> payload) {
  final header = base64Url.encode(utf8.encode(jsonEncode(<String, Object?>{'alg': 'none'}))).replaceAll('=', '');
  final body = base64Url.encode(utf8.encode(jsonEncode(payload))).replaceAll('=', '');
  return '$header.$body.signature';
}
