import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/user/data/mappers/user_route_mapper.dart';
import 'package:open_vts/features/user/data/repositories/user_route_repository_impl.dart';
import 'package:open_vts/features/user/data/sources/user_route_api_service.dart';
import 'package:open_vts/features/user/domain/entities/create_user_route_input.dart';

void main() {
  test('maps routes from enveloped response', () async {
    final repo = UserRouteRepositoryImpl(api: _FakeUserRouteApiService(), mapper: const UserRouteMapper());

    final result = await repo.getRoutes();

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.single.name, 'Main Route');
  });

  test('maps action=false to ServerError', () async {
    final repo = UserRouteRepositoryImpl(api: _FakeUserRouteApiService(action: false), mapper: const UserRouteMapper());

    final result = await repo.createRoute(const CreateUserRouteInput(name: 'Bad', points: [LatLng(28.61, 77.20), LatLng(28.62, 77.21)]));

    expect(result.isFailure, isTrue);
    expect(result.errorOrNull, isA<ServerError>());
  });
}

class _FakeUserRouteApiService implements UserRouteApiService {
  _FakeUserRouteApiService({this.action = true});
  final bool action;
  @override
  Future<Object?> getRoutes() async => _response(<String, Object?>{
        'routes': const <Object?>[
          <String, Object?>{
            'id': 'route-1',
            'name': 'Main Route',
            'geodata': <String, Object?>{
              'geometry': <String, Object?>{
                'coordinates': <Object?>[
                  <double>[77.20, 28.61],
                  <double>[77.21, 28.62],
                ],
              },
            },
          },
        ],
      });
  @override
  Future<Object?> getRouteDetail(String id) async => _response(<String, Object?>{'id': id, 'name': 'Main Route'});
  @override
  Future<Object?> createRoute(Map<String, Object?> body) async => _response(<String, Object?>{'id': 'new', ...body});
  @override
  Future<Object?> updateRoute(String id, Map<String, Object?> body) async => _response(<String, Object?>{'id': id, ...body});
  @override
  Future<Object?> deleteRoute(String id) async => _response(null);
  Map<String, Object?> _response(Object? data) => <String, Object?>{'data': <String, Object?>{'action': action, 'message': action ? '' : 'Route rejected', 'data': data}};
}
