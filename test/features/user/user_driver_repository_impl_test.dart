import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/user/data/mappers/user_driver_mapper.dart';
import 'package:open_vts/features/user/data/repositories/user_driver_repository_impl.dart';
import 'package:open_vts/features/user/data/sources/user_driver_api_service.dart';

void main() {
  test('maps user drivers from enveloped response', () async {
    final repo = UserDriverRepositoryImpl(api: _FakeUserDriverApiService(), mapper: const UserDriverMapper());

    final result = await repo.getDrivers();

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.single.email, 'driver@example.com');
  });

  test('maps rejected create to ServerError', () async {
    final repo = UserDriverRepositoryImpl(api: _FakeUserDriverApiService(action: false), mapper: const UserDriverMapper());

    final result = await repo.createDriver(const <String, Object?>{'email': 'bad@example.com'});

    expect(result.isFailure, isTrue);
    expect(result.errorOrNull, isA<ServerError>());
  });
}

class _FakeUserDriverApiService implements UserDriverApiService {
  _FakeUserDriverApiService({this.action = true});
  final bool action;

  @override
  Future<Object?> getDrivers() async => _response(<String, Object?>{
        'drivers': const <Object?>[
          <String, Object?>{'id': 'driver-1', 'name': 'Driver One', 'email': 'driver@example.com'},
        ],
      });

  @override
  Future<Object?> getDriverDetail(String id) async => _response(<String, Object?>{'id': id, 'email': 'driver@example.com'});

  @override
  Future<Object?> createDriver(Map<String, Object?> body) async => _response(<String, Object?>{'id': 'new', ...body});

  @override
  Future<Object?> updateDriver(String id, Map<String, Object?> body) async => _response(<String, Object?>{'id': id, ...body});

  @override
  Future<Object?> deleteDriver(String id, Map<String, Object?> body) async => _response(null);

  Map<String, Object?> _response(Object? data) => <String, Object?>{
        'data': <String, Object?>{'action': action, 'message': action ? '' : 'Backend rejected request', 'data': data},
      };
}
