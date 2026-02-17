import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/capturing_adapter.dart';

class _FakeTokenStorage implements TokenStorageBase {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> readAccessToken() async => 'test-token';

  @override
  Future<void> writeAccessToken(String token) async {}
}

void main() {
  test(
    'getTickets uses GET /superadmin/support/tickets (Postman list endpoint)',
    () async {
      final api = ApiClient(
        config: const AppConfig(
          environment: AppEnvironment.dev,
          baseUrl: 'https://example.com',
        ),
        tokenStorage: _FakeTokenStorage(),
      );
      final adapter = CapturingAdapter();
      api.dio.httpClientAdapter = adapter;

      final repo = SuperadminRepository(api: api);

      final res = await repo.getTickets(status: 'OPEN', page: 1, limit: 1);

      expect(res.isSuccess, isTrue);
      expect(adapter.lastRequest, isNotNull);
      expect(adapter.lastRequest!.method, equals('GET'));
      expect(adapter.lastRequest!.path, equals('/superadmin/support/tickets'));
      expect(adapter.lastRequest!.queryParameters['status'], equals('OPEN'));
      expect(adapter.lastRequest!.queryParameters['page'], equals(1));
      expect(adapter.lastRequest!.queryParameters['limit'], equals(1));
    },
  );
}
