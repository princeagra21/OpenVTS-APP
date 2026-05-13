import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/user/data/mappers/user_sub_user_mapper.dart';
import 'package:open_vts/features/user/data/repositories/user_sub_user_repository_impl.dart';
import 'package:open_vts/features/user/data/sources/user_sub_user_api_service.dart';

void main() {
  test('maps sub-user list from enveloped backend response', () async {
    final repo = UserSubUserRepositoryImpl(
      api: _FakeUserSubUserApiService(),
      mapper: const UserSubUserMapper(),
    );

    final result = await repo.getSubUsers();

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.single.email, 'qa@example.com');
  });

  test('maps action=false to ServerError', () async {
    final repo = UserSubUserRepositoryImpl(
      api: _FakeUserSubUserApiService(action: false),
      mapper: const UserSubUserMapper(),
    );

    final result = await repo.createSubUser(const <String, Object?>{'email': 'bad@example.com'});

    expect(result.isFailure, isTrue);
    expect(result.errorOrNull, isA<ServerError>());
  });
}

class _FakeUserSubUserApiService implements UserSubUserApiService {
  _FakeUserSubUserApiService({this.action = true});
  final bool action;

  @override
  Future<Object?> getSubUsers({int? page, int? limit}) async => _response(<String, Object?>{
        'subusers': const <Object?>[
          <String, Object?>{'id': 'sub-1', 'name': 'QA User', 'email': 'qa@example.com'},
        ],
      });

  @override
  Future<Object?> getSubUserDetail(String id) async => _response(<String, Object?>{'id': id, 'email': 'qa@example.com'});

  @override
  Future<Object?> createSubUser(Map<String, Object?> body) async => _response(<String, Object?>{'id': 'created', ...body});

  @override
  Future<Object?> updateSubUser(String id, Map<String, Object?> body) async => _response(<String, Object?>{'id': id, ...body});

  @override
  Future<Object?> deleteSubUser(String id) async => _response(null);

  @override
  Future<Object?> getSubUserVehicles(String id) async => _response(<String, Object?>{'vehicles': const <Object?>[]});

  @override
  Future<Object?> assignVehicle(String id, Map<String, Object?> body) async => _response(null);

  @override
  Future<Object?> unassignVehicle(String id, Map<String, Object?> body) async => _response(null);

  Map<String, Object?> _response(Object? data) => <String, Object?>{
        'status': action ? 'success' : 'error',
        'data': <String, Object?>{
          'action': action,
          'message': action ? '' : 'Backend rejected request',
          'data': data,
        },
      };
}
