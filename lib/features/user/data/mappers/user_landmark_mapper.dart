import 'package:open_vts/features/user/data/models/user_landmark_dtos.dart';
import 'package:latlong2/latlong.dart';
import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/features/user/domain/entities/create_user_landmark_input.dart';
import 'package:open_vts/features/user/domain/entities/update_user_landmark_input.dart';
import 'package:open_vts/features/user/domain/entities/user_landmark_item.dart';

class UserLandmarkMapper {
  const UserLandmarkMapper();

  List<UserLandmarkItem> geofencesFromResponse(Object? response) {
    return _items(response, const ['geofences']).map((item) => _toItem(item, fallbackShape: UserLandmarkShape.polygon)).whereType<UserLandmarkItem>().toList(growable: false);
  }

  List<UserLandmarkItem> routesFromResponse(Object? response) {
    return _items(response, const ['routes']).map((item) => _toItem(item, fallbackShape: UserLandmarkShape.route)).whereType<UserLandmarkItem>().toList(growable: false);
  }

  List<UserLandmarkItem> poisFromResponse(Object? response) {
    return _items(response, const ['pois']).map((item) => _toItem(item, fallbackShape: UserLandmarkShape.poi)).whereType<UserLandmarkItem>().toList(growable: false);
  }

  UserLandmarkItem fromMutationResponse(Object? response, CreateUserLandmarkInput input) {
    final map = ApiResponseNormalizer.mapPayloadOf(response, preferredKeys: const ['landmark', 'geofence', 'route', 'poi']);
    return _toItem(map, fallbackShape: input.shape) ?? _fromCreateInput(input);
  }

  UserLandmarkItem fromUpdateResponse(Object? response, UpdateUserLandmarkInput input) {
    final map = ApiResponseNormalizer.mapPayloadOf(response, preferredKeys: const ['landmark', 'geofence', 'route', 'poi']);
    return _toItem(map, fallbackShape: input.shape) ?? _fromUpdateInput(input);
  }

  Map<String, Object?> createPayload(CreateUserLandmarkInput input) {
    return _payload(
      name: input.name,
      shape: input.shape,
      points: input.points,
      colorHex: input.colorHex,
      radiusMeters: input.radiusMeters,
      widthMeters: input.widthMeters,
      isActive: input.isActive,
    );
  }

  Map<String, Object?> updatePayload(UpdateUserLandmarkInput input) {
    return _payload(
      name: input.name,
      shape: input.shape,
      points: input.points,
      colorHex: input.colorHex,
      radiusMeters: input.radiusMeters,
      widthMeters: input.widthMeters,
      isActive: input.isActive,
    );
  }

  String collectionForShape(UserLandmarkShape shape) {
    switch (shape) {
      case UserLandmarkShape.poi:
        return 'poi';
      case UserLandmarkShape.route:
      case UserLandmarkShape.line:
        return 'route';
      case UserLandmarkShape.circle:
      case UserLandmarkShape.polygon:
      case UserLandmarkShape.rectangle:
        return 'geofence';
    }
  }

  static List<Map<String, Object?>> _items(Object? response, List<String> keys) {
    return ApiResponseNormalizer.listOf(response, preferredKeys: keys)
        .whereType<Map>()
        .map(_map)
        .toList(growable: false);
  }

  static UserLandmarkItem? _toItem(Map<String, Object?> raw, {required UserLandmarkShape fallbackShape}) {
    if (raw.isEmpty) return null;
    final name = _text(raw['name'] ?? raw['label']);
    if (name.isEmpty) return null;
    final geodata = _map(raw['geodata']);
    final geometry = _map(geodata['geometry']);
    final shape = _shapeFrom(raw['type'] ?? geodata['kind'] ?? raw['shapeType'], fallbackShape);
    final points = _pointsFor(raw, geodata, geometry, shape);
    if (points.isEmpty) return null;
    return UserLandmarkItem(
      id: _text(raw['id'] ?? raw['_id'] ?? raw['uid'] ?? raw['code']),
      name: name,
      shape: shape,
      colorHex: _text(raw['color']).isEmpty ? '#2196F3' : _text(raw['color']),
      isActive: _bool(raw['isActive'] ?? raw['active'] ?? true),
      points: points,
      radiusMeters: _number(geodata['radiusM'] ?? raw['radius'] ?? raw['radiusM'] ?? raw['toleranceMeters']),
      widthMeters: _number(geodata['toleranceM'] ?? geodata['toleranceMeters'] ?? raw['toleranceMeters'] ?? raw['width'] ?? raw['buffer']),
      updatedAt: _text(raw['updatedAt'] ?? raw['updated_at'] ?? raw['createdAt']),
    );
  }

  static List<LatLng> _pointsFor(Map<String, Object?> raw, Map<String, Object?> geodata, Map<String, Object?> geometry, UserLandmarkShape shape) {
    if (shape == UserLandmarkShape.circle || shape == UserLandmarkShape.poi) {
      final center = _map(geodata['center']);
      final lat = _number(center['lat'] ?? raw['latitude'] ?? raw['lat'] ?? raw['centerLat']);
      final lng = _number(center['lon'] ?? center['lng'] ?? raw['longitude'] ?? raw['lng'] ?? raw['lon'] ?? raw['centerLon']);
      if (lat == null || lng == null) return const <LatLng>[];
      return <LatLng>[LatLng(lat, lng)];
    }
    return _latLngList(geometry['coordinates'] ?? raw['coordinates'] ?? raw['points'], closePolygon: shape == UserLandmarkShape.polygon);
  }

  static UserLandmarkShape _shapeFrom(Object? value, UserLandmarkShape fallback) {
    final text = _text(value).toUpperCase();
    switch (text) {
      case 'CIRCLE':
        return UserLandmarkShape.circle;
      case 'POI':
        return UserLandmarkShape.poi;
      case 'ROUTE':
        return UserLandmarkShape.route;
      case 'LINE':
        return UserLandmarkShape.line;
      case 'RECTANGLE':
        return UserLandmarkShape.rectangle;
      case 'POLYGON':
        return UserLandmarkShape.polygon;
      default:
        return fallback;
    }
  }

  static Map<String, Object?> _payload({
    required String name,
    required UserLandmarkShape shape,
    required List<LatLng> points,
    required String colorHex,
    required double? radiusMeters,
    required double? widthMeters,
    required bool isActive,
  }) {
    if (shape == UserLandmarkShape.poi) {
      final point = points.first;
      return <String, Object?>{
        'name': name,
        'color': colorHex,
        'toleranceMeters': (radiusMeters ?? 25).round(),
        'coordinates': <String, Object?>{'lat': point.latitude, 'lon': point.longitude},
      };
    }
    if (shape == UserLandmarkShape.circle) {
      final center = points.first;
      return <String, Object?>{
        'name': name,
        'type': 'CIRCLE',
        'color': colorHex,
        'isActive': isActive,
        'geodata': <String, Object?>{
          'kind': 'CIRCLE',
          'center': <String, Object?>{'lat': center.latitude, 'lon': center.longitude},
          'radiusM': (radiusMeters ?? 25).round(),
        },
      };
    }
    if (shape == UserLandmarkShape.line || shape == UserLandmarkShape.route) {
      final isRoute = shape == UserLandmarkShape.route;
      return <String, Object?>{
        'name': name,
        'description': '',
        'type': isRoute ? 'ROUTE' : 'LINE',
        'color': colorHex,
        'isActive': isActive,
        'geodata': <String, Object?>{
          'kind': isRoute ? 'ROUTE' : 'LINE',
          'geometry': <String, Object?>{
            'type': 'LineString',
            'coordinates': points.map((p) => <double>[p.longitude, p.latitude]).toList(),
          },
          'toleranceM': (widthMeters ?? 50).round(),
        },
      };
    }
    final polygonPoints = List<LatLng>.from(points);
    if (polygonPoints.length >= 3 &&
        (polygonPoints.first.latitude != polygonPoints.last.latitude || polygonPoints.first.longitude != polygonPoints.last.longitude)) {
      polygonPoints.add(polygonPoints.first);
    }
    return <String, Object?>{
      'name': name,
      'type': shape == UserLandmarkShape.rectangle ? 'RECTANGLE' : 'POLYGON',
      'color': colorHex,
      'isActive': isActive,
      'geodata': <String, Object?>{
        'kind': shape == UserLandmarkShape.rectangle ? 'RECTANGLE' : 'POLYGON',
        'geometry': <String, Object?>{
          'type': 'Polygon',
          'coordinates': [polygonPoints.map((p) => <double>[p.longitude, p.latitude]).toList()],
        },
      },
    };
  }

  static UserLandmarkItem _fromCreateInput(CreateUserLandmarkInput input) {
    return UserLandmarkItem(
      id: '',
      name: input.name,
      shape: input.shape,
      points: input.points,
      colorHex: input.colorHex,
      radiusMeters: input.radiusMeters,
      widthMeters: input.widthMeters,
      isActive: input.isActive,
    );
  }

  static UserLandmarkItem _fromUpdateInput(UpdateUserLandmarkInput input) {
    return UserLandmarkItem(
      id: input.id,
      name: input.name,
      shape: input.shape,
      points: input.points,
      colorHex: input.colorHex,
      radiusMeters: input.radiusMeters,
      widthMeters: input.widthMeters,
      isActive: input.isActive,
    );
  }

  static Map<String, Object?> _map(Object? value) {
    if (value is Map) return <String, Object?>{for (final entry in value.entries) entry.key.toString(): entry.value};
    return const <String, Object?>{};
  }

  static List<LatLng> _latLngList(Object? value, {bool closePolygon = false}) {
    if (value is! List) return const <LatLng>[];
    final points = <LatLng>[];
    for (final item in value) {
      if (item is List && item.length >= 2) {
        final first = _number(item[0]);
        final second = _number(item[1]);
        if (first == null || second == null) continue;
        final lat = first.abs() > 60 && second.abs() <= 60 ? second : first;
        final lng = first.abs() > 60 && second.abs() <= 60 ? first : second;
        points.add(LatLng(lat, lng));
      } else if (item is Map) {
        final map = _map(item);
        final lat = _number(map['lat'] ?? map['latitude']);
        final lng = _number(map['lng'] ?? map['lon'] ?? map['longitude']);
        if (lat != null && lng != null) points.add(LatLng(lat, lng));
      }
    }
    if (closePolygon && points.length >= 3 &&
        (points.first.latitude != points.last.latitude || points.first.longitude != points.last.longitude)) {
      points.add(points.first);
    }
    return points;
  }

  static String _text(Object? value) => (value ?? '').toString().trim();

  static double? _number(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  static bool _bool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase() ?? '';
    return text == 'true' || text == '1' || text == 'yes' || text == 'on';
  }

  UserLandmarkMutationDto mutation(Map<String, Object?> payload) {
    return UserLandmarkMutationDto(payload);
  }

}
