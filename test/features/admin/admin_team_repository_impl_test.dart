import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/admin/data/mappers/admin_team_mapper.dart';
import 'package:open_vts/features/admin/data/repositories/admin_team_repository_impl.dart';
import 'package:open_vts/features/admin/data/sources/admin_team_api_service.dart';

void main() {
  test('getTeams maps enveloped team list to domain items', () async {
    final repo = AdminTeamRepositoryImpl(
      api: _FakeAdminTeamApiService(
        teams: _okList(const [
          {'id': 't1', 'name': 'Ops Team', 'isActive': true},
        ], key: 'teams'),
      ),
      mapper: const AdminTeamMapper(),
    );

    final result = await repo.getTeams();

    result.when(
      success: (items) {
        expect(items, hasLength(1));
        expect(items.single.id, 't1');
        expect(items.single.fullName, 'Ops Team');
      },
      failure: (error) => fail('Expected success, got $error'),
    );
  });

  test('action=false maps to ServerError', () async {
    final repo = AdminTeamRepositoryImpl(
      api: _FakeAdminTeamApiService(teams: _response(action: false, message: 'Rejected')),
      mapper: const AdminTeamMapper(),
    );

    final result = await repo.getTeams();

    expect(result.errorOrNull, isA<ServerError>());
  });

  test('dio timeout maps to NetworkError', () async {
    final repo = AdminTeamRepositoryImpl(
      api: _FakeAdminTeamApiService(error: DioException(
        requestOptions: RequestOptions(path: '/admin/teams'),
        type: DioExceptionType.connectionTimeout,
      )),
      mapper: const AdminTeamMapper(),
    );

    final result = await repo.getTeams();

    expect(result.errorOrNull, isA<NetworkError>());
  });
}

Map<String, Object?> _okList(List<Object?> items, {required String key}) => _response(data: <String, Object?>{key: items});
Map<String, Object?> _response({bool action = true, String message = '', Object? data = const <String, Object?>{}}) => <String, Object?>{
      'status': action ? 'success' : 'error',
      'data': <String, Object?>{'action': action, 'message': message, 'data': data},
    };

class _FakeAdminTeamApiService implements AdminTeamApiService {
  _FakeAdminTeamApiService({this.teams, this.error});
  final Object? teams;
  final Object? error;

  void _throwIfNeeded() {
    final e = error;
    if (e != null) throw e;
  }

  @override
  Future<Object?> getTeams({String? search, int? page, int? limit}) async {
    _throwIfNeeded();
    return teams ?? _okList(const [], key: 'teams');
  }

  @override
  Future<Object?> getTeamDetail(String teamId) async => _response(data: {'team': {'id': teamId}});

  @override
  Future<Object?> updateTeam(String teamId, Map<String, Object?> body) async => _response();

  @override
  Future<Object?> createTeam(Map<String, Object?> body) async => _response();
}
