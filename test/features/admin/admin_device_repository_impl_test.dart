import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/admin/data/mappers/admin_device_mapper.dart';
import 'package:open_vts/features/admin/data/repositories/admin_device_repository_impl.dart';
import 'package:open_vts/features/admin/data/sources/admin_device_api_service.dart';

void main() {
  test('getDevices maps enveloped device list to domain items', () async {
    final repo = AdminDeviceRepositoryImpl(
      api: _FakeAdminDeviceApiService(
        devices: _okList(const [
          {'id': 'dev1', 'imei': '123456789012345', 'status': 'IN_STOCK'},
        ], key: 'devices'),
      ),
      mapper: const AdminDeviceMapper(),
    );

    final result = await repo.getDevices();

    result.when(
      success: (items) {
        expect(items, hasLength(1));
        expect(items.single.id, 'dev1');
        expect(items.single.imei, '123456789012345');
      },
      failure: (error) => fail('Expected success, got $error'),
    );
  });

  test('updateDevice sends typed mutation body', () async {
    final api = _FakeAdminDeviceApiService();
    final repo = AdminDeviceRepositoryImpl(api: api, mapper: const AdminDeviceMapper());

    final result = await repo.updateDeviceStatus('dev1', false);

    expect(result.valueOrNull, isNull);
    expect(api.lastUpdateBody['isActive'], false);
  });

  test('dio timeout maps to NetworkError', () async {
    final repo = AdminDeviceRepositoryImpl(
      api: _FakeAdminDeviceApiService(error: DioException(
        requestOptions: RequestOptions(path: '/admin/devices'),
        type: DioExceptionType.connectionTimeout,
      )),
      mapper: const AdminDeviceMapper(),
    );

    final result = await repo.getDevices();

    expect(result.errorOrNull, isA<NetworkError>());
  });
}

Map<String, Object?> _okList(List<Object?> items, {required String key}) => _response(data: <String, Object?>{key: items});
Map<String, Object?> _response({bool action = true, String message = '', Object? data = const <String, Object?>{}}) => <String, Object?>{
      'status': action ? 'success' : 'error',
      'data': <String, Object?>{'action': action, 'message': message, 'data': data},
    };

class _FakeAdminDeviceApiService implements AdminDeviceApiService {
  _FakeAdminDeviceApiService({this.devices, this.error});
  final Object? devices;
  final Object? error;
  Map<String, Object?> lastUpdateBody = const <String, Object?>{};

  void _throwIfNeeded() {
    final e = error;
    if (e != null) throw e;
  }

  @override
  Future<Object?> getDevices({String? search, String? status, int? page, int? limit}) async {
    _throwIfNeeded();
    return devices ?? _okList(const [], key: 'devices');
  }

  @override
  Future<Object?> getDeviceDetail(String deviceId) async => _response(data: {'device': {'id': deviceId}});

  @override
  Future<Object?> getDeviceTypes() async => _okList(const [], key: 'devicetypes');

  @override
  Future<Object?> getSims() async => _okList(const [], key: 'simcards');

  @override
  Future<Object?> getSimProviders() async => _okList(const [], key: 'simproviders');

  @override
  Future<Object?> getQuickSimCards() async => _okList(const [], key: 'simcards');

  @override
  Future<Object?> createSimCard(Map<String, Object?> body) async => _response();

  @override
  Future<Object?> createDevice(Map<String, Object?> body) async => _response();

  @override
  Future<Object?> createDeviceAndSim(Map<String, Object?> body) async => _response();

  @override
  Future<Object?> updateDevice(String deviceId, Map<String, Object?> body) async {
    lastUpdateBody = body;
    return _response();
  }
}
