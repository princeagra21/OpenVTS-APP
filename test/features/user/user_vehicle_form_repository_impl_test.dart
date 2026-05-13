import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/user/data/mappers/user_vehicle_form_mapper.dart';
import 'package:open_vts/features/user/data/repositories/user_vehicle_form_repository_impl.dart';
import 'package:open_vts/features/user/data/sources/user_vehicle_form_api_service.dart';
import 'package:open_vts/features/user/domain/entities/create_user_vehicle_input.dart';

void main() {
  test('UserVehicleFormRepositoryImpl maps vehicle types', () async {
    final repo = UserVehicleFormRepositoryImpl(
      api: _FakeUserVehicleFormApiService(),
      mapper: const UserVehicleFormMapper(),
    );

    final result = await repo.getVehicleTypes();

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.single.label, 'Car');
  });

  test('UserVehicleFormRepositoryImpl maps action false to ServerError', () async {
    final repo = UserVehicleFormRepositoryImpl(
      api: _FakeUserVehicleFormApiService(action: false),
      mapper: const UserVehicleFormMapper(),
    );

    final result = await repo.createVehicle(
      const CreateUserVehicleInput(
        imei: '1234567890',
        plateNumber: 'DL01AB1234',
        vehicleTypeId: '1',
        gmtOffset: '+05:30',
      ),
    );

    expect(result.isFailure, isTrue);
    expect(result.errorOrNull, isA<ServerError>());
  });
}

class _FakeUserVehicleFormApiService implements UserVehicleFormApiService {
  _FakeUserVehicleFormApiService({this.action = true});

  final bool action;

  @override
  Future<Object?> getVehicleTypes() async {
    return _response(<String, Object?>{
      'types': const <Object?>[
        <String, Object?>{'id': '1', 'name': 'Car'},
      ],
    });
  }

  @override
  Future<Object?> createVehicle(Map<String, Object?> body) async {
    return _response(null);
  }

  Map<String, Object?> _response(Object? data) {
    return <String, Object?>{
      'status': action ? 'success' : 'error',
      'data': <String, Object?>{
        'action': action,
        'message': action ? '' : 'Backend rejected request',
        'data': data,
      },
    };
  }
}
