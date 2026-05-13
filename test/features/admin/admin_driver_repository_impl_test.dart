import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/admin/data/mappers/admin_driver_mapper.dart';
import 'package:open_vts/features/admin/data/repositories/admin_driver_repository_impl.dart';
import 'package:open_vts/features/admin/data/sources/admin_driver_api_service.dart';

void main() {
  test('getDrivers maps enveloped driver list to domain items', () async {
    final repo = AdminDriverRepositoryImpl(
      api: _FakeAdminDriverApiService(
        drivers: _okList(const [
          {'id': 'd1', 'name': 'A Driver', 'status': 'ACTIVE'},
        ], key: 'drivers'),
      ),
      mapper: const AdminDriverMapper(),
    );

    final result = await repo.getDrivers();

    result.when(
      success: (items) {
        expect(items, hasLength(1));
        expect(items.single.id, 'd1');
        expect(items.single.fullName, 'A Driver');
      },
      failure: (error) => fail('Expected success, got $error'),
    );
  });

  test('action=false maps to ServerError', () async {
    final repo = AdminDriverRepositoryImpl(
      api: _FakeAdminDriverApiService(drivers: _response(action: false, message: 'Rejected')),
      mapper: const AdminDriverMapper(),
    );

    final result = await repo.getDrivers();

    expect(result.errorOrNull, isA<ServerError>());
  });

  test('dio timeout maps to NetworkError', () async {
    final repo = AdminDriverRepositoryImpl(
      api: _FakeAdminDriverApiService(error: DioException(
        requestOptions: RequestOptions(path: '/admin/drivers'),
        type: DioExceptionType.connectionTimeout,
      )),
      mapper: const AdminDriverMapper(),
    );

    final result = await repo.getDrivers();

    expect(result.errorOrNull, isA<NetworkError>());
  });
}

Map<String, Object?> _okList(List<Object?> items, {required String key}) {
  return _response(data: <String, Object?>{key: items});
}

Map<String, Object?> _response({bool action = true, String message = '', Object? data = const <String, Object?>{}}) {
  return <String, Object?>{
    'status': action ? 'success' : 'error',
    'data': <String, Object?>{
      'action': action,
      'message': message,
      'data': data,
    },
  };
}

class _FakeAdminDriverApiService implements AdminDriverApiService {
  _FakeAdminDriverApiService({this.drivers, this.error});
  final Object? drivers;
  final Object? error;

  void _throwIfNeeded() {
    final e = error;
    if (e != null) throw e;
  }

  @override
  Future<Object?> getDrivers({String? search, String? status, int? page, int? limit}) async {
    _throwIfNeeded();
    return drivers ?? _okList(const [], key: 'drivers');
  }

  @override
  Future<Object?> getDriverDetail(String driverId) async => _response(data: {'driver': {'id': driverId}});

  @override
  Future<Object?> updateDriver(String driverId, Map<String, Object?> body) async => _response();

  @override
  Future<Object?> getDriverDocuments(String driverId) async => _okList(const [], key: 'documents');

  @override
  Future<Object?> getLinkedUsers(String driverId, {int? rk}) async => _okList(const [], key: 'users');

  @override
  Future<Object?> getUnlinkedUsers(String driverId, {int? rk}) async => _okList(const [], key: 'users');

  @override
  Future<Object?> assignUserToDriver(String driverId, Map<String, Object?> body) async => _response();

  @override
  Future<Object?> unassignUserFromDriver(String driverId, Map<String, Object?> body) async => _response();
}
