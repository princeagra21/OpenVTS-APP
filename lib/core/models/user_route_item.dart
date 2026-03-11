import 'package:latlong2/latlong.dart';

class UserRouteItem {
  final Map<String, dynamic> raw;

  const UserRouteItem(this.raw);

  String get id => _text(raw['id'] ?? raw['_id'] ?? raw['routeId']);
  String get name => _text(raw['name'] ?? raw['label'] ?? 'Optimized Route');
  String get color => _text(raw['color']);
  int get toleranceMeters =>
      _int(raw['toleranceMeters'] ?? raw['toleranceM'] ?? raw['buffer']) ?? 100;
  String get updatedAt => _text(raw['updatedAt'] ?? raw['createdAt']);

  List<LatLng> get coordinates {
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
    return out;
  }

  bool get hasGeometry => coordinates.length >= 2;

  static String _text(Object? value) => (value ?? '').toString().trim();

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

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value.cast());
    return const <String, dynamic>{};
  }
}
