import 'package:latlong2/latlong.dart';
import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/features/user/data/models/user_route_dtos.dart';
import 'package:open_vts/features/user/domain/entities/create_user_route_input.dart';
import 'package:open_vts/features/user/domain/entities/update_user_route_input.dart';
import 'package:open_vts/features/user/domain/entities/user_route_item.dart';

class UserRouteMapper {
  const UserRouteMapper();

  List<UserRouteDto> listFromResponse(Object? response) {
    return ApiResponseNormalizer.listOf(
      response,
      preferredKeys: const ['routes', 'items', 'rows'],
    ).whereType<Map>().map((item) => UserRouteDto(_map(item))).toList(growable: false);
  }

  UserRouteDto? detailFromResponse(Object? response) {
    final map = ApiResponseNormalizer.mapPayloadOf(
      response,
      preferredKeys: const ['route', 'item'],
    );
    return map.isEmpty ? null : UserRouteDto(map);
  }

  UserRouteItem toDomain(UserRouteDto dto) => UserRouteItem.fromRaw(_dynamicMap(dto.json));

  UserRouteMutationDto createMutation(CreateUserRouteInput input) => UserRouteMutationDto(_payload(
        name: input.name,
        color: input.color,
        toleranceMeters: input.toleranceMeters,
        points: input.points,
        assignedDriver: input.assignedDriver,
      ));

  UserRouteMutationDto updateMutation(UpdateUserRouteInput input) => UserRouteMutationDto(_payload(
        name: input.name,
        color: input.color,
        toleranceMeters: input.toleranceMeters,
        points: input.points,
        assignedDriver: input.assignedDriver,
      ));

  UserRouteMutationDto assignDriverMutation(String? driver) {
    return UserRouteMutationDto(<String, Object?>{
      'assignedDriver': driver,
      'driver': driver,
    });
  }

  Map<String, Object?> _payload({
    required String name,
    required String color,
    required int toleranceMeters,
    required List<LatLng> points,
    String? assignedDriver,
  }) {
    return <String, Object?>{
      'name': name.trim().isEmpty ? 'Optimized Route' : name.trim(),
      'color': color.trim().isEmpty ? '#2196F3' : color.trim(),
      'toleranceMeters': toleranceMeters,
      if ((assignedDriver ?? '').trim().isNotEmpty) 'assignedDriver': assignedDriver!.trim(),
      'geodata': <String, Object?>{
        'kind': 'LINE',
        'geometry': <String, Object?>{
          'type': 'LineString',
          'coordinates': points.map((p) => <double>[p.longitude, p.latitude]).toList(growable: false),
        },
        'toleranceM': toleranceMeters,
      },
    };
  }

  static Map<String, Object?> _map(Map value) => <String, Object?>{for (final entry in value.entries) entry.key.toString(): entry.value};
  static Map<String, dynamic> _dynamicMap(Map<String, Object?> value) => <String, dynamic>{for (final entry in value.entries) entry.key: entry.value};
}
