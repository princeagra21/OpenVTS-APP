import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/user/data/mappers/user_vehicle_mapper.dart';
import 'package:open_vts/features/user/data/repositories/user_vehicle_repository_impl.dart';
import 'package:open_vts/features/user/data/sources/user_vehicle_api_service.dart';

void main() {
  test('maps vehicle detail from enveloped response', () async {
    final repo = UserVehicleRepositoryImpl(api: _FakeUserVehicleApiService(), mapper: const UserVehicleMapper());

    final result = await repo.getVehicleDetail('veh-1');

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.plateNumber, 'DL01AB1234');
  });

  test('maps action=false to ServerError', () async {
    final repo = UserVehicleRepositoryImpl(api: _FakeUserVehicleApiService(action: false), mapper: const UserVehicleMapper());

    final result = await repo.getVehicleDetail('veh-1');

    expect(result.isFailure, isTrue);
    expect(result.errorOrNull, isA<ServerError>());
  });
}

class _FakeUserVehicleApiService implements UserVehicleApiService {
  _FakeUserVehicleApiService({this.action = true});
  final bool action;
  @override
  Future<Object?> getVehicleDetail(String id) async => <String, Object?>{
        'data': <String, Object?>{
          'action': action,
          'message': action ? '' : 'Vehicle denied',
          'data': <String, Object?>{'id': id, 'plateNumber': 'DL01AB1234'},
        },
      };
}
