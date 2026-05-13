import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/admin/data/mappers/admin_form_mapper.dart';
import 'package:open_vts/features/admin/data/repositories/admin_form_repository_impl.dart';
import 'package:open_vts/features/admin/data/sources/admin_form_api_service.dart';
import 'package:open_vts/features/admin/domain/entities/create_admin_user_input.dart';
import 'package:open_vts/features/admin/domain/entities/create_admin_vehicle_input.dart';

void main() {
  test('create user maps success DTO to domain', () async {
    final repo = AdminFormRepositoryImpl(
      api: _FakeAdminFormApiService(
        createdUser: _okObject(<String, Object?>{'id': 'u1', 'name': 'A User', 'email': 'a@example.com'}, key: 'user'),
      ),
      mapper: const AdminFormMapper(),
    );

    final result = await repo.createUser(_userInput());

    result.when(
      success: (user) => expect(user.id, 'u1'),
      failure: (error) => fail('Expected success, got $error'),
    );
  });

  test('create vehicle prevents raw map leakage and maps DTO to domain', () async {
    final repo = AdminFormRepositoryImpl(
      api: _FakeAdminFormApiService(
        createdVehicle: _okObject(<String, Object?>{'id': 'v1', 'name': 'Truck', 'plateNumber': 'DL01'}, key: 'vehicle'),
      ),
      mapper: const AdminFormMapper(),
    );

    final result = await repo.createVehicle(_vehicleInput());

    result.when(
      success: (vehicle) {
        expect(vehicle.id, 'v1');
        expect(vehicle.plateNumber, 'DL01');
      },
      failure: (error) => fail('Expected success, got $error'),
    );
  });

  test('backend action=false maps to ServerError', () async {
    final repo = AdminFormRepositoryImpl(
      api: _FakeAdminFormApiService(
        createdUser: _response(action: false, message: 'Rejected'),
      ),
      mapper: const AdminFormMapper(),
    );

    final result = await repo.createUser(_userInput());

    expect(result.errorOrNull, isA<ServerError>());
  });

  test('empty create user data maps to ServerError', () async {
    final repo = AdminFormRepositoryImpl(
      api: _FakeAdminFormApiService(
        createdUser: _response(data: null),
      ),
      mapper: const AdminFormMapper(),
    );

    final result = await repo.createUser(_userInput());

    expect(result.errorOrNull, isA<ServerError>());
  });

  test('timeout maps to NetworkError', () async {
    final repo = AdminFormRepositoryImpl(
      api: _FakeAdminFormApiService(error: DioException(
        requestOptions: RequestOptions(path: '/admin/users'),
        type: DioExceptionType.connectionTimeout,
      )),
      mapper: const AdminFormMapper(),
    );

    final result = await repo.createUser(_userInput());

    expect(result.errorOrNull, isA<NetworkError>());
  });

  test('401 maps to AuthError', () async {
    final repo = AdminFormRepositoryImpl(
      api: _FakeAdminFormApiService(error: DioException(
        requestOptions: RequestOptions(path: '/admin/users'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/admin/users'),
          statusCode: 401,
          data: const {'message': 'Unauthorized'},
        ),
      )),
      mapper: const AdminFormMapper(),
    );

    final result = await repo.createUser(_userInput());

    expect(result.errorOrNull, isA<AuthError>());
  });
}

CreateAdminUserInput _userInput() => const CreateAdminUserInput(
      name: 'A User',
      email: 'a@example.com',
      mobilePrefix: '+91',
      mobileNumber: '9876543210',
      username: 'auser',
      password: 'secret123',
      companyName: 'Acme',
      address: 'Street',
      countryCode: 'IN',
      stateCode: 'DL',
      city: 'Delhi',
      pincode: '110001',
    );

CreateAdminVehicleInput _vehicleInput() => const CreateAdminVehicleInput(
      name: 'Truck',
      vin: 'VIN123',
      plateNumber: 'DL01',
      deviceId: '123456789012345',
      vehicleTypeId: '1',
      primaryUserId: 'u1',
      planId: 'p1',
    );

Map<String, Object?> _okObject(Map<String, Object?> item, {required String key}) {
  return _response(data: <String, Object?>{key: item});
}

Map<String, Object?> _okList(List<Object?> items, {String key = 'data'}) {
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

class _FakeAdminFormApiService implements AdminFormApiService {
  _FakeAdminFormApiService({this.createdUser, this.createdVehicle, this.error});

  final Object? createdUser;
  final Object? createdVehicle;
  final Object? error;

  @override
  Future<Object?> createUser(Map<String, dynamic> body) async {
    final e = error;
    if (e != null) throw e;
    return createdUser ?? _okObject(<String, Object?>{'id': 'u1', 'name': 'A User', 'email': 'a@example.com'}, key: 'user');
  }

  @override
  Future<Object?> createVehicle(Map<String, dynamic> body) async {
    final e = error;
    if (e != null) throw e;
    return createdVehicle ?? _okObject(<String, Object?>{'id': 'v1', 'name': 'Truck', 'plateNumber': 'DL01'}, key: 'vehicle');
  }

  @override
  Future<Object?> getUsers({int limit = 100}) async => _okList(const <Object?>[], key: 'userslist');

  @override
  Future<Object?> getQuickDevices() async => _okList(const <Object?>[], key: 'devices');

  @override
  Future<Object?> getVehicleTypes() async => _okList(const <Object?>[], key: 'types');

  @override
  Future<Object?> getPricingPlans() async => _okList(const <Object?>[], key: 'plans');
}
