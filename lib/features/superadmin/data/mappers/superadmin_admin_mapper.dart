import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/features/superadmin/data/models/superadmin_admin_dtos.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_admin.dart';

class SuperadminAdminMapper {
  const SuperadminAdminMapper();

  List<SuperadminAdminDto> listFromResponse(Object? response) {
    return ApiResponseNormalizer.listOf(response, preferredKeys: const ['admins', 'users', 'items', 'rows'])
        .map(_mapOf)
        .where((m) => m.isNotEmpty)
        .map(SuperadminAdminDto.fromJson)
        .toList(growable: false);
  }

  SuperadminAdminDto? detailFromResponse(Object? response) {
    final map = ApiResponseNormalizer.mapPayloadOf(response, preferredKeys: const ['admin', 'user', 'profile', 'data']);
    return map.isEmpty ? null : SuperadminAdminDto.fromJson(map);
  }

  SuperadminAdminListItem listItem(SuperadminAdminDto dto) {
    final json = dto.json;
    return SuperadminAdminListItem(
      id: _text(_first(json, const ['id', 'adminId', 'admin_id', 'userId', 'user_id', 'uid'])),
      name: _text(_first(json, const ['name', 'Name', 'fullName', 'full_name'])),
      username: _text(_first(json, const ['username', 'handle'])),
      email: _text(_first(json, const ['email', 'mail'])),
      phone: _text(_first(json, const ['mobileNumber', 'mobile', 'phone', 'phoneNumber'])),
      company: _text(_first(json, const ['companyName', 'company_name', 'company', 'organization', 'orgName'])),
      status: _text(_first(json, const ['status', 'state', 'verificationStatus', 'verifiedStatus', 'isActive'])),
      isActive: _bool(_first(json, const ['isActive', 'active', 'is_active', 'status'])),
      vehiclesCount: _int(_first(json, const ['vehicles', 'vehicleCount', 'vehiclesCount', 'vehicles_count', 'totalvehicles'])),
      credits: _int(_first(json, const ['credits', 'creditBalance'])),
      role: _text(_first(json, const ['role', 'roleName', 'role_name', 'companyName'])),
      location: _text(_first(json, const ['location', 'fulladdress', 'city', 'state'])),
      recentLogin: _text(_first(json, const ['recentLogin', 'lastLogin', 'last_login', 'lastLoginAt', 'Lastlogin'])),
      createdAt: _text(_first(json, const ['createdAt', 'created_at', 'created'])),
    );
  }

  SuperadminAdminDetail detail(SuperadminAdminDto dto) {
    final json = dto.json;
    final company = _firstMap(json, const ['company', 'companies']);
    return SuperadminAdminDetail(
      id: _text(_first(json, const ['id', 'adminId', 'admin_id', 'userId', 'user_id', 'uid'])),
      name: _text(_first(json, const ['name', 'fullName', 'full_name'])),
      username: _text(_first(json, const ['username', 'handle'])),
      email: _text(_first(json, const ['email', 'mail'])),
      mobilePrefix: _text(_first(json, const ['mobilePrefix', 'prefix'])),
      mobileNumber: _text(_first(json, const ['mobileNumber', 'mobile', 'phone', 'phoneNumber'])),
      companyName: _text(_first(json, const ['companyName', 'company'])) .isNotEmpty
          ? _text(_first(json, const ['companyName', 'company']))
          : _text(_first(company, const ['name', 'companyName'])),
      website: _text(_first(json, const ['website', 'domain'])) .isNotEmpty
          ? _text(_first(json, const ['website', 'domain']))
          : _text(_first(company, const ['websiteUrl', 'customDomain'])),
      isActive: _bool(_first(json, const ['isActive', 'active', 'is_active', 'status'])),
      isVerified: _bool(_first(json, const ['isVerified', 'emailVerified', 'isEmailVerified', 'verified', 'isemailvarified'])),
      addressLine: _text(_first(json, const ['addressLine', 'address1', 'address_line', 'address'])),
      city: _text(_first(json, const ['cityName', 'city', 'cityId'])),
      state: _text(_first(json, const ['stateName', 'state', 'stateId'])),
      country: _text(_first(json, const ['countryName', 'country', 'countryId'])),
      postalCode: _text(_first(json, const ['postalCode', 'zip', 'zipcode', 'pincode'])),
    );
  }

  Map<String, Object?> mutationToJson(SuperadminAdminMutationInput input) => input.fields;

  static Map<String, Object?> _mapOf(Object? value) {
    if (value is Map<String, Object?>) return value;
    if (value is Map) return <String, Object?>{for (final entry in value.entries) entry.key.toString(): entry.value};
    return const <String, Object?>{};
  }

  static Map<String, Object?> _firstMap(Map<String, Object?> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value is Map) return _mapOf(value);
      if (value is List && value.isNotEmpty && value.first is Map) return _mapOf(value.first);
    }
    return const <String, Object?>{};
  }

  static Object? _first(Map<String, Object?> source, List<String> keys) {
    for (final key in keys) {
      if (!source.containsKey(key)) continue;
      final value = source[key];
      if (value == null) continue;
      if (value is String && value.trim().isEmpty) continue;
      return value;
    }
    return null;
  }

  static String _text(Object? value) => value?.toString().trim() ?? '';
  static int _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(_text(value).replaceAll(',', '')) ?? 0;
  }
  static bool _bool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = _text(value).toLowerCase();
    return text == 'true' || text == '1' || text == 'active' || text == 'verified' || text == 'enabled';
  }
}
