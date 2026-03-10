import 'package:fleet_stack/core/models/admin_driver_list_item.dart';

class AdminDriverDetails extends AdminDriverListItem {
  const AdminDriverDetails(super.raw);

  factory AdminDriverDetails.fromRaw(Map<String, dynamic> raw) {
    return AdminDriverDetails(raw);
  }

  String get pincode => _firstString(const ['pincode', 'zipCode', 'zip']);

  String get countryCode => _firstString(const ['countryCode', 'country']);

  String get stateCode => _firstString(const ['stateCode', 'StateCode']);

  String get city => _firstString(const ['city']);

  String get primaryUserId =>
      _firstString(const ['primaryUserid', 'primaryUserId']);

  String _firstString(List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      if (value == null) continue;
      final s = value.toString().trim();
      if (s.isNotEmpty && s.toLowerCase() != 'null') return s;
    }
    return '';
  }
}
