import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/user/data/mappers/user_landmark_mapper.dart';
import 'package:open_vts/features/user/data/repositories/user_landmark_repository_impl.dart';
import 'package:open_vts/features/user/data/sources/user_landmark_api_service.dart';
import 'package:open_vts/features/user/domain/entities/create_user_landmark_input.dart';

void main() {
  test('maps POIs from enveloped response', () async {
    final repo = UserLandmarkRepositoryImpl(api: _FakeUserLandmarkApiService(), mapper: const UserLandmarkMapper());

    final result = await repo.getPois();

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.single.name, 'Warehouse');
  });

  test('maps action=false to ServerError', () async {
    final repo = UserLandmarkRepositoryImpl(api: _FakeUserLandmarkApiService(action: false), mapper: const UserLandmarkMapper());

    final result = await repo.createLandmark(const CreateUserLandmarkInput(
      name: 'Bad',
      shape: UserLandmarkShape.poi,
      points: <LatLng>[LatLng(28.6, 77.2)],
    ));

    expect(result.isFailure, isTrue);
    expect(result.errorOrNull, isA<ServerError>());
  });
}

class _FakeUserLandmarkApiService implements UserLandmarkApiService {
  _FakeUserLandmarkApiService({this.action = true});
  final bool action;
  @override
  Future<Object?> getGeofences() async => _response(<String, Object?>{'geofences': const <Object?>[]});
  @override
  Future<Object?> getRoutes() async => _response(<String, Object?>{'routes': const <Object?>[]});
  @override
  Future<Object?> getPois() async => _response(<String, Object?>{'pois': const <Object?>[<String, Object?>{'id': 'poi-1', 'name': 'Warehouse', 'coordinates': <String, Object?>{'lat': 28.6, 'lon': 77.2}}]});
  @override
  Future<Object?> createGeofence(Map<String, Object?> body) async => _response(<String, Object?>{'geofence': body});
  @override
  Future<Object?> createRoute(Map<String, Object?> body) async => _response(<String, Object?>{'route': body});
  @override
  Future<Object?> createPoi(Map<String, Object?> body) async => _response(<String, Object?>{'poi': <String, Object?>{'id': 'created', ...body}});
  @override
  Future<Object?> updateGeofence(String id, Map<String, Object?> body) async => _response(<String, Object?>{'geofence': <String, Object?>{'id': id, ...body}});
  @override
  Future<Object?> updateRoute(String id, Map<String, Object?> body) async => _response(<String, Object?>{'route': <String, Object?>{'id': id, ...body}});
  @override
  Future<Object?> updatePoi(String id, Map<String, Object?> body) async => _response(<String, Object?>{'poi': <String, Object?>{'id': id, ...body}});
  @override
  Future<Object?> deleteGeofence(String id) async => _response(null);
  @override
  Future<Object?> deleteRoute(String id) async => _response(null);
  @override
  Future<Object?> deletePoi(String id) async => _response(null);
  Map<String, Object?> _response(Object? data) => <String, Object?>{'data': <String, Object?>{'action': action, 'message': action ? '' : 'Landmark rejected', 'data': data}};
}
