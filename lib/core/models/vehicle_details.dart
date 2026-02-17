import 'package:fleet_stack/core/models/vehicle_document_item.dart';
import 'package:fleet_stack/core/models/vehicle_user_item.dart';

class VehicleDetails {
  final Map<String, dynamic> raw;

  const VehicleDetails(this.raw);

  Map<String, dynamic> get data {
    final d = raw['data'];
    if (d is Map) return Map<String, dynamic>.from(d.cast());
    return raw;
  }

  String get id =>
      _s(data['id'] ?? data['vehicleId'] ?? data['vehicle_id'] ?? data['uuid']);

  String get plate => _s(
    data['plateNumber'] ??
        data['plate_number'] ??
        data['plate'] ??
        data['registrationNumber'] ??
        data['registration_number'],
  );

  String get status => _s(data['status'] ?? data['state']);

  bool get isActive {
    final v = data['active'] ?? data['isActive'] ?? data['is_active'];
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = status.trim().toLowerCase();
    if (s == 'active' || s == 'running') return true;
    if (s == 'inactive' || s == 'disabled') return false;
    if (v is String) {
      final t = v.trim().toLowerCase();
      if (t == 'true' || t == '1') return true;
      if (t == 'false' || t == '0') return false;
    }
    return false;
  }

  String get model =>
      _s(data['model'] ?? data['deviceModel'] ?? data['device']);

  String get type => _s(
    data['type'] ??
        data['vehicleType'] ??
        data['vehicleTypeName'] ??
        data['vehicle_type_name'],
  );

  String get imei => _s(
    data['imei'] ??
        data['deviceImei'] ??
        data['device_imei'] ??
        data['imeiNumber'],
  );

  String get lastSeen => _s(
    data['lastSeen'] ??
        data['lastSeenAt'] ??
        data['last_seen_at'] ??
        data['updatedAt'] ??
        data['updated_at'],
  );

  String get speed => _s(data['speed'] ?? data['currentSpeed']);

  String get ignition =>
      _s(data['ignition'] ?? data['isIgnitionOn'] ?? data['ignitionStatus']);

  String get locationName =>
      _s(data['location'] ?? data['locationName'] ?? data['city']);

  List<Object?>? get usersRaw => _extractList(const [
    'users',
    'userList',
    'vehicleUsers',
    'linkedUsers',
    'assignedUsers',
  ]);

  List<Object?>? get documentsRaw =>
      _extractList(const ['documents', 'docs', 'files']);

  List<VehicleUserItem> get users =>
      _mapItems(usersRaw, (map) => VehicleUserItem(map));

  List<VehicleDocumentItem> get documents =>
      _mapItems(documentsRaw, (map) => VehicleDocumentItem(map));

  List<Object?>? _extractList(List<String> keys) {
    for (final key in keys) {
      final candidate = data[key];
      final list = _coerceList(candidate);
      if (list != null) return list;
    }
    return null;
  }

  static List<Object?>? _coerceList(Object? candidate) {
    if (candidate is List) return List<Object?>.from(candidate);
    if (candidate is Map) {
      for (final k in const ['data', 'items', 'result', 'results', 'list']) {
        final nested = candidate[k];
        if (nested is List) return List<Object?>.from(nested);
      }
    }
    return null;
  }

  static List<T> _mapItems<T>(
    List<Object?>? list,
    T Function(Map<String, dynamic>) builder,
  ) {
    if (list == null) return <T>[];
    final out = <T>[];
    for (final it in list) {
      if (it is Map<String, dynamic>) {
        out.add(builder(it));
      } else if (it is Map) {
        out.add(builder(Map<String, dynamic>.from(it.cast())));
      }
    }
    return out;
  }

  static String _s(Object? v) {
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }
}
