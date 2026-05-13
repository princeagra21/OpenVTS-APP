import 'package:open_vts/features/admin/domain/entities/admin_driver_list_item.dart';

class UserDriverDetails extends AdminDriverListItem {
  const UserDriverDetails(super.raw);

  factory UserDriverDetails.fromRaw(Map<String, Object?> raw) {
    return UserDriverDetails(raw);
  }

  Map<String, Object?> get addressMap {
    final value = raw['address'];
    if (value is Map<String, Object?>) return value;
    if (value is Map) return Map<String, Object?>.from(value.cast());
    return const <String, dynamic>{};
  }

  String get countryCode => _text(
    raw['countryCode'] ?? addressMap['countryCode'] ?? addressMap['country'],
  );

  String get stateCode =>
      _text(raw['stateCode'] ?? addressMap['stateCode'] ?? addressMap['state']);

  String get cityId =>
      _text(raw['cityId'] ?? addressMap['cityId'] ?? addressMap['city']);

  String get addressLine =>
      _text(raw['addressLine'] ?? addressMap['addressLine'] ?? raw['address']);

  String get pincode =>
      _text(raw['pincode'] ?? addressMap['pincode'] ?? raw['postalCode']);

  String get fullAddress =>
      _text(addressMap['fullAddress'] ?? raw['fullAddress'] ?? addressLine);

  String get mobileCode => _text(
    raw['mobileCode'] ?? raw['mobilePrefix'] ?? addressMap['mobileCode'],
  );

  bool get isVerified {
    final value = raw['isVerified'] ?? raw['verified'];
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = _text(value).toLowerCase();
    return text == 'true' || text == '1' || text == 'verified';
  }

  String get createdAtLabel =>
      _text(raw['createdAt'] ?? raw['created_at'] ?? raw['created']);

  @override
  String get driverVehicleLabel {
    final vehicle = raw['driverVehicle'];
    if (vehicle is Map<String, Object?>) {
      return _text(
        vehicle['plateNumber'] ??
            vehicle['name'] ??
            vehicle['vehicleName'] ??
            vehicle['id'],
      );
    }
    if (vehicle is Map) {
      final map = Map<String, Object?>.from(vehicle.cast());
      return _text(
        map['plateNumber'] ?? map['name'] ?? map['vehicleName'] ?? map['id'],
      );
    }
    return _text(vehicle);
  }

  static String _text(Object? value) {
    if (value == null) return '';
    final text = value.toString().trim();
    if (text.toLowerCase() == 'null') return '';
    return text;
  }
}
