import 'package:fleet_stack/core/models/admin_driver_list_item.dart';

class AdminDriverDetails extends AdminDriverListItem {
  const AdminDriverDetails(super.raw);

  factory AdminDriverDetails.fromRaw(Map<String, dynamic> raw) {
    return AdminDriverDetails(raw);
  }

  String get pincode => _firstString(
    const ['pincode', 'zipCode', 'zip'],
    nestedKeys: const ['address'],
  );

  String get countryCode => _firstString(
    const ['countryCode', 'country'],
    nestedKeys: const ['address'],
  );

  String get stateCode => _firstString(
    const ['stateCode', 'StateCode'],
    nestedKeys: const ['address'],
  );

  String get city =>
      _firstString(const ['city', 'cityId'], nestedKeys: const ['address']);

  @override
  String get primaryUserId =>
      _firstString(const ['primaryUserid', 'primaryUserId']);

  String get addressLine =>
      _firstString(const ['addressLine'], nestedKeys: const ['address']);

  String get fullAddress =>
      _firstString(const ['fullAddress'], nestedKeys: const ['address']);

  String get createdAt =>
      _firstString(const ['createdAt', 'created_at', 'joinedAt']);

  String get verifiedLabel => isVerified ? 'Verified' : 'Not Verified';

  bool get isVerified {
    final direct = _firstBool(const ['isVerified', 'verified']);
    return direct ?? false;
  }

  String _firstString(
    List<String> keys, {
    List<String> nestedKeys = const <String>[],
  }) {
    for (final nestedKey in nestedKeys) {
      final nested = raw[nestedKey];
      if (nested is Map<String, dynamic>) {
        for (final key in keys) {
          final value = nested[key];
          if (value == null) continue;
          final s = value.toString().trim();
          if (s.isNotEmpty && s.toLowerCase() != 'null') return s;
        }
      } else if (nested is Map) {
        final map = Map<String, dynamic>.from(nested.cast());
        for (final key in keys) {
          final value = map[key];
          if (value == null) continue;
          final s = value.toString().trim();
          if (s.isNotEmpty && s.toLowerCase() != 'null') return s;
        }
      }
    }

    for (final key in keys) {
      final value = raw[key];
      if (value == null) continue;
      final s = value.toString().trim();
      if (s.isNotEmpty && s.toLowerCase() != 'null') return s;
    }
    return '';
  }

  bool? _firstBool(List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value == null) continue;
      if (value is bool) return value;
      if (value is num) return value != 0;
      final s = value.toString().trim().toLowerCase();
      if (s == 'true' || s == '1' || s == 'yes') return true;
      if (s == 'false' || s == '0' || s == 'no') return false;
    }
    return null;
  }
}
