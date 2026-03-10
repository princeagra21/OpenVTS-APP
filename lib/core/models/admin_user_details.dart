import 'package:fleet_stack/core/models/admin_user_list_item.dart';

class AdminUserDetails {
  final Map<String, dynamic> raw;

  const AdminUserDetails(this.raw);

  factory AdminUserDetails.fromRaw(Map<String, dynamic> raw) {
    return AdminUserDetails(raw);
  }

  AdminUserListItem get summary => AdminUserListItem(raw);

  String get id => summary.id;
  String get fullName => summary.fullName;
  String get email => summary.email;
  String get username => summary.username;
  String get phonePrefix => summary.phonePrefix;
  String get phoneNumber => summary.phoneNumber;
  String get fullPhone => summary.fullPhone;
  String get statusLabel => summary.statusLabel;
  bool get isActive => summary.isActive;
  String get location => summary.location;
  int get vehiclesCount => summary.vehiclesCount;
  String get joinedAt => summary.joinedAt;

  String get address => _firstString(const ['address']);
  String get city => _firstString(const ['city']);
  String get state => _firstString(const ['state', 'stateName']);
  String get country => _firstString(const ['country', 'countryName']);
  String get pincode => _firstString(const ['pincode', 'postalCode']);
  String get companyName =>
      _firstString(const ['companyName', 'company', 'tenantName']);
  String get lastLoginAt =>
      _firstString(const ['lastLogin', 'lastLoginAt', 'updatedAt']);

  bool? get emailVerified =>
      _firstBool(const ['isEmailVerified', 'emailVerified']);
  bool? get mobileVerified =>
      _firstBool(const ['isMobileVerified', 'mobileVerified']);

  String _firstString(List<String> keys) {
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
