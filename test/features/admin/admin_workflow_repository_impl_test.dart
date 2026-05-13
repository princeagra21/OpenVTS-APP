import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/admin/data/mappers/admin_workflow_mapper.dart';
import 'package:open_vts/features/admin/data/repositories/admin_device_form_repository_impl.dart';
import 'package:open_vts/features/admin/data/repositories/admin_driver_form_repository_impl.dart';
import 'package:open_vts/features/admin/data/repositories/admin_team_form_repository_impl.dart';
import 'package:open_vts/features/admin/data/sources/admin_workflow_api_service.dart';
import 'package:open_vts/features/admin/domain/entities/admin_device_form_input.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_form_input.dart';
import 'package:open_vts/features/admin/domain/entities/admin_team_form_input.dart';

void main() {
  test('AdminDeviceFormRepositoryImpl maps form data success', () async {
    final repo = AdminDeviceFormRepositoryImpl(
      api: _FakeAdminWorkflowApiService(),
      mapper: const AdminWorkflowMapper(),
    );

    final result = await repo.loadFormData();

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.deviceTypes.first.name, 'GT06');
    expect(result.valueOrNull?.sims.first.number, '999');
  });

  test('AdminDeviceFormRepositoryImpl prevents empty create failure leaks', () async {
    final repo = AdminDeviceFormRepositoryImpl(
      api: _FakeAdminWorkflowApiService(action: false),
      mapper: const AdminWorkflowMapper(),
    );

    final result = await repo.createDevice(
      const CreateAdminDeviceInput(imei: '1234567890', deviceTypeId: '1'),
    );

    expect(result.isFailure, isTrue);
    expect(result.errorOrNull, isA<ServerError>());
  });

  test('AdminDriverFormRepositoryImpl creates driver through typed input', () async {
    final repo = AdminDriverFormRepositoryImpl(
      api: _FakeAdminWorkflowApiService(),
      mapper: const AdminWorkflowMapper(),
    );

    final result = await repo.createDriver(
      const CreateAdminDriverInput(
        primaryUserId: '1',
        name: 'Driver',
        email: 'driver@example.com',
        username: 'driver',
        password: 'secret123',
        mobilePrefix: '+91',
        mobile: '9999999999',
        countryCode: 'IN',
        stateCode: 'DL',
        city: 'Delhi',
        address: 'Road',
        pincode: '110001',
      ),
    );

    expect(result.isSuccess, isTrue);
  });

  test('AdminTeamFormRepositoryImpl maps action false to ServerError', () async {
    final repo = AdminTeamFormRepositoryImpl(
      api: _FakeAdminWorkflowApiService(action: false),
    );

    final result = await repo.createTeam(
      const CreateAdminTeamInput(
        name: 'Team',
        email: 'team@example.com',
        mobilePrefix: '+91',
        mobileNumber: '9999999999',
        username: 'team',
        password: 'secret123',
      ),
    );

    expect(result.isFailure, isTrue);
    expect(result.errorOrNull, isA<ServerError>());
  });
}

class _FakeAdminWorkflowApiService implements AdminWorkflowApiService {
  _FakeAdminWorkflowApiService({this.action = true});

  final bool action;

  @override
  Future<Object?> getUsers({int limit = 200}) async {
    return _response(<String, Object?>{
      'userslist': const <Object?>[
        <String, Object?>{'id': '1', 'name': 'User'},
      ],
    });
  }

  @override
  Future<Object?> createDriver(Map<String, Object?> body) async {
    return _response(<String, Object?>{
      'driver': <String, Object?>{'id': '1', 'name': body['name']},
    });
  }

  @override
  Future<Object?> getDeviceTypes() async {
    return _response(<String, Object?>{
      'devicetypes': const <Object?>[
        <String, Object?>{'id': '1', 'name': 'GT06'},
      ],
    });
  }

  @override
  Future<Object?> getSims() async {
    return _response(<String, Object?>{
      'simcards': const <Object?>[
        <String, Object?>{'id': '1', 'simNumber': '999'},
      ],
    });
  }

  @override
  Future<Object?> createDevice(Map<String, Object?> body) async {
    return _response(null);
  }

  @override
  Future<Object?> createTeam(Map<String, Object?> body) async {
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
