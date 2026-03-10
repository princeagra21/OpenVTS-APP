class AdminSimCardItem {
  final Map<String, dynamic> raw;

  const AdminSimCardItem(this.raw);

  factory AdminSimCardItem.fromRaw(Map<String, dynamic> raw) {
    return AdminSimCardItem(raw);
  }

  String get id => _firstString(const ['id', 'simId', 'uid', '_id']);

  String get phoneNumber =>
      _firstString(const ['simNumber', 'phoneNumber', 'phone', 'number']);

  String get provider {
    final providerObj = _asMap(raw['provider']);
    final nested = _string(providerObj['name'] ?? providerObj['providerName']);
    if (nested.isNotEmpty) return nested;

    final direct = _firstString(const ['providerName', 'provider']);
    if (direct.isNotEmpty) return direct;
    return '—';
  }

  String get imei =>
      _firstString(const ['imei', 'deviceImei', 'imeiNumber', 'device_imei']);

  String get iccid => _firstString(const ['iccid', 'iccidNo']);

  String get expiryDate => _firstString(const [
    'expiry',
    'expiryDate',
    'validTill',
    'validTo',
    'planExpiry',
    'licenseExpiry',
  ]);

  String get rawStatus =>
      _firstString(const ['status', 'state', 'simStatus', 'accountStatus']);

  bool get isActive {
    final direct = _firstBool(const ['isActive', 'active', 'enabled']);
    if (direct != null) return direct;

    final normalized = normalizeStatus(rawStatus);
    if (normalized == 'active') return true;
    if (normalized == 'inactive') return false;
    if (normalized == 'suspended') return false;
    return false;
  }

  String get statusLabel {
    final normalized = normalizeStatus(rawStatus, isActive: isActive);
    if (normalized == 'active') return 'Active';
    if (normalized == 'inactive') return 'Inactive';
    if (normalized == 'suspended') return 'Suspended';

    final s = rawStatus.trim();
    if (s.isNotEmpty) return s;
    return 'Inactive';
  }

  String get statusFilterValue =>
      normalizeStatus(rawStatus, isActive: isActive);

  static String normalizeStatus(String? raw, {bool? isActive}) {
    final value = (raw ?? '').trim().toLowerCase();

    if (value.isEmpty) {
      if (isActive == true) {
        return 'active';
      }
      if (isActive == false) {
        return 'inactive';
      }
      return '';
    }

    if (value == 'active' || value == 'enabled') {
      return 'active';
    }
    if (value == 'inactive' || value == 'disabled' || value == 'disable') {
      return 'inactive';
    }
    if (value == 'suspended' || value == 'paused') {
      return 'suspended';
    }

    if (value.contains('suspend') || value.contains('pause')) {
      return 'suspended';
    }
    if (value.contains('active') || value.contains('enable')) {
      return 'active';
    }
    if (value.contains('inactive') || value.contains('disable')) {
      return 'inactive';
    }

    return value;
  }

  String _firstString(List<String> keys) {
    for (final key in keys) {
      final value = raw[key];
      final out = _string(value);
      if (out.isNotEmpty) return out;
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

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value.cast());
    return const <String, dynamic>{};
  }

  static String _string(Object? value) {
    if (value == null) return '';
    final out = value.toString().trim();
    if (out.isEmpty || out.toLowerCase() == 'null') return '';
    return out;
  }
}
