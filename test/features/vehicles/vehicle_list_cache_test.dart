import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/database/app_database.dart';
import 'package:open_vts/core/storage/cache_keys.dart';
import 'package:open_vts/core/storage/secure_storage.dart';
import 'package:open_vts/core/storage/token_storage.dart';
import 'package:open_vts/features/vehicles/data/local/vehicle_local_source.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle.dart';
import 'package:open_vts/shared/models/paginated_response.dart';

void main() {
  late AppDatabase database;
  late VehicleLocalSource localSource;

  setUp(() {
    database = AppDatabase.forExecutor(NativeDatabase.memory());
    localSource = VehicleLocalSource(
      database: database,
      scopeResolver: CacheScopeResolver(
        secureStorage: SecureStorage(tokenStorage: _MemoryTokenStorage()),
        dio: Dio(BaseOptions(baseUrl: 'https://tenant.example.com/api')),
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('vehicle list reads cached page as stale-safe fallback data', () async {
    await localSource.saveVehicleList(
      pageData: const PaginatedResponse<Vehicle>(
        data: [
          Vehicle(
            id: 'v1',
            name: 'Truck 1',
            plateNumber: 'DL01AA0001',
            imei: '1234567890',
            status: 'moving',
          ),
        ],
        total: 1,
        page: 1,
        limit: 20,
      ),
      page: 1,
      limit: 20,
    );

    final hit = await localSource.readVehicleList(page: 1, limit: 20);

    expect(hit, isNotNull);
    expect(hit!.page.isFromCache, isTrue);
    expect(hit.page.data.single.id, 'v1');
    expect(hit.page.data.single.plateNumber, 'DL01AA0001');
  });

  test('database cache clear removes cached vehicle rows on logout hook', () async {
    await localSource.saveVehicleList(
      pageData: const PaginatedResponse<Vehicle>(
        data: [Vehicle(id: 'v1', name: 'Truck 1')],
        total: 1,
      ),
    );

    await database.clearAllCachedData();

    final hit = await localSource.readVehicleList();
    expect(hit, isNull);
  });
}

class _MemoryTokenStorage implements TokenStorageBase {
  String? accessToken;
  String? refreshToken;

  @override
  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
  }

  @override
  Future<void> clearImpersonatorToken() async {}

  @override
  Future<void> clearRefreshToken() async => refreshToken = null;

  @override
  Future<String?> popImpersonatorToken() async => null;

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readImpersonatorToken() async => null;

  @override
  Future<String?> readRefreshToken() async => refreshToken;

  @override
  Future<void> writeAccessToken(String token) async => accessToken = token;

  @override
  Future<void> writeImpersonatorToken(String token) async {}

  @override
  Future<void> writeRefreshToken(String token) async => refreshToken = token;
}
