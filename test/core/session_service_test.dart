import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/session/session_service.dart';
import 'package:open_vts/core/storage/token_storage.dart';

class MockTokenStorage implements TokenStorageBase {
  String? _accessToken;
  String? _refreshToken;
  String? _impersonatorToken;

  @override
  Future<String?> readAccessToken() async => _accessToken;

  @override
  Future<void> writeAccessToken(String token) async {
    _accessToken = token;
  }

  @override
  Future<String?> readImpersonatorToken() async => _impersonatorToken;

  @override
  Future<void> writeImpersonatorToken(String token) async {
    _impersonatorToken = token;
  }

  @override
  Future<String?> popImpersonatorToken() async {
    final token = _impersonatorToken;
    _impersonatorToken = null;
    return token;
  }

  @override
  Future<void> clearImpersonatorToken() async {
    _impersonatorToken = null;
  }

  @override
  Future<String?> readRefreshToken() async => _refreshToken;

  @override
  Future<void> writeRefreshToken(String token) async {
    _refreshToken = token;
  }

  @override
  Future<void> clearRefreshToken() async {
    _refreshToken = null;
  }

  @override
  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    _impersonatorToken = null;
  }
}

void main() {
  late MockTokenStorage mockTokenStorage;
  late SessionService sessionService;

  setUp(() {
    mockTokenStorage = MockTokenStorage();
    sessionService = SessionService(tokenStorage: mockTokenStorage);
  });

  group('SessionService', () {
    group('readAccessToken', () {
      test('returns token from storage', () async {
        mockTokenStorage._accessToken = 'test-token';

        final result = await sessionService.readAccessToken();

        expect(result, 'test-token');
      });

      test('returns null when storage returns null', () async {
        mockTokenStorage._accessToken = null;

        final result = await sessionService.readAccessToken();

        expect(result, null);
      });
    });

    group('readRefreshToken', () {
      test('returns refresh token from storage', () async {
        mockTokenStorage._refreshToken = 'refresh-token';

        final result = await sessionService.readRefreshToken();

        expect(result, 'refresh-token');
      });
    });

    group('clearSession', () {
      test('clears all tokens', () async {
        mockTokenStorage._accessToken = 'token';
        mockTokenStorage._refreshToken = 'refresh';
        mockTokenStorage._impersonatorToken = 'impersonator';

        await sessionService.clearSession();

        expect(mockTokenStorage._accessToken, null);
        expect(mockTokenStorage._refreshToken, null);
        expect(mockTokenStorage._impersonatorToken, null);
      });
    });

    group('roleFromCurrentToken', () {
      test('extracts role from valid JWT token', () async {
        // JWT with payload {"role": "admin", "exp": 2000000000}
        const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYWRtaW4iLCJleHAiOjIwMDAwMDAwMDB9.test';
        mockTokenStorage._accessToken = token;

        final role = await sessionService.roleFromCurrentToken();

        expect(role, 'admin');
      });

      test('returns null for invalid token', () async {
        mockTokenStorage._accessToken = 'invalid-token';

        final role = await sessionService.roleFromCurrentToken();

        expect(role, null);
      });

      test('returns null when no token', () async {
        mockTokenStorage._accessToken = null;

        final role = await sessionService.roleFromCurrentToken();

        expect(role, null);
      });
    });

    group('logout', () {
      test('clears session when no impersonator token', () async {
        mockTokenStorage._accessToken = 'token';
        mockTokenStorage._refreshToken = 'refresh';
        mockTokenStorage._impersonatorToken = null;

        await sessionService.logout();

        expect(mockTokenStorage._accessToken, null);
        expect(mockTokenStorage._refreshToken, null);
        expect(mockTokenStorage._impersonatorToken, null);
      });

      test('restores impersonator token when present', () async {
        mockTokenStorage._accessToken = 'current-token';
        mockTokenStorage._refreshToken = 'refresh-token';
        mockTokenStorage._impersonatorToken = 'impersonator-token';

        await sessionService.logout();

        expect(mockTokenStorage._accessToken, 'impersonator-token');
        expect(mockTokenStorage._refreshToken, null);
        expect(mockTokenStorage._impersonatorToken, null);
      });
    });

    group('hasValidAccessToken', () {
      test('returns true for valid non-expired token', () async {
        // JWT with future expiry
        const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjIwMDAwMDAwMDB9.test';
        mockTokenStorage._accessToken = token;

        final result = await sessionService.hasValidAccessToken();

        expect(result, isTrue);
      });

      test('returns false for expired token', () async {
        // JWT with past expiry
        const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjEwMDAwMDAwMDB9.test';
        mockTokenStorage._accessToken = token;

        final result = await sessionService.hasValidAccessToken();

        expect(result, isFalse);
      });

      test('returns false for null token', () async {
        mockTokenStorage._accessToken = null;

        final result = await sessionService.hasValidAccessToken();

        expect(result, isFalse);
      });

      test('returns false for empty token', () async {
        mockTokenStorage._accessToken = '';

        final result = await sessionService.hasValidAccessToken();

        expect(result, isFalse);
      });
    });

    group('startImpersonation', () {
      test('stores current token and sets new one', () async {
        mockTokenStorage._accessToken = 'current-token';

        await sessionService.startImpersonation('new-token');

        expect(mockTokenStorage._accessToken, 'new-token');
        expect(mockTokenStorage._impersonatorToken, 'current-token');
      });

      test('handles null current token', () async {
        mockTokenStorage._accessToken = null;

        await sessionService.startImpersonation('new-token');

        expect(mockTokenStorage._accessToken, 'new-token');
        expect(mockTokenStorage._impersonatorToken, null);
      });

      test('trims whitespace from token', () async {
        await sessionService.startImpersonation('  trimmed-token  ');

        expect(mockTokenStorage._accessToken, 'trimmed-token');
      });
    });
  });
}