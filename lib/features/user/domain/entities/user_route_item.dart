import 'package:latlong2/latlong.dart';

class UserRouteItem {
  const UserRouteItem({
    required this.id,
    required this.name,
    required this.color,
    required this.toleranceMeters,
    required this.updatedAt,
    required this.coordinates,
    this.assignedDriver,
  });

  factory UserRouteItem.fromRaw(Map<String, Object?> raw) {
    return UserRouteItem(
      id: _text(raw['id'] ?? raw['_id'] ?? raw['routeId']),
      name: _text(raw['name'] ?? raw['label'] ?? 'Optimized Route'),
      color: _text(raw['color']),
      toleranceMeters: _int(raw['toleranceMeters'] ?? raw['toleranceM'] ?? raw['buffer']) ?? 100,
      updatedAt: _text(raw['updatedAt'] ?? raw['createdAt']),
      coordinates: _coordinatesFromRaw(raw),
      assignedDriver: _nullableText(raw['assignedDriver'] ?? raw['driverName'] ?? raw['driver']),
    );
  }

  final String id;
  final String name;
  final String color;
  final int toleranceMeters;
  final String updatedAt;
  final List<LatLng> coordinates;
  final String? assignedDriver;

  bool get hasGeometry => coordinates.length >= 2;

  UserRouteItem copyWith({
    String? id,
    String? name,
    String? color,
    int? toleranceMeters,
    String? updatedAt,
    List<LatLng>? coordinates,
    Object? assignedDriver = _unchanged,
  }) {
    return UserRouteItem(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      toleranceMeters: toleranceMeters ?? this.toleranceMeters,
      updatedAt: updatedAt ?? this.updatedAt,
      coordinates: coordinates ?? this.coordinates,
      assignedDriver: identical(assignedDriver, _unchanged) ? this.assignedDriver : assignedDriver as String?,
    );
  }

  static List<LatLng> _coordinatesFromRaw(Map<String, Object?> raw) {
    final geodata = _map(raw['geodata']);
    final geometry = _map(geodata['geometry']);
    final value = geometry['coordinates'] ?? raw['coordinates'] ?? raw['points'];
    if (value is! List) return const <LatLng>[];

    final out = <LatLng>[];
    for (final item in value) {
      if (item is List && item.length >= 2) {
        final a = _double(item[0]);
        final b = _double(item[1]);
        if (a == null || b == null) continue;

        late final double lat;
        late final double lng;
        if (a.abs() > 60 && b.abs() <= 60) {
          lng = a;
          lat = b;
        } else if (b.abs() > 60 && a.abs() <= 60) {
          lat = a;
          lng = b;
        } else {
          lat = a;
          lng = b;
        }
        out.add(LatLng(lat, lng));
      }
    }
    return List<LatLng>.unmodifiable(out);
  }

  static String _text(Object? value) => (value ?? '').toString().trim();

  static String? _nullableText(Object? value) {
    final text = _text(value);
    return text.isEmpty ? null : text;
  }

  static int? _int(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString());
  }

  static double? _double(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static Map<String, Object?> _map(Object? value) {
    if (value is Map<String, Object?>) return value;
    if (value is Map) {
      return <String, Object?>{for (final entry in value.entries) entry.key.toString(): entry.value};
    }
    return const <String, Object?>{};
  }
}

const Object _unchanged = Object();
